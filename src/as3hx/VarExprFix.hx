package as3hx;
import as3hx.As3.Expr;
import as3hx.As3.Function;
import as3hx.RebuildUtils.RebuildResult;
import neko.Lib;

/**
 * ...
 * @author xmi
 */
class VarExprFix
{
    private var cfg:Config;
    
    public function new(cfg:Config){
        this.cfg = cfg;
    }
    
    public function apply(f:Function, es:Array<Expr>, typer:Typer):Array<Expr> {
        var map:Map<String,String> = typer.getContextClone(-1);
        var firstUse:Map<String,Int> = new Map<String,Int>();
        var firstUseLine:Map<Int,Array<String>> = new Map<Int,Array<String>>();
        for (v in map.keys()) {
            firstUse.set(v, -1);
        }
        for (arg in f.args) {
            firstUse.set(arg.name, -1);
        }
        if (f.varArgs != null && !cfg.replaceVarArgsWithOptionalArguments) {
            firstUse.set(f.varArgs, -1);
        }
        var line:Int = 0;
        function rebuildMethodLookForVars(e:Expr):RebuildResult {
            switch(e) {
                case EIdent(v):
                    if (v != null && !firstUse.exists(v)) {
                        firstUse.set(v, line);
                        if (firstUseLine.exists(line)) {
                            firstUseLine.get(line).push(v);
                        } else {
                            firstUseLine.set(line, [v]);
                        }
                    }
                case EFunction(f, v):
                    if (v != null) {
                        map.set(v, "Function");
                    }
                case EVars(vars/*Array<{ name : String, t : Null<T>, val : Null<Expr> }>*/):
                    var newVars:Array<Expr> = [];
                    var hasChange:Bool = false;
                    for (vr in vars) {
                        var v:String = vr.name;
                        if (!firstUse.exists(v)) {
                            firstUse.set(v, -1);
                            newVars.push(EVars([vr]));
                        } else {
                            hasChange = true;
                            if (vr.val != null) {
                                newVars.push(EBinop("=", EIdent(v), vr.val, false));
                            }
                        }
                        map.set(v, typer.tstring(vr.t));
                    }
                    if (hasChange) {
                        return RebuildResult.RReplaceArray(newVars);
                    }
                default:
            }
            return null;
        }
        function rebuildMethodPutVars(e:Expr):Array<Expr> {
            if (firstUseLine.exists(line)) {
                var res:Array<Expr> = [];
                for (name in firstUseLine.get(line)) {
                    var type:String = map.get(name);
                    if (type == null) continue;
                    var defaultValue:Expr = null;
                    switch(type) {
                    case "int", "Int", "UInt":
                        defaultValue = EConst(CInt("0"));
                    case "Float":
                        defaultValue = EConst(CInt("Math.NaN"));
                    default:
                        defaultValue = EIdent("null");
                    }
                    res.push(ENL( EVars([ { name:name, t:TPath([type]), val:defaultValue } ])));
                }
                if (res.length > 0 ) {
                    res.push(e);
                    return res;
                }
            }
            return null;
        }
        var res:Array<Expr> = [];
        res = RebuildUtils.rebuildArray(es, rebuildMethodLookForVars);
        if (res == null) {
            res = es;
        }
        es = res;
        res = [];
        for (i in 0...es.length) {
            line = i;
            var e:Expr = es[i];
            var a:Array<Expr> = rebuildMethodPutVars(e);
            if (a != null) {
                for (e in a) {
                    res.push(e);
                }
            } else {
                res.push(e);
            }
        }
        return res;
    }
}