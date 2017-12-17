package as3hx;
import as3hx.As3.ClassDef;
import as3hx.As3.ClassField;
import as3hx.As3.Expr;
import as3hx.As3.Function;
import as3hx.As3.T;
import as3hx.RebuildUtils.RebuildResult;
import neko.Lib;

/**
 * AS3 typing allows multiple equal variable type declarations in one method and opens new variable context only inside function, not in any {} block
 */
class Typer
{
    var cfg:Config;
    var classes : Map<String,Map<String,String>> = new Map<String,Map<String,String>>();
    var context : Map<String,String> = new Map<String,String>();
    var contextStack : Array<Map<String,String>> = [];

    public function new(cfg:Config) {
        this.cfg = cfg;
    }

    public function getExprType(e:Expr):Null<String> {
        switch(e) {
            case ETypedExpr(e2, t): return tstring(t);
            case EField(e2, f):
                switch(e2) {
                    case EIdent("this"): return contextStack[0].get(f);
                    default:
                }
                var t2 = getExprType(e2);
                //write("/* e2 " + e2 + "."+f+" type: "+t2+" */");
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
                if (ts != null && classes.exists(ts)) {
                    return classes.get(ts).get(f);
                } else {
                    return null;
                }
            case EIdent(s):
                s = getModifiedIdent(s);
                return context.get(s);
            case EVars(vars) if(vars.length == 1): return tstring(vars[0].t);
            case EArray(n, _): return getExprType(n);
            case EArrayDecl(_): return "Array<Dynamic>";
            case EUnop(_, _, e2): return getExprType(e2);
            case EBinop(_ => "/", _, _, _): return "Float";
            case EBinop(_, e1, e2, _) if(getExprType(e1) != "Float" && getExprType(e2) != "Float"): return "Int";
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
            case "Object": "Dynamic";
            case "undefined": "null";
            //case "Error": cfg.mapFlClasses ? "flash.errors.Error" : s;
            case "XML": "FastXML";
            case "XMLList": "FastXMLList";
            case "NaN":"Math.NaN";
            case "Dictionary": cfg.dictionaryToHash ? "haxe.ds.ObjectMap" : s;
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
        parseClassFields(c, classMap);
        classes[path] = classMap;
    }

    public function enterClass(path, c:ClassDef):Void {
        var classMap:Map<String,String> = classes.get(path);
        if (classMap == null) {
            classMap = new Map<String, String>();
            parseClassFields(c, classMap);
        }
        context = classMap;
    }

    public function enterFunction(f:Function):Void {
        openContext();
        for (arg in f.args) {
            context.set(arg.name, tstring(arg.t));
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

    function parseClassFields(c:ClassDef, map:Map<String,String>):Void {
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