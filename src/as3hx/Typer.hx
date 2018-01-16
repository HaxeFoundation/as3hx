package as3hx;
import as3hx.As3.ClassDef;
import as3hx.As3.ClassField;
import as3hx.As3.Expr;
import as3hx.As3.Function;
import as3hx.As3.Program;
import as3hx.As3.T;
import as3hx.RebuildUtils.RebuildResult;
import neko.Lib;

typedef DictionaryTypes = {
    key:Array<String>,
    value:Array<String>
}

/**
 * AS3 typing allows multiple equal variable type declarations in one method and opens new variable context only inside function, not in any {} block
 */
class Typer
{
    var cfg:Config;
    var classes : Map<String,Map<String,String>> = new Map<String,Map<String,String>>();
    var classFieldDictionaryTypes : Map<String,Map<String,DictionaryTypes>> = new Map<String,Map<String,DictionaryTypes>>();
    var context : Map<String,String> = new Map<String,String>();
    var contextStack : Array<Map<String,String>> = [];
    var currentPath:String = null;
    var importsMap : Map<String,String>;

    public function new(cfg:Config) {
        this.cfg = cfg;
    }
    
    public function getContextClone(relativeLevel:Int = 0):Map<String,String> {
        var context:Map<String,String>;
        if (relativeLevel < 0 && -relativeLevel <= contextStack.length) {
            context = contextStack[contextStack.length + relativeLevel];
        } else {
            context = this.context;
        }
        var clone:Map<String,String> = new Map<String,String>();
        for (v in context.keys()) {
            clone.set(v, context.get(v));
        }
        return clone;
    }

    public function getExprType(e:Expr):Null<String> {
        switch(e) {
            case ETypedExpr(e2, t): return tstring(t);
            case EField(e2, f):
                switch(e2) {
                    case EIdent("this"): return contextStack.length > 0 ? contextStack[0].get(f) : context.get(f);
                    default:
                }
                var t2 = getExprType(e2);
                if (t2 != null && (t2.indexOf("Array<") == 0 || t2.indexOf("Vector<") == 0) && f == "length") {
                    return "Int";
                }
                switch(t2) {
                    case "FastXML":
                        return switch(f) {
                            case "descendants", "nodes": "FastXMLList";
                            case "node": "FastXML";
                            case "length": "Int";
                            case _: "FastXMLList";
                        }
                    case "FastXMLList":
                        switch(f) {
                            case "length": return "Int";
                        }
                    default:
                }
                var ts:String = getExprType(e2);
                if (ts != null) {
                    if (context.exists(ts)) {
                        ts = context.get(ts);
                    }
                    if (classes.exists(ts)) {
                        return classes.get(ts).get(f);
                    } else if (importsMap != null && importsMap.exists(ts)) {
                        if (classes.exists(ts)) {
                            return classes.get(importsMap.get(ts)).get(f);
                        }
                    }
                }
                return null;
            case ECall(e, params):
                var t:String = getExprType(e);
                if (t != null) {
                    var li:Int = t.lastIndexOf("->");
                    if (li != -1) {
                        return t.substr(li + 2);
                    }
                }
            case EIdent(s):
                switch(s) {
                    case "true", "false": return "Bool";
                    case "encodeURI", "decodeURI", "escape", "unescape": return "String->String";
                    default:
                }
                s = getModifiedIdent(s);
                return context.get(s);
            case EVars(vars) if(vars.length == 1): return tstring(vars[0].t);
            case EArray(n, _): return getExprType(n);
            case EArrayDecl(_): return "Array<Dynamic>";
            case EUnop(_, _, e2): return getExprType(e2);
            case EBinop(_ => "as", _, type, _): return getExprType(type);
            case EBinop(_ => "/", _, _, _): return "Float";
            case EBinop(_, e1, e2, _) if (getExprType(e1) != "Float" && getExprType(e2) != "Float"): return "Int";
            case ENew(t, params): return tstring(t);
            case EConst(c):
                return switch(c) {
                    case CInt(_): "Int";
                    case CFloat(_): "Float";
                    case CString(_): "String";
                }
            case ERegexp(_, _): return getRegexpType();
            default:
        }
        return null;
    }

    public function getModifiedIdent(s : String) : String {
        return switch(s) {
            case "int": "Int";
            case "uint": cfg.uintToInt ? "Int" : "UInt";
            case "Number": "Float";
            case "Boolean": "Bool";
            case "Function": cfg.functionToDynamic ? "Dynamic" : s;
            case "Object": cfg.useOpenFlTypes ? "Object" : "Dynamic";
            case "undefined": "null";
            //case "Error": cfg.mapFlClasses ? "flash.errors.Error" : s;
            case "XML": "FastXML";
            case "XMLList": "FastXMLList";
            case "NaN":"Math.NaN";
            case "Dictionary": cfg.dictionaryToHash ? "haxe.ds.ObjectMap" : s;
            case "decodeURI": "StringTools.decodeURI";
            case "encodeURI": "StringTools.encodeURI";
            case "escape": "StringTools.htmlEscape";
            case "unescape": "StringTools.htmlUnescape";
            //case "QName": cfg.mapFlClasses ? "flash.utils.QName" : s;
            default: s;
        };
    }

