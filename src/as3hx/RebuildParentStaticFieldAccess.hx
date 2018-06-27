package as3hx;
import as3hx.As3.Expr;
import as3hx.As3.Program;
import as3hx.RebuildUtils.RebuildResult;

/**
 * ...
 * @author
 */
class RebuildParentStaticFieldAccess {
    private var cfg:Config;
    private var typer:Typer;
    private var program:Program;

    public function new(cfg:Config, typer:Typer) {
        this.cfg = cfg;
        this.typer = typer;
    }

    public function apply(program:Program):Void {
        this.program = program;
        RebuildUtils.rebuildProgram(program, cfg, typer, rebuild);
    }

    private function rebuild(expr:Expr):RebuildResult {
        switch(expr) {
            case EIdent(v):
                var staticFieldHost:String = typer.getIsStaticField(v);
                if (staticFieldHost != null) {
                    var a:Array<String> = staticFieldHost.split(".");
                    typer.addImport(program, TPath(a));
                    var staticFieldHostName:String = a[a.length - 1];
                    return RebuildResult.RReplace(EField(EIdent(staticFieldHostName), v));
                }
            default:
            //if (staticFieldHost != null) {
                //write(staticFieldHost + ".");
            //}
        }
        return null;
    }
}