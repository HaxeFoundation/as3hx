package as3hx;
import as3hx.As3.Expr;
import as3hx.RebuildUtils.RebuildResult;
import neko.Lib;

/**
 * ...
 * @author xmi
 */


class LoopPosition {
    public function new() { }
    public var expr:Expr;
    public var num:Int;
}

class ForLoopRebuild
{
    private var loopsListPerLoopVar:Map<String,Array<LoopPosition>> = new Map<String,Array<LoopPosition>>();
    private var loopsListPerLoopVarStack:Array<Map<String,Array<LoopPosition>>> = new Array<Map<String,Array<LoopPosition>>>();
    private var loopNumToReplace:Map<Int,Bool> = new Map<Int,Bool>();
    private var forLoopNum:Int = 0;

    public function new() {

    }
    private function rebuildLookUpPassArray(expressions:Array<Expr>):Array<Expr> {
        var needUpdate:Bool = false;
        var newExpressions:Array<Expr> = [];
        for (e in expressions) {
            processLookUpPassExpr(e);
            var re:Array<Expr> = RebuildUtils.rebuildArray([e], rebuildLookUpPass);
            if (re != null) {
                for (r in re) {
                    newExpressions.push(r);
                }
                needUpdate = true;
            } else {
                newExpressions.push(e);
            }
        }
        if (needUpdate) {
            return newExpressions;
        } else {
            return null;
        }
    }
    
    public function replaceForLoopsWithWhile(expressions:Array<Expr>):Array<Expr> {
        forLoopNum = 0;
        
        var re:Array<Expr> = rebuildLookUpPassArray(expressions);
        var rexpr:Expr = RebuildUtils.rebuild(EBlock(expressions), rebuildLookUpPass);
        switch(rexpr) {
            case null:
            case EBlock(es):
                expressions = es;
            default:
        }
        
        forLoopNum = 0;
        re = RebuildUtils.rebuildArray(expressions, rebuildReplacePass);
        if (re != null) {
            expressions = re;
        }
        return expressions;
    }
 

    private function openBlockContext():Void {
        loopsListPerLoopVarStack.push(loopsListPerLoopVar);
        loopsListPerLoopVar = new Map<String,Array<LoopPosition>>();
    }

    private function closeBlockContext():Void {
        var old:Map<String,Array<LoopPosition>> = loopsListPerLoopVar;
        loopsListPerLoopVar = loopsListPerLoopVarStack.pop();
        for (key in old.keys()) {
            if (loopsListPerLoopVar.exists(key)) {
                loopsListPerLoopVar.set(key, loopsListPerLoopVar.get(key).concat(old.get(key)));
            } else {
                loopsListPerLoopVar.set(key, old.get(key));
            }
        }
    }

    private function convertEForToEWhile(inits:Array<Expr>, conds:Array<Expr>, incrs:Array<Expr>, expr:Expr):Array<Expr> {
        incrs = incrs.map(function(e) return ENL(e));
        function insertIncrementsBeforeContinue(e:Expr):RebuildResult {
            switch(e) {
                case EFunction(_, _):
                    return RebuildResult.RSkip;
                case EContinue:
                    return RebuildResult.RReplace(EBlock( incrs.concat([ENL(e)])));
                default:
            }
            return null;
        }
        var r:Expr = RebuildUtils.rebuild(expr, insertIncrementsBeforeContinue);
        if (r == null) {
            r = expr;
        }
        
        var condition:Expr;
        if (conds.length == 0) {
            condition = EIdent("true");
        } else {
            condition = conds[0];
            for (i in 1...conds.length) {
                condition = EBinop("&&", condition, conds[i], false);
            }
        }
        
        var whileBody:Array<Expr> = switch(r) {
            case EBlock(e): e;
            default: [r];
        }
        whileBody = whileBody.concat(incrs);
        
        var result:Array<Expr> = [];
        for (init in inits) {
            result.push(init);
        }
        result.push(EWhile(condition, EBlock(whileBody), false));
        
        return result;
    }

    private static function getForLoopVariable(incrementExprs:Array<Expr>):String {
        if (incrementExprs.length < 1) return null;
        switch(incrementExprs[0]) {
            case null: return null;
            case EBinop(_, e, _, _):
                switch(e) {
                    case EIdent(s): return s;
                    default:
                }
            case EUnop(_, _, e):
                switch(e) {
                    case EIdent(s): return s;
                    default:
                }
            default:
        }
        return null;
    }