    public function tstring(t:T, isNativeGetSet:Bool = false, fixCase:Bool = true) : String {
        if(t == null) return null;
        return switch(t) {
            case TStar: "Dynamic";
            case TVector(t): cfg.vectorToArray ? "Array<" + tstring(t) + ">" : "Vector<" + tstring(t) + ">";
            case TPath(p):
                var c = p.join(".");
                return switch(c) {
                    case "Array"    : "Array<Dynamic>";
                    case "Boolean"  : "Bool";
                    case "Class"    : "Class<Dynamic>";
                    case "int"      : "Int";
                    case "Number"   : "Float";
                    case "uint"     : cfg.uintToInt ? "Int" : "UInt";
                    case "void"     : "Void";
                    case "Function" : cfg.functionToDynamic ? "Dynamic" : c;
                    case "Object"   : isNativeGetSet ? "{}" : "Dynamic";
                    case "XML"      : cfg.useFastXML ? "FastXML" : "Xml";
                    case "XMLList"  : cfg.useFastXML ? "FastXMLList" : "Iterator<Xml>";
                    case "RegExp"   : cfg.useCompat ? "as3hx.Compat.Regex" : "flash.utils.RegExp";
                    default         : fixCase ? properCase(c, true) : c;
                }
            case TComplex(e): return getExprType(e); // not confirmed
            case TDictionary(k, v): (cfg.dictionaryToHash ? "haxe.ds.ObjectMap" : "Dictionary") + "<" + tstring(k) + "," + tstring(v) + ">";
            case TFunction(p): p.map(function(it) return tstring(it)).join("->");
        }
    }

    public function addClass(path:String, c:ClassDef):Void {
        var classMap:Map<String,String> = new Map<String,String>();
        parseClassFields(path, c, classMap);
        classes[path] = classMap;
    }

    public function enterClass(path, c:ClassDef):Void {
        currentPath = path;
        var classMap:Map<String,String> = classes.get(path);
        if (classMap == null) {
            classMap = new Map<String, String>();
            parseClassFields(path, c, classMap);
        }
        contextStack[contextStack.length - 1] = context = classMap;
    }
    
    public function setImports(importsMap:Map<String,String>):Void {
        this.importsMap = importsMap;
    }

    public function enterFunction(f:Function):Void {
        openContext();
        for (arg in f.args) {
            context.set(arg.name, tstring(arg.t));
        }
        if (f.varArgs != null) {
            context.set(f.varArgs, "Array<Dynamic>");
        }
        function lookUpForTyping(expr:Expr):RebuildResult {
            switch(expr) {
                case EVars(vars):
                    for (v in vars) {
                        context.set(v.name, tstring(v.t));
                    }
                case EFunction(f, name):
                    if (name != null) {
                        context.set(name, tstring(getFunctionType(f)));
                    }
                    // Stop parsing this branch. We are not interested in variables in another scope
                    return RSkip;
                default:
            }
            return null;
        }
        RebuildUtils.rebuild(f.expr, lookUpForTyping);
    }

    public function leaveFunction():Void {
        closeContext();
    }

    function parseClassFields(path:String, c:ClassDef, map:Map<String,String>):Void {
        for (field in c.fields) {
            switch(field.kind) {
                case FVar(t, val):
                    map.set(field.name, tstring(t));
                case FFun(f):
                    if (isSetter(field) || isGetter(field)) {
                        map.set(field.name, tstring(f.ret.t));
                    } else {
                        map.set(field.name, tstring(getFunctionType(f)));
                    }
                default:
            }
        }
        map.set(c.name, path);
    }
    
    public function applyRefinedTypes(program:Program):Void {
        var pack:String = (program.pack.length > 0 ? program.pack.join(".") + "." : "");
        for (d in program.defs) {
            switch (d) {
                case CDef(c):
                    enterClass(pack + c.name, c);
                    for (f in c.fields) {
                        var t:T = getDictionaryType(f.name);
                        switch (t)  {
                            case TDictionary(k, v):
                                addImport(program, k);
                                addImport(program, v);
                            case null:
                            default:
                        }
                        var d:String = tstring(t);
                        if (t != null) {
                            switch(f.kind) {
                                case FVar(t1, val):
                                    f.kind = FVar(t, val);
                                default:
                            }
                            context[f.name] = d;
                            Lib.println("    Refined type in " + pack + c.name + "::" + f.name + ":  " + d);
                        }
                    }
                default:
            }
        }
    }
    
