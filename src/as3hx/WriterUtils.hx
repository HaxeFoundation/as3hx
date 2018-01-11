package as3hx;
import as3hx.As3.Expr;
import as3hx.As3.SwitchCase;
import as3hx.As3.SwitchDefault;
import as3hx.As3.T;
import as3hx.RebuildUtils.RebuildResult;
import neko.Lib;

class WriterUtils 
{
    /**
     * In AS3 local function declarations are available all throw parent function, but in haxe we need to declare them before usage.
     * So we need to relocate local functions that they preceded the usage expressions.
     * To keep result code more consistent let's move all function declarations to the begining of parent function.
     **/
    public static function moveFunctionDeclarationsToTheTop(expressions:Array<Expr>):Array<Expr> {
        var localFunctionDeclarations:Array<Expr> = [];
        function lookUpForLocalFunctions(e:Expr):RebuildResult {
            switch(e) {
                case EBinop(op, e1, e2, newLineAfterOp):
                    if (op == "=") {
                        switch(e2) {
                            case EFunction(f, name):
                                return RebuildResult.RSkip;
                            default:
                        }
                    }
                    return RebuildResult.RSkip;
                case EFunction(f, name):
                    if (name != null) {
                        localFunctionDeclarations.push(ENL(e));
                        return RebuildResult.REmpty;
                    } else {
                        return RebuildResult.RSkip;
                    }
                default:
            }
            return null;
        }
        var expressionsWithoutFunctions:Array<Expr> = RebuildUtils.rebuildArray(expressions, lookUpForLocalFunctions);
        if (expressionsWithoutFunctions == null) {
            expressionsWithoutFunctions = expressions;
        }
        return localFunctionDeclarations.concat(expressionsWithoutFunctions);
    }
    
    public static function replaceForLoopsWithWhile(expressions:Array<Expr>):Array<Expr> {
        return new ForLoopRebuild().replaceForLoopsWithWhile(expressions);
    }
}