    private function rebuildReplacePass(expr:Expr):RebuildResult {
        switch(expr) {
            case EFor(inits, conds, incrs, e):
                if (loopNumToReplace.exists(forLoopNum++)) {
                    var res:Array<Expr> = convertEForToEWhile(inits, conds, incrs, e);
                    
                    var resRebuild:Array<Expr> = RebuildUtils.rebuildArray(res, rebuildReplacePass);
                    if (resRebuild != null) {
                        res = resRebuild;
                    }
                    
                    return RebuildResult.RReplaceArray(res);
                }
            default:
        }
        return null;
    }

    private function storeLoop(loopVariable:String, loop:LoopPosition):Void {
        if (loopsListPerLoopVar.exists(loopVariable)) {
            loopsListPerLoopVar.get(loopVariable).push(loop);
        } else {
            loopsListPerLoopVar.set(loopVariable, [loop]);
        }
    }

    private function dropLoops(loopVariable:String):Void {
        if (loopsListPerLoopVar.exists(loopVariable)) {
            loopsListPerLoopVar.remove(loopVariable);
        }
    }

    private function replaceLoops(loopVariable:String):Void {
        if (loopsListPerLoopVar.exists(loopVariable)) {
            for (f in loopsListPerLoopVar.get(loopVariable)) {
                loopNumToReplace.set(f.num, true);
                
            }
            loopsListPerLoopVar.remove(loopVariable);
        }
    }
    
    private function processLookUpPassExpr(expr:Expr):Void {
        var loopVariablesAccess:Map<String,Bool> = getOverwrittenIdents(expr, loopsListPerLoopVar);
        for (loopVariable in loopVariablesAccess.keys()) {
            var wasOverwritten:Bool = loopVariablesAccess.get(loopVariable);
            if (wasOverwritten) {
                dropLoops(loopVariable);
            } else {
                replaceLoops(loopVariable);
            }
        }
    }

    private function rebuildLookUpPass(expr:Expr):RebuildResult {
        switch(expr) {
            case EFor(inits, conds, incrs, e):
                if (!canUseForLoop(inits, conds, incrs, e)) {
                    var r:Expr = RebuildUtils.rebuild(e, rebuildLookUpPass);
                    if (r != null) e = r;
                    var res:Array<Expr> = convertEForToEWhile(inits, conds, incrs, e);
                    return RebuildResult.RReplaceArray(res);
                } else {
                    var loopVariable:String = getForLoopVariable(incrs);
                    var loop:LoopPosition = new LoopPosition();
                    loop.expr = expr;
                    loop.num = forLoopNum++;
                    storeLoop(loopVariable, loop);
                    
                    var r:Expr = RebuildUtils.rebuild(e, rebuildLookUpPass);
                    if (r != null) {
                        return RebuildResult.RReplace(EFor(inits, conds, incrs, r));
                    } else {
                        return RebuildResult.RSkip;
                    }
                }
            case EBlock(expressions):
                openBlockContext();
                var newExpressions:Array<Expr> = rebuildLookUpPassArray(expressions);
                closeBlockContext();
                if (newExpressions != null) {
                    return RebuildResult.RReplace(EBlock(newExpressions));
                } else {
                    return RebuildResult.RSkip;
                }
            default:
        }
        return null;
    }
    
