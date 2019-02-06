package as3hx;
import as3hx.As3.ClassDef;
import as3hx.As3.Expr;
import as3hx.As3.Function;
import as3hx.As3.Program;
import as3hx.As3.T;
import as3hx.DictionaryRebuild.ComplexType;
import as3hx.RebuildUtils.RebuildResult;
import neko.Lib;

class ComplexType {
    public var types:Array<ComplexType>;
    public var name:String;
    public function new(name:String, types:Array<ComplexType>):Void {
        this.name = name;
        this.types = types;
    }
}

typedef DictionaryTypes = {
    key:Array<String>,
    value:Array<String>
}

/**
 * ...
 * @author ...
 */
class DictionaryRebuild
{
    var classFieldDictionaryTypes : Map<String,Map<String,DictionaryTypes>> = new Map<String,Map<String,DictionaryTypes>>();
    var typer:Typer;
    var cfg:Config;

    public function new(typer:Typer, cfg:Config) {
        this.typer = typer;
        this.cfg = cfg;
    }

    function getUnderlyingIdent(expr:Expr):Expr {
        switch(expr) {
            case EArray(e, index):
                return getUnderlyingIdent(e);
            case EField(e, f):
                return e;
            case EIdent(v):
                return expr;
            default:
                return null;
        }
    }


    private function isOpenFlDictionaryType(s:String):Bool {
        return s != null && (StringTools.startsWith(s, "Dictionary") || StringTools.startsWith(s, "openfl.utils.Dictionary")) && cfg.useOpenFlTypes;
    }

    public function applyRefinedTypes(program:Program):Void {
        for (i in 0...4) {
            refineTypes(program);
        }
    }

    public function refineTypes(program:Program):Void {
        var currentClass:String = null;
        var pack:String = typer.getPackageString(program.pack);

        function refineArrayAccess(e1:Expr, index:Expr, valueType:String):Void {
            var type1:String = typer.getExprType(e1);
            var identExpr:Expr = getUnderlyingIdent(e1);
            var identType:String = typer.getExprType(identExpr);
            switch(e1) {
                case EArray(e, i):
                    var newStringType:String = "Dictionary<" + typer.getExprType(index) + "," + valueType + ">";
                    refineArrayAccess(e, i, newStringType);
                    return;
                default:
            }
            if (type1 != null && (StringTools.startsWith(type1, "Dictionary") || StringTools.startsWith(type1, "openfl.utils.Dictionary"))) {
                var baseType:String = null;
                var field:String = null;
                switch(e1) {
                    case EField(e2, f):
                        baseType = typer.getExprType(e2);
                        field = f;
                    case EIdent(s):
                        baseType = pack + currentClass;
                        field = s;
                    default:
                }
                if (field != null && baseType != null) {
                    if (typer.classes.exists(baseType)) {
                        var indexType:String = typer.getExprType(index);
                        var newStringType:String = foldStringType(field, typer.expandStringType(type1), typer.expandStringType(indexType), typer.expandStringType(valueType));
                        if (newStringType != type1) {
                            typer.overrideIdentType(field, typer.expandType(TPath([newStringType])));
                        }
                    }
                }
            }
        }
        var returnType:T = null;
        function rebuild(expr:Expr):RebuildResult {
            switch(expr) {
                case EFunction(f, name):
                    typer.enterFunction(f, name);
                    var oldReturnType:T = returnType;
                    returnType = f.ret.t;
                    var re:Expr = RebuildUtils.rebuild(f.expr, rebuild);
                    f.ret.t = returnType;
                    returnType = oldReturnType;
                    typer.leaveFunction();
                    if (re != null) {
                        return RebuildResult.RReplace(EFunction({args: f.args, varArgs: f.varArgs, ret:f.ret, expr:re}, name));
                    } else {
                        return RebuildResult.RSkip;
                    }
                case EReturn(e):
                    switch(e) {
                        case EArray(e, index):
                            refineArrayAccess(e, index, typer.tstring(returnType));
                            RebuildUtils.rebuild(e, rebuild);
                            RebuildUtils.rebuild(index, rebuild);
                            return RebuildResult.RSkip;
                        case null:
                        default:
                            var newType:String = typer.getExprType(e);
                            if (isOpenFlDictionaryType(newType)) {
                                var oldType:String = typer.expandStringType(typer.tstring(returnType));
                                newType = foldDictionaryType2(oldType, newType);
                                newType = typer.shortenStringType(newType);
                                if (oldType != newType) {
                                    returnType = TPath([newType]);
                                }
                            }
                    }
                case EVars(vars):
                    for (v in vars) {
                        switch(v.val) {
                            case ETypedExpr(e, t):
                                switch(e) {
                                    case EArray(e1, index):
                                        refineArrayAccess(e1, index, typer.tstring(v.t));
                                        RebuildUtils.rebuild(e1, rebuild);
                                        RebuildUtils.rebuild(index, rebuild);
                                        return RebuildResult.RSkip;
                                    case null:
                                    default:
                                }
                            case null:
                            default:
                        }
                    }
                case EBinop("=", e1, e2, _):
                    switch(e1) {
                        case EArray(e1, index):
                            refineArrayAccess(e1, index, typer.getExprType(e2));
                            RebuildUtils.rebuild(e1, rebuild);
                            RebuildUtils.rebuild(index, rebuild);
                            return RebuildResult.RSkip;
                        default:
                    }
                    switch(e2) {
                        case EArray(e2, index):
                            refineArrayAccess(e2, index, typer.getExprType(e1));
                            RebuildUtils.rebuild(e2, rebuild);
                            RebuildUtils.rebuild(index, rebuild);
                            return RebuildResult.RSkip;
                        default:
                    }
                case EArray(e1, index):
                    refineArrayAccess(e1, index, "Dynamic");
                default:
            }
            return null;
        }

        typer.enterProgram(program);
        for (d in program.defs) {
            switch (d) {
                case CDef(c):
                    typer.setImports(WriterImports.getImports(program, cfg, c), null);
                    typer.enterClass(pack + c.name, c);
                    currentClass = c.name;
                    for (field in c.fields) {
                        switch(field.kind) {
                            case FFun(f):
                                typer.enterFunction(f, field.name, c);
                                returnType = f.ret.t;
                                RebuildUtils.rebuild(f.expr, rebuild);
                                f.ret.t = returnType;
                                typer.leaveFunction();
                            default:
                        }
                    }
                case FDef(f):
                    returnType = f.f.ret.t;
                    RebuildUtils.rebuild(f.f.expr, rebuild);
                default:
            }
        }
    }

