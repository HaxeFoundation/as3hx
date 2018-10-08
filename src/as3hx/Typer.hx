package as3hx;
import as3hx.As3.ClassDef;
import as3hx.As3.ClassField;
import as3hx.As3.Expr;
import as3hx.As3.Function;
import as3hx.As3.FunctionDef;
import as3hx.As3.Program;
import as3hx.As3.T;
import as3hx.RebuildUtils.RebuildResult;

/**
 * AS3 typing allows multiple equal variable type declarations in one method and opens new variable context only inside function, not in any {} block
 */
class Typer
{
    public var classes(default,null) : Map<String,Map<String,String>> = new Map<String,Map<String,String>>();
    public var classDefs(default,null) : Map<String,ClassDef> = new Map<String,ClassDef>();
    public var classChildren(default,null):Map<String,Array<String>> = new Map<String,Array<String>>();
    public var currentPath(default, null):String = null;
    var cfg:Config;
    var classesByPackages:Map<String,Map<String,String>> = new Map<String,Map<String,String>>();
    var parentStaticFields : Map<String,String> = new Map<String,String>();
    var funDefs : Map<String,String> = new Map<String,String>();
    var classPrograms : Map<ClassDef,Program> = new Map<ClassDef,Program>();
    var staticContext : Map<String,String> = new Map<String,String>();
    var context : Map<String,String> = new Map<String,String>();
    var contextStack : Array<Map<String,String>> = [];
    var functionStack : Array<Function> = [];
    var functionStackName : Array<String> = [];
    var pack:String = null;
    var importsMap : Map<String,String>;
    var classPacks:Map<ClassDef,String> = new Map<ClassDef,String>();
    var _hostClassRef:Reference<ClassDef> = new Reference<ClassDef>();

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
        for (v in staticContext.keys()) {
            clone.set(v, context.get(v));
        }
        return clone;
    }

    public function isExistingIdent(ident:String):Bool {
        switch(ident) {
            case "as3hx.Compat", "Std", "true", "false", "encodeURI", "decodeURI", "escape", "unescape", "encodeURIComponent", "decodeURIComponent": return true;
            default:
        }
        ident = getModifiedIdent(ident);
        if (context.exists(ident)) {
           return true;
        } else if (staticContext.exists(ident)) {
           return true;
        } else if (importsMap != null && importsMap.exists(ident)) {
           return true;
        }
        return false;
    }

    private function getQualifiedClassName(shortName:String):String {
        if (classes.exists(shortName)) return shortName;
        if (importsMap != null && importsMap.exists(shortName)) return importsMap.get(shortName);
        return '';
    }

    public function getThisIdentType(ident:String):String {
        return contextStack.length > 0 ? contextStack[0].get(ident) : null;
    }

    public function getIsInterface(e:Expr):Bool {
        var type:String = getExprType(e, true);
        if (type != null && classDefs.exists(type)) {
            return classDefs[type].isInterface;
        } else {
            return false;
        }
    }

    public function doImplements(a:String, b:String):Bool {
        var ca:ClassDef = classDefs[a];
        var cb:ClassDef = classDefs[b];
        if (cb == null) return false;
        while (ca != null) {
            if (ca == cb) return true;
            if (cb.isInterface) {
                for (t in ca.implement) {
                    switch(t) {
                        case TPath(t):
                            if (t[t.length - 1] == cb.name) return true;
                            if (t[t.length - 1].indexOf("." + cb.name) != -1) return true;
                        default:
                    }
                }
            }
            var classPackage:String = classPacks.get(ca);
            var parentPath:String = getPathByType(ca.extend, ca, null, classPackage);
            if (parentPath == null) break;
            ca = classDefs[parentPath];
        }
        return false;
    }

    public function getField(v:String, hostClass:Reference<ClassDef>, c:ClassDef = null):ClassField {
        if (c == null) {
            c = classDefs[currentPath];
        }
        while (c != null) {
            for (f in c.fields) {
                hostClass.value = c;
                if (f.name == v) return f;
            }
            if (c.extend == null) break;
            var classPackage:String = classPacks.get(c);
            var parentPath:String = getPathByType(c.extend, c, null, classPackage);
            if (parentPath != null) {
                c = classDefs[parentPath];
            } else {
                break;
            }
        }
        return null;
    }

    public function getFunctionArgTypes(e:Expr):Array<T> {
        var c:ClassDef = null;
        var f:ClassField = null;
        switch (e) {
            case EIdent(v):
                c = classDefs[currentPath];
                f = getField(v, _hostClassRef, c);
            case EField(e, field):
                var t:String = getExprType(e);
                if (t != null) {
                    c = classDefs[t];
                    f = getField(field, _hostClassRef, c);
                }
            default:
        }
        if (f != null) {
            c = _hostClassRef.value;
            switch(f.kind) {
                case FFun(f):
                    var r:Array<T> = [];
                    for (i in 0...f.args.length) {
                        var a = f.args[i];
                        if (a != null && a.t != null) {
                            r.push(expandType(a.t, c));
                        } else {
                            r.push(null);
                        }
                    }
                    return r;
                default:
            }
        }
        return null;
    }

    public function isVariable(ident:String):Bool {
        var isConstructor:Bool = classDefs[currentPath] != null && classDefs[currentPath].name == ident;
        return !isConstructor && (context.exists(ident) || staticContext.exists(ident));
    }

    public function getExprType(e:Expr, isFieldAccess:Bool = false):Null<String> {
        switch(e) {
            case null: return null;
            case ETypedExpr(e2, t): return tstring(t);
            case EField(e2, f):
                var t2 = null;
                switch(e2) {
                    case EIdent("super"):
                        var c:ClassDef = classDefs[currentPath];
                        if (c != null && c.extend != null) {
                            var classPackage:String = classPacks.get(c);
                            var parentPath:String = getPathByType(c.extend, c, null, classPackage);
                            if (parentPath != null && classDefs[parentPath] != null) {
                                t2 = parentPath;
                            }
                        }
                    case EIdent("this"):
                        return contextStack.length > 0 ? contextStack[0].get(f) : context.get(f);
                    default:
                }
                if (t2 == null) {
                    t2 = getExprType(e2, true);
                }
                if (t2 != null && (t2.indexOf("Array<") == 0 || t2.indexOf("Vector<") == 0 || t2.indexOf("openfl.Vector<") == 0)) {
                    switch(f) {
                        case "length": return "Int";
                        case "sort" : return "Function->Void";
                    }
                }
                switch(t2) {
                    case "Reflect":
                        switch(f) {
                            case "hasField": return "Dynamic->String->Bool";
                            case "field": return "Dynamic->String->Dynamic";
                            case "setField": return "Dynamic->String->Dynamic->Void";
                        }
                    case "Signal","signals.Signal":
                        switch(f) {
                            case "add": return "Function->Void";
                            case "addOnce": return "Function->Void";
                            case "remove": return "Function->Void";
                        }
                    case "as3hx.Compat":
                        switch(f) {
                            case "parseInt": return "Float->Int";
                            case "setTimeout": return "Dynamic->Int->Int";
                            case "getQualifiedClassName": return "Dynamic->String";
                        }
                    case "AS3":
                        switch(f) {
                            case "string": return "Dynamic->String";
                            case "int": return "Dynamic->Int";
                            case "parseInt": return "Dynamic->Int";
                            case "hasOwnProperty": return "Dynamic->String->Bool";
                        }
                    case "Date":
                        switch(f) {
                            case "getTime": return "Void->Float";
                            case "now": return "Void->Date";
                            case "time": return "Float";
                        }
                    case "Math":
                        switch(f) {
                            case "ceil", "floor", "round": return "Float->Int";
                            case "max", "min": return "Float->Float->Float";
                            case "random": return "Void->Float";
                            default: return "Float->Float";
                        }
                    case "Std":
                        switch(f) {
                            case "int": return "Float->Int";
                            case "is": return "Dynamic->Dynamic->Bool";
                            case "parseFloat": return "String->Float";
                            case "parseInt": return "String->Int";
                            case "random": return "Int->Int";
                            case "string": return "Dynamic->String";
                            default:
                        }
                    case "StringTools":
                        return switch(f) {
                            case "replace": return "String->String->String->String";
                            default: return "String";
                        }
                    case "String":
                        return switch(f) {
                            case "length": return "Int";
                            case "charCodeAt": return "Int->Int";
                            case "indexOf": return "String->Int";
                            case "lastIndexOf": return "String->Int";
                            case "split": return "String->Array<String>";
                            case "substr", "substring": return "Int->Int->String";
                            case "replace": return "String->String->String";
                            case "toLowerCase", "toUpperCase", "toString", "toLocaleLowerCase", "toLocaleUpperCase": return "Void->String";
                            case "fromCharCode": return "Int->String";
                            default: return "String";
                        }
                    case "FastXMLNodeAccess": return "FastXML";
                    case "FastXMLNodeListAccess": return "FastXMLList";
                    case "FastXMLAttribAccess": return "String";
                    case "FastXMLHasAttribAccess": return "Bool";
                    case "FastXMLHasNodeAccess": return "Bool";
                    case "FastXML":
                        return switch(f) {
                            case "copy": return "Void->FastXML";
                            case "node":"FastXMLNodeAccess";
                            case "nodes":"FastXMLNodeListAccess";
                            case "att":"FastXMLAttribAccess";
                            case "has":"FastXMLHasAttribAccess";
                            case "hasNode":"FastXMLHasNodeAccess";
                            case "name":"String";
                            case "innerData":"String";
                            case "innerHTML":"String";
                            case "descendants": "String->FastXMLList";
                            //case "descendants", "nodes": "FastXMLList";
                            //case "node": "FastXML";
                            //case "length": "Int";
                            case _: "FastXMLList";
                        }
                    case "FastXMLList":
                        switch(f) {
                            case "copy": return "Void->FastXMLList";
                            case "length": return "Int";
                            case "descendants": return "String->FastXMLList";
                            case "get": return "Int->FastXML";
                            default: return "FastXMLList"; // will be transformed to .descendants()
                        }
                    default:
                        if (t2 != null && t2.indexOf("Dictionary<") == 0) {
                            switch(f) {
                                case "exists": return "Dynamic->Bool";
                            }
                        }
                }
                if (t2 != null) {
                    var index:Int = t2.indexOf("<");
                    var typeParam:String = null;
                    if (index != -1) {
                        typeParam = t2.substring(index + 1, t2.length - 1);
                        t2 = t2.substr(0, index);
                    }
                    var cl:String = resolveClassIdent(t2);
                    if (context.exists(t2)) {
                        t2 = context.get(t2);
                    } else if (staticContext.exists(t2)) {
                        t2 = staticContext.get(t2);
                    }
                    if (importsMap != null && importsMap.exists(t2)) {
                        var t:String = importsMap.get(t2);
                        if (t != null) t2 = t;
                    }
                    if (t2.indexOf(".") != -1) {
                        var t2Array:Array<String> = t2.split(".");
                        t2 = getImportString(t2Array, true);
                    }
                    if (classes.exists(t2)) {
                        var t:String = classes.get(t2).get(f);
                        if (t != null) {
                            var index:Int = t.indexOf("<");
                            if (index != -1) {
                                var resultTypeParam = t.substring(index, t.length);
                                if (resultTypeParam == classDefs[t2].typeParams) {
                                    t = t.substring(0, index + 1) + typeParam + ">";
                                }
                            }
                            return t;
                        }
                    }
                }
                return null;
            case ECall(e, params):
                /* handling of as3 typing calls */
                switch(e) {
                    case EIdent("Object"): return getExprType(params[0]);
                    case EIdent("Number"): return "Float";
                    case EIdent("String"): return "String";
                    case EIdent("int"): return "Int";
                    case EIdent("uint"): return "Int";
                    case EIdent("getQualifiedClassName"): return "String";
                    case EVector(t): return "Vector<" + tstring(t) + ">";
                    case EField(e, "instance"):
                        switch(e) {
                            case EIdent("Std"):
                                return getExprType(params[1]);
                            default:
                        }
                    default:
                }
                var t:String = getExprType(e);
                if (t != null) {
                    var li:Int = t.lastIndexOf("->");
                    if (li != -1) {
                        return t.substr(li + 2);
                    }
                }
            case EIdent(s):
                switch(s) {
                    case "as3hx.Compat": return "as3hx.Compat";
                    case "Std": return "Std";
                    case "true", "false": return "Bool";
                    case "encodeURI", "decodeURI", "escape", "unescape", "encodeURIComponent", "decodeURIComponent": return "String->String";
                    case "this": return currentPath;
                    case "trace": return "Dynamic->Void";
                    case "super":
                        var c:ClassDef = classDefs[currentPath];
                        if (c != null && c.extend != null) {
                            var classPackage:String = classPacks.get(c);
                            var parentPath:String = getPathByType(c.extend, c, null, classPackage);
                            if (parentPath != null && classDefs[parentPath] != null) {
                                c = classDefs[parentPath];
                                for (f in c.fields) {
                                    if (f.name == c.name) {
                                        switch(f.kind) {
                                            case FFun(f):
                                                var pack:Array<String> = classPrograms[c].pack;
                                                var constructorReturnType:T = TPath([pack.length > 0 ? pack + "." + c.name : c.name]);
                                                return "Dynamic->" + tstring(getFunctionType(f, constructorReturnType));
                                            default:
                                        }
                                    }
                                }
                            }
                        }
                        return "Void->Dynamic";
                    default:
                }
                //var ss:String = s;
                var ident:Bool = false;
                s = getModifiedIdent(s);
                if (context.exists(s)) {
                   s = context.get(s);
                   ident = true;
                } else if (staticContext.exists(s)) {
                   s = staticContext.get(s);
                   ident = true;
                }
                if (s != null && importsMap != null && importsMap.exists(s)) {
                    var t:String = importsMap.get(s);
                    s = t == null ? s : t;
                    if (!ident && !isFieldAccess) return "Class<Dynamic>";
                }
                return s;
            case EVars(vars) if(vars.length == 1): return tstring(vars[0].t);
            case EArray(n, _):
                var tn:String = getExprType(n);
                if (tn != null) {
                    if (StringTools.startsWith(tn, "Array")) {
                        return tn.substring(6, tn.lastIndexOf(">"));
                    } else if (StringTools.startsWith(tn, "Vector")) {
                        return expandStringType(tn.substring(7, tn.lastIndexOf(">")));
                    } else if (StringTools.startsWith(tn, "openfl.Vector")) {
                        return expandStringType(tn.substring(14, tn.lastIndexOf(">")));
                    } else if (StringTools.startsWith(tn, "Dictionary") || StringTools.startsWith(tn, "openfl.utils.Dictionary")) {
                        var bothTypes:String = tn.substring(tn.indexOf("<") + 1, tn.lastIndexOf(">"));
                        var commaPosition:Int = -1;
                        var level:Int = 0;
                        for (i in 0...bothTypes.length) {
                            var char:Int = bothTypes.charCodeAt(i);
                            if (char == "<".code) {
                                level++;
                            } else if (char == ">".code) {
                                level--;
                            } else if (char == ",".code) {
                                if (level == 0) {
                                    commaPosition = i;
                                    break;
                                }
                            }
                        }
                        if (commaPosition != -1) {
                            return bothTypes.substr(commaPosition + 1);
                        }
                    }
                }
                return tn;
            case EArrayDecl(_): return "Array<Dynamic>";
            case EUnop(_, _, e2): return getExprType(e2);
            case EParent(e): return getExprType(e);
            case ETernary(cond, e1, e2): return getExprType(e1);
            case EVector(t): return "Vector<" + tstring(t) + ">";
            case EBinop(op, e1, e2, _) :
                switch(op) {
                    case "=" : return getExprType(e1);
                    case "as": return getExprType(e2, true);
                    case "/" : return "Float";
                    case "is" | "in" | "||" | "&&" | "!=" | "!==" | "==" | "===" | ">" | ">=" | "<" | "<=": return "Bool";
                    default:
                        var t1:String = getExprType(e1);
                        var t2:String = getExprType(e2);
                        if (op == "+" && t1 == "String" || t2 == "String") return "String";
                        if (t1 != "Float" && t1 != "Dynamic" && t2 != "Float" && t2 != "Dynamic") return "Int";
                        return "Float";
                }
            case ENew(t, params):
                switch(t) {
                    case TComplex(e):
                        var pack:Array<String> = getPackString(e);
                        if (pack != null) {
                            t = TPath(pack);
                        }
                    default:
                }
                switch(t) {
                    case TPath(p):
                        if (p[p.length - 1] == "Signal") {
                            var types:Array<String> = [];
                            for (param in params) {
                                switch(param) {
                                    case EVector(t):
                                        types.push(tstring(TVector(t)));
                                    case EIdent(v):
                                        var fullPath:String = resolveClassIdent(v);
                                        types.push(tstring(TPath([fullPath == null ? v : fullPath])));
                                        //types.push(tstring(TPath([fullPath])));
                                        //types.push(tstring(TPath([v])));
                                    default:
                                }
                            }
                            types.push("Void");
                            return "Signal<" +types.join("->") + ">";
                        } else if (p[p.length - 1] == "Dictionary" && cfg.useOpenFlTypes) {
                            return "Dictionary<Dynamic,Dynamic>";
                        }
                    default:
                }
                return tstring(t);
            case ECondComp(_, e, e2):
                return getExprType(e);
            case ENL(e):
                return getExprType(e);
            case EBlock(es):
                if (es.length == 1) {
                    return getExprType(es[0]);
                }
            //case EFunction(f, _):
                //return tstring(getFunctionType(f, null));
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

    inline function isBooleanOp(s:String):Bool return switch(s) {
        case "||" | "&&" | "!=" | "!==" | "==" | "===": true;
        case _: false;
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
            case "decodeURI": "StringTools.urlDecode";
            case "encodeURI": "StringTools.urlEncode";
            case "decodeURIComponent": "StringTools.urlDecode";
            case "encodeURIComponent": "StringTools.urlEncode";
            case "escape": "StringTools.htmlEscape";
            case "unescape": "StringTools.htmlUnescape";
            //case "QName": cfg.mapFlClasses ? "flash.utils.QName" : s;
            default: s;
        };
    }

    public static function tstringStatic(t:T) : String {
        if(t == null) return null;
        return switch(t) {
            case TStar: "Dynamic";
            case TVector(t): "Vector<" + tstringStatic(t) + ">";
            case TPath(p):
                var c = p.join(".");
                return c;
            default: t + "";
        }
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
                    case "Object"   : isNativeGetSet ? "{}" : (cfg.useOpenFlTypes ? "Object" : "Dynamic");
                    case "XML"      : cfg.useFastXML ? "FastXML" : "Xml";
                    case "XMLList"  : cfg.useFastXML ? "FastXMLList" : "Iterator<Xml>";
                    case "RegExp"   : cfg.useCompat ? "as3hx.Compat.Regex" : "flash.utils.RegExp";
                    //default         : fixCase ? properCase(c, true) : c;
                    default         : cfg.importExclude.indexOf(c) != -1 ? p[p.length - 1] : fixCase ? properCase(c, true) : c;
                }
            case TComplex(e): return getExprType(e); // not confirmed
            case TDictionary(k, v): (cfg.dictionaryToHash ? "haxe.ds.ObjectMap" : "Dictionary") + "<" + tstring(k) + "," + tstring(v) + ">";
            case TFunction(p): p.map(function(it) {
                    var s:String = tstring(it);
                    if (s != null && s.indexOf("->") != -1) {
                        return "(" + s + ")";
                    } else {
                        return s;
                    }
                }).join("->");
        }
    }

    public function addGlobalFunction(path:String, f:FunctionDef):Void {
        var contextRoot = contextStack.length > 0 ? contextStack[0] : context;
        funDefs[f.name] = path;
        //contextRoot.set(f.name, getFunctionType(f.f));
    }

    public function hasGlobalFunction(name:String):String {
        return funDefs.get(name);
    }

    public function addProgram(p:Program):Void {
        var pack:String = getImportString(p.pack, false);
        var path:String = p.pack.length > 0 ? pack + "." : "";
        var packMap:Map<String,String>;
        if (classesByPackages.exists(pack)) {
            packMap = classesByPackages.get(pack);
        } else {
            packMap = new Map<String,String>();
            classesByPackages.set(pack, packMap);
        }
        for (d in p.defs) {
            switch(d) {
                case CDef(c): addClass(p, pack, path + c.name, c);
                    packMap.set(c.name, path + c.name);
                    classPrograms.set(c, p);
                case FDef(f): addGlobalFunction(path + f.name, f);
                case NDef(n):
                default:
            }
        }
    }

    public function addClass(p:Program, pack:String, path:String, c:ClassDef):Void {
        var classMap:Map<String,String> = new Map<String,String>();
        if (!cfg.useFullTyping) {
            parseClassFields(p, pack, path, c, classMap);
        }
        classes[path] = classMap;
        classDefs[path] = c;
        classPacks.set(c, pack);
    }

    public function parseParentClasses():Void {
        for (path in classes.keys()) {
            var c:ClassDef = classDefs[path];
            parseClassFields(classPrograms[c], classPacks[c], path, c, classes[path]);
        }
        for (path in classes.keys()) {
            parseParentClass(path);
        }
    }

    private function parseParentClass(path:String):Map<String,String> {
        var classMap:Map<String,String> = classes.get(path);
        if (!classMap.exists("%childrenComplete")) {
            var c:ClassDef = classDefs.get(path);
            if (c.isInterface) {
                for (t in c.implement) {
                    parseOneParentClass(t, path, c, classMap);
                }
            } else if (c.extend != null) {
                parseOneParentClass(c.extend, path, c, classMap);
            }
            classMap.set("%childrenComplete", "");
        }
        return classMap;
    }

    private function parseOneParentClass(parentT:T, path:String, c:ClassDef, classMap:Map<String,String>):Void {
        var classPackage:String = classPacks.get(c);
        var parentPath:String = getPathByType(parentT, c, null, classPackage);
        if (parentPath != null) {
            if (!classChildren.exists(parentPath)) {
                classChildren.set(parentPath, [path]);
            } else {
                classChildren.get(parentPath).push(path);
            }
            var parentClassMap:Map<String,String> = parseParentClass(parentPath);
            for (field in parentClassMap.keys()) {
                classMap.set(field, parentClassMap.get(field));
            }
        }
    }

    public function getPathByType(t:T, hostClass:ClassDef, packageArray:Array<String> = null, packageString:String = null):String {
        switch (t) {
            case null:
            case TPath(p):
                if (p.length == 1 && p[0].indexOf(".") != -1) {
                    p = p[0].split(".");
                }
                var parentClassString:String = getImportString(p, true);
                if (parentClassString.indexOf("<") != -1) {
                    parentClassString = parentClassString.substr(0, parentClassString.indexOf("<"));
                }
                var path:String;
                if (parentClassString.indexOf(".") == -1) {
                    path = resolveClassIdent(parentClassString);
                    if (path == null) {
                        if (packageString == null && packageArray != null) {
                            packageString = getImportString(packageArray, false);
                        }
                        path = WriterImports.getImport(parentClassString, cfg, classes, hostClass, null, packageString);
                    }
                } else {
                    path = parentClassString;
                }
                if (path != null && classes.exists(path)) {
                    return path;
                }
            default:
        }
        return null;
    }

    public function getClassConstructorTypes(path:String):Array<T> {
        var c:String = path;
        if (context.exists(path)) {
           c = context.get(path);
        } else if (staticContext.exists(path)) {
           c = staticContext.get(path);
        } else if (importsMap != null && importsMap.exists(path)) {
            var t:String = importsMap.get(path);
            c = t == null ? path : t;
        }
        var def:ClassDef = classDefs.get(c);
        if (def != null) return getConstructorType(def);
        return null;
    }

    public function getIsStaticField(ident:String):String {
        if (!parentStaticFields.exists(ident) || context.exists(ident)) {
            return null;
        }
        return parentStaticFields.get(ident);
    }

    private function isLocalIdent(v:String):Bool {
        if (contextStack.length > 0 && context.exists(v) && !contextStack[0].exists(v)) {
            return true;
        }
        for (i in 1...contextStack.length) {
            if (contextStack[i].exists(v)) {
                return true;
            }
        }
        return false;
    }

    public function overrideExprType(expr:Expr, t:T):Void {
        switch (expr) {
            case null:
            case EIdent(v):
                if (isLocalIdent(v)) {
                    overrideLocalType(v, t);
                } else {
                    overrideIdentType(v, t);
                }
            case EField(e, f):
                var cName:String = getExprType(e);
                if (cName != null) {
                    overrideIdentType(f, t, classDefs[cName]);
                } else {
                    trace("null expr type for " + e + "." + f);
                }
            default:
        }
    }

    public function overrideLocalType(v:String, t:T):Void {
        var index:Int = functionStack.length - 1;
        while (index >= 0) {
            var f:Function = functionStack[index];

            var found:Bool = false;

            var short:T = shortenType(t);
            for (arg in f.args) {
                if (arg.name == v) {
                    arg.t = short;
                    if (functionStackName[index] != null) {
                        overrideExprType(EIdent(functionStackName[index]), getFunctionType(f, null));
                    }
                    found = true;
                }
            }
            if (!found) {
                found = overrideFunctionLocalType(f, v, short);
            }
            if (found) {
                for (i in index...contextStack.length) {
                    contextStack[i].set(v, tstring(t));
                }
                context.set(v, tstring(t));
            }
            index--;
        }
    }

    public function overrideFunctionLocalType(f:Function, v:String, t:T):Bool {
        //trace("override local type " + currentPath + "." + v + " : " + t + " (UNIMPLEMENTED");
        //t = shortenType(t);
        //for (arg in f.args) {
            //if (arg.name == v) {
                //arg.t = t;
                //return true;
            //}
        //}
        var replaced:Bool = false;
        function lookUpForTyping(expr:Expr):RebuildResult {
            switch(expr) {
                case EVars(vars):
                    for (variable in vars) {
                        if (variable.name == v) {
                            variable.t = t;
                            replaced = true;
                        }
                    }
                case EFunction(fun, name):
                    if (name == v) {
                        replaced = true;
                        switch(t) {
                            case TFunction(p):
                                overrideFunctionParams(fun, p);
                            default:
                                trace("UNCOMPATEABLE TYPE : " + t + " with function " + name);
                        }
                    }
                    // Stop parsing this branch. We are not interested in variables in another scope
                    return RebuildResult.RSkip;
                default:
            }
            return null;
        }
        RebuildUtils.rebuild(f.expr, lookUpForTyping);
        return replaced;
    }

    public function overrideFieldType(path:String, name:String, t:T, overrideInParents:Bool = true):Void {
        if (currentPath == path) {
            context.set(name, tstring(t));
        }
        var c:ClassDef = classDefs[path];
        var classMap:Map<String,String> = classes[path];
        if (classMap == null) return;
        classMap.set(name, tstring(t));
        if (overrideInParents && c.extend != null) {
            var classPackage:String = classPacks.get(c);
            var parentPath:String = getPathByType(c.extend, c, null, classPackage);
            if (parentPath != null) {
                var parentClassMap:Map<String,String> = classes.get(parentPath);
                if (parentClassMap.exists(name)) {
                    overrideFieldType(parentPath, name, t);
                    return;
                }
            }
        }
        var children:Array<String> = classChildren[path];
        if (children != null) {
            for (childPath in children) {
                overrideFieldType(childPath, name, t, false);
            }
        }
    }

    public static function getTypeParams(type:String, delimiters:Array<String> = null):Array<Array<String>> {
        var result:Array<Array<String>> = new Array<Array<String>>();
        var name:String = "";
        var inDelimiter:Bool = false;
        for (i in 0...type.length) {
            var c:Int = type.charCodeAt(i);
            var newInDelimiter:Bool;
            switch(c) {
                case "<".code, ">".code, "-".code, ",".code, " ".code, "(".code, ")".code:
                    newInDelimiter = true;
                default:
                    newInDelimiter = false;
            }
            if (newInDelimiter != inDelimiter) {
                inDelimiter = newInDelimiter;
                if (name.length > 0) {
                    if (inDelimiter) {
                        result.push(name.split("."));
                    } else {
                        if (delimiters != null) {
                            delimiters.push(name);
                        }
                    }
                    name = "";
                }
            }
            name += String.fromCharCode(c);
        }
        if (inDelimiter) {
            if (delimiters != null) {
                delimiters.push(name);
            }
        } else {
            result.push(name.split("."));
        }
        return result;
    }

    public function expandStringType(stringType:String, c:ClassDef = null):String {
        if (stringType == null) return null;
        return expandStringTypeToArray(stringType, c).join(".");
    }

    public function expandType(t:T, c:ClassDef = null):T {
        switch (t) {
            case null:
                if (c != null) trace("null T for class ", c.name);
                return null;
            case TVector(t):
                return TVector(expandType(t, c));
            case TFunction(p):
                var pr:Array<T> = [];
                for (pi in p) {
                    pr.push(expandType(pi, c));
                }
                return TFunction(pr);
            case TPath(p):
                var lastWord:String = p[p.length - 1];
                return TPath(expandStringTypeToArray(lastWord, c));
            default: return t;
        }
    }

    private function expandStringTypeToArray(stringType:String, c:ClassDef = null):Array<String> {
        var delimiters:Array<String> = new Array<String>();
        var t:Array<Array<String>> = getTypeParams(stringType, delimiters);
        var s:String;
        var r:Array<String>;
        var l:Int = 1;
        if (t[0].length == 1) {
            if (l == 1) {
                r = getFullTypeName(t[0][0], c).split(".");
                s = r.pop();
            } else {
                s = getFullTypeName(t[0][0], c);
                r = [];
            }
        } else {
            if (l == 1) {
                r = t[0];
                s = r.pop();
            } else {
                s = t[0].join(".");
                r = [];
            }
        }
        for (i in 1...t.length) {
            var fullType:String = '';
            if (t[i].length == 1) {
                fullType = getFullTypeName(t[i][0], c);
            } else {
                fullType = t[i].join(".");
            }
            s += delimiters[i - 1] + fullType;
        }
        if (delimiters.length == t.length) {
            s += delimiters[delimiters.length - 1];
        }
        r.push(s);
        return r;
    }

    public function shortenTypeAndImport(c:ClassDef, t:T):T {
        if (c != null) {
            addTypeImports(classPrograms[c], t);
        }
        return shortenType(t);
    }

    public function shortenType(t:T):T {
        switch (t) {
            case TFunction(p):
                var pr = [];
                for (i in 0...p.length) {
                    pr.push( shortenType(p[i]) );
                }
                return TFunction(pr);
            case TDictionary(k, v):
                return TDictionary(shortenType(k), shortenType(v));
            case TPath(p):
                var s:String = p[p.length - 1];
                var delimiters:Array<String> = new Array<String>();
                var t:Array<Array<String>> = getTypeParams(s, delimiters);
                var s:String = t[0][t[0].length - 1];
                for (i in 1...t.length) {
                    s += delimiters[i - 1] + t[i][t[i].length - 1];
                }
                if (delimiters.length == t.length) {
                    s += delimiters[delimiters.length - 1];
                }
                return TPath([s]);
            default: return t;
        }
    }

    public function shortenStringType(type:String):String {
        var delimiters:Array<String> = [];
        var t:Array<Array<String>> = getTypeParams(type, delimiters);
        var s:String = t[0][t[0].length - 1];
        for (i in 1...t.length) {
            s += delimiters[i - 1] + t[i][t[i].length - 1];
        }
        if (delimiters.length == t.length) {
            s += delimiters[delimiters.length - 1];
        }
        return s;
    }

    private function addTypeImports(program:Program, t:T):Void {
        switch(t) {
            case TDictionary(k, v):
                addTypeImports(program, k);
                addTypeImports(program, v);
            case TPath(p):
                var i:String;
                if (p.length == 1) {
                    p = p[0].split(".");
                    t = TPath(p);
                }
                i = getImportString(p, true);
                if (i.indexOf(">") != -1) {
                    for (t in getTypeParams(i)) {
                        if (t.length != 1 || t[0] != "Void" || t[0] != "Dynamic") {
                            addImport(program, TPath(t));
                        }
                    }
                } else {
                    addImport(program, t);
                }
            default:
                addImport(program, t);
        }
    }

    public function overrideIdentType(name:String, t:T, c:ClassDef = null):Void {
        if (c == null) {
            if (classDefs.exists(currentPath)) {
                c = classDefs.get(currentPath);
                overrideFieldType(currentPath, name, t);
            }
        } else {
            overrideFieldType(getClassPath(c), name, t);
        }
        if (c != null) {
            var f:ClassField = getField(name, _hostClassRef, c);
            c = _hostClassRef.value;
            if (f == null) return;
            switch(f.kind) {
                case FVar(oldT, val):
                    t = shortenTypeAndImport(c, t);
                    f.kind = FVar(t, val);
                case FFun(fun):
                    if (f.kwds.indexOf("get") == -1 && f.kwds.indexOf("set") == -1) {
                        switch(t) {
                            case TFunction(p):
                                overrideFunctionParams(fun, p, c);
                            default:
                                t = shortenTypeAndImport(c, t);
                                fun.ret.t = t;
                        }
                    } else if (fun.ret.t != null) {
                        t = shortenTypeAndImport(c, t);
                        fun.ret.t = t;
                    } else if (fun.args.length != 0) {
                        t = shortenTypeAndImport(c, t);
                        fun.args[0].t = t;
                    }
                default:
            }
        }
    }

    private function overrideFunctionParams(fun:Function, types:Array<T>, c:ClassDef = null):Void {
        fun.ret.t = types[types.length - 1];
        var expressionsToInsert:Array<Expr> = [];
        for (i in 0...types.length - 1) {
            var arg = fun.args[i];
            if (arg == null) continue;
            var t:T = types[i];
            if (!typesAreEqual(shortenType(t), arg.t)) {
                t = shortenTypeAndImport(c, t);
                var oldT:T = arg.t;
                var oldName:String = arg.name;
                arg.t = t;
                arg.name = "__" + oldName;
                var e:Expr = EIdent(arg.name);
                var ts:String = tstring(oldT);
                if (ts != "Dynamic") {
                    e = EBinop("as", e, EIdent(ts), false);
                }
                expressionsToInsert.push(ENL(EVars([{name:oldName, t:oldT, val:e}])));
                for (j in 0...arg.exprs.length) {
                    var e:Expr = arg.exprs[j];
                    switch(e) {
                        case EIdent(v):
                            arg.exprs[j] = EIdent(arg.name);
                        case ETypedExpr(e, oldT):
                            arg.exprs[j] = ETypedExpr(e, types[i]);
                        default:
                    }
                }
            }
        }
        if (expressionsToInsert.length > 0) {
            unshiftIntoFunction(fun, expressionsToInsert);
        }
    }

    private function unshiftIntoFunction(f:Function, toInsert:Array<Expr>):Void {
        var doInsert:Expr->Expr = null;
        doInsert = function(e) {
            if(e == null) return null;
            switch(e) {
                case EBlock(ex):
                    if (ex.length == 0) return doInsert(ex[0]);
                    if (ex.length > 0) {
                        ex[0] = ENL(ex[0]);
                    }
                    ex = toInsert.concat(ex);
                    return EBlock(ex);
                case ENL(ex): return doInsert(ex);
                case EObject(fl) if (fl.length == 0): return EBlock(toInsert);
                default:
                    toInsert.push(ENL(e));
                    return EBlock(toInsert);
            }
        }
        f.expr = doInsert(f.expr);
    }

    private function typesAreEqual(a:T, b:T):Bool {
        return tstring(a) == tstring(b);
    }


    private function getClassPath(c:ClassDef):String {
        var pack:String = classPacks[c];
        if (pack != null && pack.length > 0) {
            return pack + "." + c.name;
        } else {
            return c.name;
        }
    }

    public function getPackageString(i : Array<String>):String {
        if (i.length == 0) {
            return "";
        } else if (i[0] == "flash") {
            i[0] = cfg.flashTopLevelPackage;
            return i.join(".") + ".";
        } else {
            return Writer.properCaseA(i, false).join(".") + ".";
        }
    }

    public function getImportString(i : Array<String>, hasClassName:Bool) {
        if (i[0] == "flash") {
            i[0] = cfg.flashTopLevelPackage;
            return i.join(".");
        } else {
            return Writer.properCaseA(i, hasClassName).join(".");
        }
    }

    function resolveClassIdent(ident:String):String {
        if (classes.exists(ident)) {
            return ident;
        } else if (importsMap != null && importsMap.exists(ident)) {
            var t:String = importsMap.get(ident);
            if (t != null && classes.exists(t)) {
                return t;
            }
        }
        return null;
    }

    public function setPackage(pack:String):Void {
        this.pack = pack;
    }

    public function enterProgram(program:Program):Void {
        setPackage(getImportString(program.pack, false));
    }

    public function enterClass(path:String, c:ClassDef):Void {
        currentPath = path;
        //parentStaticFields = new Map<String,String>();
        staticContext = new Map<String,String>();
        var classMap:Map<String,String>;
        classMap = classes.get(path);
        var ic:ClassDef = c;
        var parentPath:String = path;
        if (ic.extend != null) {
            //classMap = new Map<String, String>();
            while (ic != null && ic.extend != null) {
                var packageString:String = parentPath.substring(0, parentPath.lastIndexOf("."));
                var path:String = getPathByType(ic.extend, ic, classPrograms[ic].pack, packageString);
                if (path != null) {
                    parentPath = path;
                    ic = classDefs.get(path);
                    if (ic == null) break;
                    parseStaticFields(parentPath, ic);
                } else {
                    ic = null;
                    break;
                }
                //switch (ic.extend) {
                    //case null:
                    //case TPath(p):
                        //var parentClassString:String = getImportString(p, true);
                        //var path:String = resolveClassIdent(parentClassString);
                        //if (path == null) {
                            //path = WriterImports.getImport(parentClassString, cfg, classes, ic, null, parentPath.substring(0, parentPath.lastIndexOf(".")));
                        //}
                        //if (path != null) {
                            //parentPath = path;
                            //ic = classDefs.get(path);
                            //if (ic == null) break;
                            //parseStaticFields(parentPath, ic);
                            ////var childClassMap:Map<String,String> = classes.get(path);
                            ////if (childClassMap != null) {
                                ////for (key in childClassMap.keys()) {
                                    ////classMap.set(key, childClassMap.get(key));
                                ////}
                            ////}
                        //} else {
                            //ic = null;
                            //break;
                        //}
                    //default:
                //}
            }
        } else {
            //classMap = classes.get(path);
        }
        parseStaticFields(path, c, true);
        var classMapCopy:Map<String,String> = new Map<String,String>();
        if (classMap != null) {
            for (key in classMap.keys()) {
                if (!staticContext.exists(key)) {
                    classMapCopy.set(key, classMap.get(key));
                }
            }
        }
        classMap = classMapCopy;
        //if (classMap == null) {
            //classMap = new Map<String, String>();
        //}
        //for (key in staticContext.keys()) {
            //if (classMap.exists(key)) {
                //classMap.remove(key);
            //}
        //}
        context = classMap;
        if (contextStack.length > 0) {
            contextStack[contextStack.length - 1] = context;
        }
    }

    public function getFullTypeName(ident:String, c:ClassDef = null):String {
        //switch(s) {
            //case "as3hx.Compat": return "as3hx.Compat";
            //case "Std": return "Std";
            //case "true", "false": return "Bool";
            //case "encodeURI", "decodeURI", "escape", "unescape": return "String->String";
            //default:
        //}
        //s = getModifiedIdent(s);
        if (ident == "null") return ident;
        if (context.exists(ident)) {
           return context.get(ident);
        } else if (staticContext.exists(ident)) {
           return staticContext.get(ident);
        } else if (importsMap != null && importsMap.exists(ident)) {
            var t:String = importsMap.get(ident);
            return t == null ? ident : t;
        } else if (classes.exists(ident)) {
            return ident;
        } else if (cfg.useOpenFlTypes && ident == "Dictionary") {
            return "openfl.utils.Dictionary";
        }
        var parentPath:String;
        if (c == null) {
            c = classDefs[currentPath];
            parentPath = currentPath;
        } else {
            parentPath = getClassPath(c);
            var fullTypeName:String = WriterImports.getImport(ident, cfg, classes, c, classPrograms[c], parentPath);
            if (fullTypeName != null) return fullTypeName;
        }
        while (c.extend != null) {
            parentPath = getPathByType(c.extend, c, null, parentPath.substr(0, parentPath.lastIndexOf(".")));
            if (parentPath != null && classes.exists(parentPath)) {
                c = classDefs.get(parentPath);
                var fullTypeName:String = WriterImports.getImport(ident, cfg, classes, c, classPrograms[c], parentPath);
                if (fullTypeName != null) return fullTypeName;
            } else break;
        }
        if (ident == "null" || ident == "this") return ident;
        //trace("UNKNOWN IDENT " + ident);
        return ident;
    }

    public function getFullTypeNameDescription(ident:String):String {
        //switch(s) {
            //case "as3hx.Compat": return "as3hx.Compat";
            //case "Std": return "Std";
            //case "true", "false": return "Bool";
            //case "encodeURI", "decodeURI", "escape", "unescape": return "String->String";
            //default:
        //}
        //s = getModifiedIdent(s);
        if (context.exists(ident)) {
            trace(1, context.get(ident));
           return context.get(ident);
        } else if (staticContext.exists(ident)) {
           trace(2, staticContext.get(ident));
           return staticContext.get(ident);
        } else if (importsMap != null && importsMap.exists(ident)) {
            var t:String = importsMap.get(ident);
            trace(3, t);
            return t == null ? ident : t;
        } else if (classes.exists(ident)) {
            trace(4, ident);
            return ident;
        } else if (cfg.useOpenFlTypes && ident == "Dictionary") {
            return "openfl.utils.Dictionary";
        }
        var c:ClassDef = classDefs[currentPath];
        var parentPath:String = currentPath;
        while (c.extend != null) {
            parentPath = getPathByType(c.extend, c, null, parentPath.substr(0, parentPath.lastIndexOf(".")));
            if (parentPath != null && classes.exists(parentPath)) {
                c = classDefs.get(parentPath);
                var fullTypeName:String = WriterImports.getImport(ident, cfg, classes, c, classPrograms[c], parentPath);
            trace(5, fullTypeName);
                if (fullTypeName != null) return fullTypeName;
            } else break;
        }
            trace(6, ident);
        if (ident == "null" || ident == "this") return ident;
        //trace("UNKNOWN IDENT " + ident);
        return ident;
    }

    public function setImports(importsMap:Map<String,String>, imported:Array<String>):Void {
        this.importsMap = new Map<String,String>();
        for (key in importsMap.keys()) {
            var fullPath:String = importsMap.get(key);
            if (fullPath != null) {
                this.importsMap.set(key, fullPath);
            }
        }
        var packMap:Map<String,String> = this.classesByPackages.get(pack);
        if (packMap != null) {
            for (key in packMap.keys()) {
                this.importsMap.set(key, packMap.get(key));
            }
        }

        if (imported != null) {
            for (key in imported) {
                var i:Int = key.lastIndexOf(".");
                this.importsMap.set(key.substr(i + 1), key);
            }
        }
    }

    public function enterFunction(f:Function, name:String, c:ClassDef = null):Void {
        openContext(f, name, c);
        for (arg in f.args) {
            context.set(arg.name, tstring(arg.t));
        }
        if (f.varArgs != null) {
            context.set(f.varArgs, "Array<Dynamic>");
        }
        function lookUpForTyping(expr:Expr):RebuildResult {
            switch(expr) {
                case EForEach(ev, e, block):
                    var etype:String = getExprType(e);
                    var isMap:Bool = etype != null && (etype.indexOf("Map") == 0 || etype.indexOf("Dictionary") == 0 || etype.indexOf("openfl.utils.Dictionary") == 0);
                    var isVector:Bool = etype != null && (etype.indexOf("Array") == 0 || etype.indexOf("Vector") == 0 || etype.indexOf("openfl.Vector") == 0);
                    var isXml:Bool = etype == "FastXML" || etype == "FastXMLList";
                    switch(ev) {
                        case EVars(vars):
                            if(vars.length == 1 && vars[0].val == null) {
                                var type:String;
                                if (isMap) {
                                    type = Typer.getMapParam(etype, 1);
                                    if (type == null) {
                                        type = "Dynamic";
                                    }
                                } else if (isVector) {
                                    type = getVectorParam(etype);
                                } else if (isXml) {
                                    type = etype;
                                } else {
                                    type = "Dynamic";
                                }
                                context.set(vars[0].name, type);
                                var re2:Expr = RebuildUtils.rebuild(e, lookUpForTyping);
                                var re3:Expr = RebuildUtils.rebuild(block, lookUpForTyping);
                                if (re2 != null || re3 != null) {
                                    if (re2 == null) re2 = e;
                                    if (re3 == null) re3 = block;
                                    return RebuildResult.RReplace(EForEach(ev, re2, re3));
                                } else {
                                    return RebuildResult.RSkip;
                                }
                            }
                        default:
                    }
                case EForIn(ev, e, block):
                    var etype:String = getExprType(e);
                    var isMap:Bool = etype != null && (etype.indexOf("Map") == 0 || etype.indexOf("Dictionary") == 0 || etype.indexOf("openfl.utils.Dictionary") == 0);
                    var isArray:Bool = etype != null && (etype.indexOf("Array<") == 0 || etype.indexOf("Vector<") == 0 || etype.indexOf("openfl.Vector<") == 0);
                    switch(ev) {
                        case EVars(vars):
                            if(vars.length == 1 && vars[0].val == null) {
                                var type:String;
                                if (isMap) {
                                    type = getMapIndexType(etype);
                                    if (type == null) {
                                        type = "Dynamic";
                                    }
                                } else if (isArray) {
                                    type = "Int";
                                } else {
                                    type = "String";
                                }
                                context.set(vars[0].name, type);
                                var re2:Expr = RebuildUtils.rebuild(e, lookUpForTyping);
                                var re3:Expr = RebuildUtils.rebuild(block, lookUpForTyping);
                                if (re2 != null || re3 != null) {
                                    if (re2 == null) re2 = e;
                                    if (re3 == null) re3 = block;
                                    return RebuildResult.RReplace(EForIn(ev, re2, re3));
                                } else {
                                    return RebuildResult.RSkip;
                                }
                            }
                        default:
                    }
                case EVars(vars):
                    for (v in vars) {
                        context.set(v.name, tstring(v.t));
                    }
                case EFunction(f, name):
                    if (name != null) {
                        context.set(name, tstring(getFunctionType(f)));
                    }
                    // Stop parsing this branch. We are not interested in variables in another scope
                    return RebuildResult.RSkip;
                default:
            }
            return null;
        }
        RebuildUtils.rebuild(f.expr, lookUpForTyping);
    }

    public function leaveFunction():Void {
        closeContext();
    }

    function parseStaticFields(path:String, c:ClassDef, remove:Bool = false):Void {
        for (field in c.fields) {
            if (!isStatic(field)) continue;

            var type:String = null;
            switch(field.kind) {
                case FVar(t, val):
                   type = tstring(t);
                case FFun(f):
                    if (isSetter(field)) {
                        type = tstring(f.args[0].t);
                    } else if (isGetter(field)) {
                        type = tstring(f.ret.t);
                    } else {
                        var constructorReturnType:T = field.name == c.name ? TPath([c.name]) : null;
                        type = tstring(getFunctionType(f, constructorReturnType));
                    }
                default:
            }
            if (remove) {
                parentStaticFields.remove(field.name);
                staticContext.remove(field.name);
            } else {
                parentStaticFields.set(field.name, path);
                staticContext.set(field.name, type);
            }
        }
    }

    function parseClassFields(p:Program, pack:String, path:String, c:ClassDef, map:Map<String,String>):Void {
        var imports:Map<String,String> = WriterImports.getImports(p, cfg, c);
        this.pack = pack;
        this.currentPath = path;
        setImports(imports, null);
        for (field in c.fields) {
            var type:T = null;
            switch(field.kind) {
                case FVar(t, val):
                    type = t;
                case FFun(f):
                    if (isSetter(field)) {
                        type = f.args[0].t;
                    } else if (isGetter(field)) {
                        type = f.ret.t;
                    } else {
                        var constructorReturnType:T = field.name == c.name ? TPath([pack.length > 0 ? pack + "." + c.name : c.name]) : null;
                        type = getFunctionType(f, constructorReturnType);
                    }
                default:
            }
            if (type != null) {
                map.set(field.name, tstring(expandType(type, c)));
            }
        }
    }

    inline function getRegexpType():String return cfg.useCompat ? "as3hx.Compat.Regex" : "flash.utils.RegExp";

    inline function isGetter(c:ClassField):Bool return Lambda.has(c.kwds, "get");

    inline function isSetter(c:ClassField):Bool return Lambda.has(c.kwds, "set");

    inline function isStatic(c:ClassField):Bool return Lambda.has(c.kwds, "static");


    /**
     * Opens a new context for variable typing
     */
    function openContext(f:Function = null, name:String = null, cl:ClassDef = null) {
        var c = new Map();
        for(k in context.keys())
            c.set(k, context.get(k));
        contextStack.push(context);
        if (f != null) {
            functionStack.push(f);
            functionStackName.push(name);
        }
        context = c;
    }

    /**
     * Closes the current variable typing context
     */
    function closeContext() {
        context = contextStack.pop();
        if (functionStack.length > 0) {
            functionStack.pop();
            functionStackName.pop();
        }
    }

    function hasImport(program:Program, path:Array<String>):Bool {
        for (p in program.imports) {
            if (p.length == path.length) {
                var samePath:Bool = true;
                for (i in 0...p.length) {
                    if (p[i] != path[i]) {
                        samePath = false;
                        break;
                    }
                }
                if (samePath) {
                    return true;
                }
            }
        }
        return false;
    }

    public function addImport(program:Program, t:T):Void {
        if (program.typesSeen.indexOf(t) != -1) return;
        program.typesSeen.push(t);
        switch(t) {
            case TPath(path):
                if (path.length == 1 && (CommonImports.getImports(cfg).exists(path[0]) || path[0].indexOf(".") == -1)) return;
                if (!hasImport(program, path)) {
                    program.imports.push(path);
                }
            default:
        }
    }

    function getConstructorType(c:ClassDef):Array<T> {
        var args:Array<T> = [];
        for (f in c.fields) {
            if (f.name == c.name) {
                switch(f.kind) {
                    case FFun(f):
                        for (arg in f.args) {
                            args.push(arg.t);
                        }
                    default:
                }
            }
        }
        return args;
    }

	public function getMapIndexType(s:String):String {
		var startIndex:Int = s.indexOf("<");
		if (startIndex == -1) return null;
		var commaIndex:Int = s.indexOf(",");
		if (commaIndex == -1) return null;
		return s.substring(startIndex + 1, commaIndex);
	}

    public function getPackString(expr:Expr):Array<String> {
        switch(expr) {
            case EIdent(s):
                return isExistingIdent(s) ? null : [s];
            case EField(e, f):
                var s:Array<String> = getPackString(e);
                if (s != null) {
                    s.push(f);
                }
                return s;
            default: return null;
        }
    }

    public static function getFunctionType(f:Function, constructorReturnType:T = null):T {
        var t = f.args.map(function(it) return it.t);
        if(f.varArgs != null) t.push(TPath(["Array<Dynamic>"]));
        if (t.length == 0) t.push(TPath(["Void"]));
        if (constructorReturnType != null) {
            t = [constructorReturnType];
        } else {
            t.push(f.ret.t);
        }
        return TFunction(t);
    }

    public static function properCase(pkg:String, hasClassName:Bool):String {
        var openIndex:Int = pkg.indexOf("<");
        if (openIndex == -1) {
            return Writer.properCase(pkg, hasClassName);
        } else {
            return Writer.properCase(pkg.substr(0, openIndex), hasClassName) + pkg.substr(openIndex);
        }
    }

    public static function getVectorParam(s:String):String {
        var openIndex:Int = s.indexOf("<");
        if (openIndex == -1) return "Dynamic";
        var closeIndex:Int = s.lastIndexOf(">");
        if (closeIndex == -1) return "Dynamic";
        return s.substring(openIndex + 1, closeIndex);
    }
    public static function getMapParam(s:String, index:Int):String {
        var openIndex:Int = s.indexOf("<");
        if (openIndex == -1) return "Dynamic";
        var splitIndex:Int = -1;
        var depth:Int = 0;
        for (i in openIndex + 1...s.length) {
            switch (s.charCodeAt(i)) {
                case '<'.code: depth++;
                case '>'.code: depth--;
                case ','.code:
                    if (depth == 0) {
                        splitIndex = i;
                        break;
                    }
            }
        }
        if (splitIndex != -1) {
            if (index == 0) {
                return s.substring(openIndex + 1, splitIndex);
            } else if (index == 1) {
                return s.substring(splitIndex + 1, s.length - 1);
            } else {
                return "Dynamic";
            }
        } else {
            return "Dynamic";
        }
    }
}

class Reference<T> {
    public var value:T;
    public function new() {  }
}