    public function refineTypes(program:Program):Void {
        var currentClass:String = null;
        var pack:String = (program.pack.length > 0 ? program.pack.join(".") + "." : "");
        
        function refineArrayAccess(e1:Expr, index:Expr, value:Expr):Void {
            var type1:String = getExprType(e1);
            if (type1 != null && StringTools.startsWith(type1, "Dictionary")) {
                var baseType:String = null;
                var field:String = null;
                switch(e1) {
                    case EField(e2, f):
                        baseType = getExprType(e2);
                        field = f;
                    case EIdent(s):
                        baseType = pack + currentClass;
                        field = s;
                    default:
                }
                if (field != null && baseType != null) {
                    if (classes.exists(baseType)) {
                        if (!classFieldDictionaryTypes.exists(baseType)) {
                            classFieldDictionaryTypes.set(baseType, new Map<String, DictionaryTypes>());
                        }
                        var map:Map<String, DictionaryTypes> = classFieldDictionaryTypes.get(baseType);
                        if (!map.exists(field)) {
                            map.set(field, {
                                key:new Array<String>(),
                                value:new Array<String>()
                            });
                        }
                        var d:DictionaryTypes = map.get(field);
                        refineStringType(d.key, getExprType(index));
                        if (value != null) {
                            refineStringType(d.value, getExprType(value));
                        }
                    }
                }
            }
        }
        
        function rebuild(expr:Expr):RebuildResult {
            switch(expr) {
                case EFunction(f, name):
                    enterFunction(f);
                    var re:Expr = RebuildUtils.rebuild(f.expr, rebuild);
                    leaveFunction();
                    if (re != null) {
                        return RebuildResult.RReplace(re);
                    } else {
                        return RebuildResult.RSkip;
                    }
                case EBinop("=", e1, e2, _):
                    switch(e1) {
                        case EArray(e1, index):
                            refineArrayAccess(e1, index, e2);
                        default:
                    }
                    switch(e2) {
                        case EArray(e2, index):
                            refineArrayAccess(e2, index, e1);
                        default:
                    }
                case EArray(e1, index):
                    refineArrayAccess(e1, index, null);
                default:
            }
            return null;
        }
        
        for (d in program.defs) {
            switch (d) {
                case CDef(c):
                    enterClass(pack + c.name, c);
                    currentClass = c.name;
                    for (field in c.fields) {
                        switch(field.kind) {
                            case FFun(f):
                                enterFunction(f);
                                RebuildUtils.rebuild(f.expr, rebuild);
                                leaveFunction();
                            default:
                        }
                    }
                case FDef(f):
                    RebuildUtils.rebuild(f.f.expr, rebuild);
                default:
            }
        }
    }
    
    public function getDictionaryType(field:String):T {
        var m:Map<String,DictionaryTypes> = classFieldDictionaryTypes.get(currentPath);
        if (m != null && field != null) {
            var d:DictionaryTypes = m.get(field);
            if (d != null) {
                var keyT:String = null;
                var valueT:String = null;
                for (t in d.key) keyT = foldDictionaryType(keyT, t);
                for (t in d.value) valueT = foldDictionaryType(valueT, t);
                if (cfg.useOpenFlTypes) {
                    if (keyT == null || keyT == "Dynamic") keyT = "Object";
                    if (valueT == null || valueT == "Dynamic") valueT = "Object";
                }
                return TDictionary(TPath([keyT]), TPath([valueT]));
                //return "Dictionary<" + d.key[0] + "," + d.value[0] + ">";
            }
        }
        if (contextStack.length < 1) return null;
        var t:String = contextStack[0].get(field);
        return TPath([t]);
    }
    
    function foldDictionaryType(a:String, b:String):String {
        if (a == b) return a;
        if (a == "Dynamic" || a == null) return b;
        if (b == "Dynamic" || b == null) return a;
        if (a == "String") return a;
        if (b == "String") return b;
        return "Dynamic";
    }
    
    /** it could be better if we would refine single value on occurance but not to collect all types */
    function refineStringType(types:Array<String>, type:String):Void {
        if (type != null) {
            types.push(type);
        }
    }

    inline function getRegexpType():String return cfg.useCompat ? "as3hx.Compat.Regex" : "flash.utils.RegExp";

    inline function isGetter(c:ClassField):Bool return Lambda.has(c.kwds, "get");

    inline function isSetter(c:ClassField):Bool return Lambda.has(c.kwds, "set");


    /**
     * Opens a new context for variable typing
     */
    function openContext() {
        var c = new Map();
        for(k in context.keys())
            c.set(k, context.get(k));
        contextStack.push(context);
        context = c;
    }

    /**
     * Closes the current variable typing context
     */
    function closeContext() {
        context = contextStack.pop();
    }
    
    function addImport(program:Program, t:T):Void {
        program.typesSeen.push(t);
    }

    public static function getFunctionType(f:Function):T {
        var t = f.args.map(function(it) return it.t);
        if(f.varArgs != null) t.push(TPath(["Array<Dynamic>"]));
        if(t.length == 0) t.push(TPath(["Void"]));
        t.push(f.ret.t);
        return TFunction(t);
    }

    public static function properCase(pkg:String, hasClassName:Bool):String {
        return Writer.properCase(pkg, hasClassName);
    }
}