    function foldStringType(field:String, old:String, newKey:String, newValue:String):String {
        var openIndex:Int = old.indexOf("<");
        if (openIndex == -1) {
            return "Dictionary<" + newKey + "," + newValue + ">";
        }
        var name:String = old.substr(0, openIndex);
        var depth:Int = 0;
        var splitIndex:Int = -1;
        for (i in openIndex + 1...old.length) {
            switch (old.charCodeAt(i)) {
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
            var oldKey:String = old.substring(openIndex + 1, splitIndex);
            var oldValue:String = old.substring(splitIndex + 1, old.length - 1);
            newKey = foldDictionaryType2(oldKey, newKey);
            newValue = foldDictionaryType2(oldValue, newValue);
        }
        return name + "<" + newKey + "," + newValue + ">";
    }

    function foldDictionaryType2(a:String, b:String):String {
        if (a == b) return a;
        //use <T> as type param
        if (a == "T") return a;
        if (b == "T") return b;

        var aIsAny:Bool = a == "Dynamic" || a == "Object" || a == CommonImports.ObjectImport || a == null || a == "null";
        var bIsAny:Bool = b == "Dynamic" || b == "Object" || b == "openfl.utils.Object" || b== "" || b == null || b == "null";
        if (aIsAny && bIsAny) return "Dynamic";
        if (aIsAny) return b;
        if (bIsAny) return a;

        if (a == "String") return a;
        if (b == "String") return b;

        if ((a.indexOf("openfl.utils.Dictionary") == 0 || a.indexOf("Dictionary") == 0) && (b.indexOf("openfl.utils.Dictionary") == 0 || b.indexOf("Dictionary") == 0)) {
            var newKey:String = foldDictionaryType2(Typer.getMapParam(a, 0), Typer.getMapParam(b, 0));
            var newValue:String = foldDictionaryType2(Typer.getMapParam(a, 1), Typer.getMapParam(b, 1));
            if (newKey == "null") newKey = "Dynamic";
            if (newValue == "null") newValue = "Dynamic";
            return "openfl.utils.Dictionary<" + newKey + "," + newValue + ">";
        }
        if (typer.doImplements(a, b)) return b;
        if (typer.doImplements(b, a)) return a;
        return "Dynamic";
    }


    /** it could be better if we would refine single value on occurance but not to collect all types */
    function refineStringType(types:Array<String>, type:String):Void {
        if (type != null) {
            types.push(type);
        }
    }
}