    private static function canUseForLoop(inits:Array<Expr>, conds:Array<Expr>, incrs:Array<Expr>, e:Expr):Bool {
        if (inits.length == 0 || conds.length != 1 || incrs.length != 1) return false;
        var loopVariable:String = getForLoopVariable(incrs);
        var loopIdent:Expr = EIdent(loopVariable);
        
        // if variable is not set up before loop, no FOR
        switch(inits[inits.length - 1]) {
            case EBinop("=", e1, e2, _):
                if (!e1.equals(loopIdent)) {
                    return false;
                }
            case EVars(vars) if(vars.length > 1): return false;
            default: return false;
        }
        
        // if comparison is not `variable less then value`, no FOR
        switch(conds[0]) {
            case EBinop(op, e1, e2, _):
                if (op == "<" || op == "<=") {
                    if (!e1.equals(loopIdent)) {
                        return false;
                    }
                } else if (op == ">" || op == ">=") {
                    if (!e2.equals(loopIdent)) {
                        return false;
                    }
                } else {
                    return false;
                }
            default: return false;
        }
        
        // if variable is not incremented by 1, no FOR
        switch(incrs[0]) {
            case EUnop("++", _, e1):
                if (!e1.equals(loopIdent)) {
                    return false;
                }
            case EBinop("+=", e1, e2, _):
                if ( !e1.equals(loopIdent) || (!e2.equals(EConst(CInt("1"))) && !e2.equals(EConst(CFloat("1.0")))) ) {
                    return false;
                }
            case null: return false;
            default: return false;
        }

        // if variable is modified inside of loop, no FOR
        if (checkIfUsesIdentForWriting(loopVariable, e, false)) {
            return false;
        }
        
        return true;
    }
    
    private function getOverwrittenIdents(e:Expr, blockContext:Map<String,Array<LoopPosition>>):Map<String,Bool> {
        var result:Map<String,Bool> = new Map<String,Bool>();
        for (key in loopsListPerLoopVar.keys()) {
            if (checkIfUsesIdentValue(key, e)) {
                result.set(key, false);
            } else if (checkIfUsesIdentForWriting(key, e, true)) {
                result.set(key, true);
            }
        }
        return result;
    }
    
    public static function checkIfUsesIdentValue(ident:String, expr:Expr):Bool {
        var wasUsed:Bool = false;
        function rebuild(e:Expr):RebuildResult {
            switch(e) {
                case EBlock(es):
                    for (e in es) {
                        if (checkIfUsesIdentValue(ident, e)) {
                            wasUsed = true;
                            break;
                        } else if (checkIfUsesIdentForWriting(ident, e, false)) {
                            break;
                        }
                    }
                    return RebuildResult.RSkip;
                case EFor(inits, conds, incrs, e):
                    var uses:Bool = false;
                    var overwrites:Bool = false;
                    for (i in inits) {
                        if (checkIfUsesIdentValue(ident, i)) {
                            uses = true;
                        } else if (checkIfUsesIdentForWriting(ident, i, false)) {
                            overwrites = true;
                        }
                    }
                    if (overwrites && !uses) {
                        return RebuildResult.RSkip;
                    }
                case EIdent(v):
                    if (v == ident) {
                        wasUsed = true;
                        return RebuildResult.RSkip;
                    }
                case EBinop(op, e1, e2, _):
                    if (op == "=" && isIdent(e1, ident)) {
                        RebuildUtils.rebuild(e2, rebuild);
                        return RebuildResult.RSkip;
                    }
                case EUnop(op, _, e):
                    if (isIdent(e, ident)) {
                        wasUsed = true;
                        return RebuildResult.RSkip;
                    }
                default:
            }
            return null;
        }
        RebuildUtils.rebuild(expr, rebuild);
        return wasUsed;
    }
    
    public static function checkIfUsesIdentForWriting(ident:String, expr:Expr, definitelyOverwritten:Bool):Bool {
        var result:Bool = false;
        function rebuild(e:Expr):RebuildResult {
            switch(e) {
                case EIf(cond, e1, e2):
                    if (definitelyOverwritten) {
                        if (!result && checkIfUsesIdentForWriting(ident, e1, definitelyOverwritten) && checkIfUsesIdentForWriting(ident, e2, definitelyOverwritten)) {
                            result = true;
                        }
                        return RebuildResult.RSkip;
                    }
                case EBinop(op, e1, _, _):
                    if (op.indexOf("=") != -1 && isIdent(e1, ident)) {
                        result = true;
                        return RebuildResult.RSkip;
                    }
                case EUnop(op, _, e):
                    if (isIdent(e, ident)) {
                        result = true;
                        return RebuildResult.RSkip;
                    }
                default:
            }
            return null;
        }
        RebuildUtils.rebuild(expr, rebuild);
        return result;
    }
    
    public static function isIdent(e:Expr, ident:String):Bool {
        switch(e) {
            case EParent(e): return isIdent(e, ident);
            case EIdent(v): return v == ident;
            default:
        }
        return false;
    }
}