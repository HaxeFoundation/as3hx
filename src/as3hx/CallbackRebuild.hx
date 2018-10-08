package as3hx;
import as3hx.As3.Expr;
import as3hx.As3.Function;
import as3hx.As3.Program;
import as3hx.As3.T;
import as3hx.RebuildUtils.RebuildResult;

/**
 * ...
 * @author
 */
class CallbackRebuild {
    private var cfg:Config;
    private var typer:Typer;

    public function new(cfg:Config, typer:Typer) {
        this.cfg = cfg;
        this.typer = typer;
    }


    public function apply(program:Program):Void {
        RebuildUtils.rebuildProgram(program, cfg, typer, rebuild);
    }

    private function rebuild(expr:Expr):RebuildResult {
        switch (expr) {
            case ECall(e, params) :
                var args:Array<T> = typer.getFunctionArgTypes(e);
                if (args != null) {
                    for (i in 0...args.length) {
                        var a = args[i];
                        if (a != null && params[i] != null) {
                            var t:String = typer.tstring(a);
                            if (t != null && t.indexOf("->") != -1) {
                                var ps:Array<String> = t.split("->");
                                if (ps[0] != "T") {
                                    var pt:Array<T> = ps.map(function(s:String):T { return TPath([typer.expandStringType(s)]); });
                                    typer.overrideExprType(params[i], TFunction(pt));
                                }
                            }
                        }
                    }
                }
            default:
        }
        return null;
    }

}