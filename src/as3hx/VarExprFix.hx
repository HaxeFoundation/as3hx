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
        var map:Map<String,String> = typer.getContextClone(0);
        var localVar:Map<String,Bool> = new Map<String,Bool>();
        var firstUse:Map<String,Int> = new Map<String,Int>();
        var firstUseLine:Map<Int,Array<String>> = new Map<Int,Array<String>>();
        var blockVars:Array<String> = new Array<String>();
        var restrictedVars:Array<String> = new Array<String>();
        var varsToIgnore:Array<String> = new Array<String>();
        var localFunctionVars:Map<String,Bool>;
        var hasVarsToInsert:Bool = false;
        var inLocalFunction:Bool = false;
        var line:Int = 0;
        var depth:Int = 0;
        for (v in map.keys()) {
            firstUse.set(v, -1);
            localVar.set(v, false);
        }
        for (arg in f.args) {
            firstUse.set(arg.name, -1);
            localVar.set(arg.name, true);
        }
        if (f.varArgs != null && !cfg.replaceVarArgsWithOptionalArguments) {
            firstUse.set(f.varArgs, -1);
            localVar.set(f.varArgs, true);
        }
        function rebuildMethodCleanUp(e:Expr):RebuildResult {
            switch(e) {
                case EVars(vars/*Array<{ name : String, t : Null<T>, val : Null<Expr> }>*/):
                    var newVars:Array<Expr> = [];
                    var hasChange:Bool = false;
                    for (vr in vars) {
                        var v:String = vr.name;
                        if (varsToIgnore.indexOf(v) != -1 && (!firstUseLine.exists(line) || firstUseLine.get(line).indexOf(v) == -1)) {
                            hasChange = true;
                            if (firstUseLine.exists(line)) {
                                firstUseLine.get(line).push(v);
                            } else {
                                firstUseLine.set(line, [v]);
                                hasVarsToInsert = true;
                            }
                            if (vr.val != null) {
                                newVars.push(EBinop("=", EIdent(v), vr.val, false));
                            }
                        } else {
                            newVars.push(EVars([vr]));
                        }
                    }
                    if (hasChange) {
                        return RebuildResult.RReplaceArray(newVars);
                    }
                case EFunction(f, name):
                    return RebuildResult.RSkip;
                default:
            }
            return null;
        }
        function rebuildMethodGetLocalFunctionVars(e:Expr):RebuildResult {
            switch (e) {
                case EFunction(f, name): return RebuildResult.RSkip;
                case EVars(vars):
                    for (vr in vars) {
                        localFunctionVars.set(vr.name, true);
                    }
                    return RebuildResult.RSkip;
                default: return null;
            }
        }
        function rebuildMethodLookForVars(e:Expr):RebuildResult {
            switch(e) {
                case EFor(inits, conds, incrs, e):
                    if (inLocalFunction) return null;
                    depth++;
                    var oldBlockVars:Array<String> = blockVars;
                    blockVars = new Array<String>();

                    var rinits:Array<Expr> = RebuildUtils.rebuildArray(inits, rebuildMethodLookForVars);
                    var rconds:Array<Expr> = RebuildUtils.rebuildArray(conds, rebuildMethodLookForVars);
                    var rincrs:Array<Expr> = RebuildUtils.rebuildArray(incrs, rebuildMethodLookForVars);
                    var re:Expr = null;
                    switch(e) {
                        case EBlock(es):
                            var res:Array<Expr> = RebuildUtils.rebuildArray(es, rebuildMethodLookForVars);
                            if (res != null) re = EBlock(res);
                        default:
                            re = RebuildUtils.rebuild(e, rebuildMethodLookForVars);
                    }
                    for (v in blockVars) {
                        restrictedVars.push(v);
                    }
                    blockVars = oldBlockVars;
                    depth--;
                    if (rinits == null && rconds == null && rincrs == null && re == null) {
                        return RebuildResult.RSkip;
                    } else {
                        if (rinits == null) rinits = inits;
                        if (rconds == null) rconds = conds;
                        if (rincrs == null) rincrs = incrs;
                        if (re == null) re = e;
                        return RebuildResult.RReplace(EFor(rinits, rconds, rincrs, re));
                    }
                case EBlock(es):
                    if (inLocalFunction) return null;
                    depth++;
                    var oldBlockVars:Array<String> = blockVars;
                    blockVars = new Array<String>();
                    var r:Array<Expr> = RebuildUtils.rebuildArray(es, rebuildMethodLookForVars);
                    for (v in blockVars) {
                        restrictedVars.push(v);
                    }
                    blockVars = oldBlockVars;
                    depth--;
                    if (r == null) {
                        return RebuildResult.RSkip;
                    } else {
                        return RebuildResult.RReplace(EBlock(r));
                    }
                case EIdent(v):
                    if (v != null) {
                        if (inLocalFunction && localFunctionVars.exists(v)) {
                            return RebuildResult.RSkip;
                        }
                        if (!localVar.exists(v)) {
                            if (!inLocalFunction && v == "arguments") {
                                var arguments:Array<Expr> = [];
                                for (arg in f.args) {
                                    arguments.push(EIdent(arg.name));
                                }
                                return RebuildResult.RReplace(ECommented("/*arguments*/", true, true, EArrayDecl(arguments)));
                            }
                            return null;
                        }
                        if (!firstUse.exists(v) || firstUse.get(v) == -1) {
                            firstUse.set(v, line);
                            if (firstUseLine.exists(line)) {
                                firstUseLine.get(line).push(v);
                            } else {
                                firstUseLine.set(line, [v]);
                                hasVarsToInsert = true;
                            }
                        } else if (restrictedVars.indexOf(v) != -1) {
                            varsToIgnore.push(v);
                            restrictedVars.remove(v);
                        }
                    }
                case EFunction(f, name):
                    if (name != null) {
                        map.set(name, "Function");
                    }
                    var oldInLocalFunction = inLocalFunction;
                    inLocalFunction = true;
                    localFunctionVars = new Map<String, Bool>();
                    RebuildUtils.rebuild(f.expr, rebuildMethodGetLocalFunctionVars);
                    var rexpr = RebuildUtils.rebuild(f.expr, rebuildMethodLookForVars);
                    inLocalFunction = oldInLocalFunction;
                    if (rexpr == null) return RebuildResult.RSkip;
                    return RebuildResult.RReplace(EFunction({args:f.args, varArgs:f.varArgs, ret:f.ret, expr:rexpr}, name));
                case EVars(vars/*Array<{ name : String, t : Null<T>, val : Null<Expr> }>*/):
                    if (inLocalFunction) {
                        return RebuildResult.RSkip;
                    }
                    var newVars:Array<Expr> = [];
                    var hasChange:Bool = false;
                    for (vr in vars) {
                        var v:String = vr.name;
                        if (!localVar.exists(v)) continue;
                        if (firstUse.exists(v) && firstUse.get(v) != -1) {
                            hasChange = true;
                            if (vr.val != null) {
                                newVars.push(EBinop("=", EIdent(v), vr.val, false));
                            }
                            if (restrictedVars.indexOf(v) != -1) {
                                varsToIgnore.push(v);
                                restrictedVars.remove(v);
                            }
                        } else {
                            if (depth > 0) {
                                blockVars.push(v);
                            }
                            newVars.push(EVars([vr]));
                        }
                        firstUse.set(v, -2);
                        localVar.set(v, true);
                        map.set(v, typer.tstring(vr.t));
                    }
                    if (hasChange) {
                        return RebuildResult.RReplaceArray(newVars);
                    }
                default:
            }
            return null;
        }
        function rebuildMethodInsertVars(e:Expr):RebuildResult {
            if (firstUseLine.exists(line)) {
                var res:Array<Expr> = null;
                for (name in firstUseLine.get(line)) {
                    if (firstUse.get(name) != -2) continue;
                    var type:String = map.get(name);
                    if (type == null || type == "Function") continue;
                    var defaultValue:Expr = null;
                    switch(type) {
                    case "int", "Int", "UInt":
                        defaultValue = EConst(CInt("0"));
                    case "Float":
                        defaultValue = EConst(CInt("Math.NaN"));
                    default:
                        defaultValue = EIdent("null");
                    }
                    if (res == null) res = [];
                    res.push(ENL(EVars([ { name:name, t:TPath([type]), val:defaultValue } ])));
                }
                if (res != null && res.length > 0) {
                    var te:Expr = e;
                    var newLines:Int = 0;
                    while (true) {
                        switch(te) {
                            case ENL(e):
                                te = e;
                                newLines++;
                            default:
                                break;
                        }
                    }
                    while (newLines-- > 1) {
                        res[0] = ENL(res[0]);
                    }
                    res.push(ENL(te));
                    return RebuildResult.RReplaceArray(res);
                }
            }
            return RebuildResult.RSkip;
        }
        function rebuildByLine(es:Array<Expr>, rebuildMethod:Expr->RebuildResult):Array<Expr> {
            var needRebuild:Bool = false;
            var rs:Array<Expr> = new Array<Expr>();
            for (i in 0...es.length) {
                line = i;
                if (RebuildUtils.rebuildToArray(es[i], rebuildMethod, rs)) {
                    needRebuild = true;
                }
            }
            if (needRebuild) {
                return rs;
            } else {
                return es;
            }
        }
        es = rebuildByLine(es, rebuildMethodLookForVars);
        if (varsToIgnore.length > 0) {
            es = rebuildByLine(es, rebuildMethodCleanUp);
        }
        if (hasVarsToInsert) {
            es = rebuildByLine(es, rebuildMethodInsertVars);
        }
        return es;
    }
}