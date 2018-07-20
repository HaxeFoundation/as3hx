package as3hx;
import as3hx.As3.Expr;
import as3hx.As3.Function;
import as3hx.As3.Program;
import as3hx.As3.SwitchCase;
import as3hx.As3.SwitchDefault;
import as3hx.As3.T;

enum RebuildResult {
    RReplace( expr : Expr ); // replace current expression with provided expr
    RSkip; // do not iterate through child expressions of current expr
    RNull; // no actions needed for this expr, continue recursion
    RReplaceArray( es : Array<Expr> ); // replace current expression with group of expressions. This operation could be applied only to expression in an array
    REmpty; // remove current expression. This operation could be applied only to expression in an array
}

/*
 * RebuildUtils methods can iterate all through provided Expr and it's parameters and somehow process all Exprs by provideed method
 */
class RebuildUtils
{
    public static function rebuildProgram(program:Program, cfg:Config, typer:Typer, rebuild:Expr->RebuildResult):Void {
        for (d in program.defs) {
            switch (d) {
                case CDef(c):
                    var path:String = typer.getPackageString(program.pack) + c.name;
                    typer.setPackage(typer.getImportString(program.pack, false));
                    typer.setImports(WriterImports.getImports(program, cfg, c), null);
                    typer.enterClass(path, c);
                    for (field in c.fields) {
                        switch(field.kind) {
                            case FFun(f):
                                typer.enterFunction(f, field.name, c);
                                var expr:Expr = RebuildUtils.rebuild(f.expr, rebuild);
                                if (expr != null) {
                                    f.expr = expr;
                                }
                                rebuildArgs(f, rebuild);
                                typer.leaveFunction();
                            case FVar(t, val):
                                var expr:Expr = RebuildUtils.rebuild(EBinop("=", EIdent(field.name), val, false), rebuild);
                                if (expr != null) {
                                    // type could be changed while rebuilding
                                    t = field.kind.getParameters()[0];
                                    switch(expr) {
                                        case EBinop(_, _, val, _):
                                            field.kind = FVar(t, val);
                                            typer.overrideFieldType(path, field.name, typer.expandType(t));
                                        default:
                                    }
                                }
                            default:
                        }
                    }
                case FDef(f):
                    var expr:Expr = RebuildUtils.rebuild(f.f.expr, rebuild);
                    if (expr != null) {
                        f.f.expr = expr;
                    }
                    rebuildArgs(f.f, rebuild);
                default:
            }
        }
    }

    public static function rebuildArray(es:Array<Expr>, rebuildMethod:Expr->RebuildResult):Array<Expr> {
        var needRebuild:Bool = false;
        var rs:Array<Expr> = new Array<Expr>();
        for (i in 0...es.length) {
            if (rebuildToArray(es[i], rebuildMethod, rs)) {
                needRebuild = true;
            }
        }
        if (needRebuild) {
            return rs;
        } else {
            return null;
        }
    }

    public static function rebuild(e:Expr, rebuildMethod:Expr->RebuildResult):Expr {
        if (e == null) return null;
        var r:RebuildResult = rebuildMethod(e);
        switch(r) {
            case RReplace(expr): return expr;
            case RSkip: return null;
            case null, RNull:
            default:
        }
        switch(e) {
            case ECommented(s, isBlock, isTail, e1):
                var re = rebuild(e1, rebuildMethod);
                if (re == null) {
                    return e;
                } else {
                    return ECommented(s, isBlock, isTail, re);
                }
            case ENL(e1):
                var re = rebuild(e1, rebuildMethod);
                if (re == null) {
                    return e;
                } else {
                    return ENL(re);
                }
            default:
                return rebuildExprParams(e, rebuildMethod);
        }
    }

    public static function rebuildToArray(e:Expr, rebuildMethod:Expr->RebuildResult, output:Array<Expr>):Bool {
        var r:RebuildResult = rebuildMethod(e);
        switch(r) {
            case RReplace(expr):
                output.push(expr);
                return true;
            case RReplaceArray(es):
                for (expr in es) {
                    output.push(expr);
                }
                return true;
            case REmpty:
                return true;
            case null, RNull:
                switch(e) {
                    case ECommented(s, isBlock, isTail, e1):
                        if (e1 != null) {
                            var l:Int = output.length;
                            var needRebuild = rebuildToArray(e1, rebuildMethod, output);
                            var i:Int = output.length;
                            while (i-- > l + 1) {
                                output[i] = output[i];
                            }
                            output[i] = ECommented(s, isBlock, isTail, output[i]);
                            return needRebuild;
                        }
                    case ENL(e1) :
                        if (e1 != null) {
                            var l:Int = output.length;
                            var needRebuild = rebuildToArray(e1, rebuildMethod, output);
                            var i:Int = output.length;
                            while (i-- > l) {
                                output[i] = ENL(output[i]);
                            }
                            return needRebuild;
                        }
                    default:
                        var expr:Expr = rebuildExprParams(e, rebuildMethod);
                        if (expr != null) {
                            output.push(expr);
                            return true;
                        }
                }
            case RSkip:
            default:
        }
        output.push(e);
        return false;
    }

    private static function rebuildExprParams(e:Expr, rebuildMethod:Expr->RebuildResult):Expr {
        switch(e) {
            case EFunction(f, name):
                var rexpr = rebuild(f.expr, rebuildMethod);
                if (rexpr == null) return null;
                rebuildArgs(f, rebuildMethod);
                return EFunction({args:f.args, varArgs:f.varArgs, ret:f.ret, expr:rexpr}, name);
            case EBlock(es):
                var r:Array<Expr> = rebuildArray(es, rebuildMethod);
                if (r == null) {
                    return null;
                } else {
                    return EBlock(r);
                }
            case EArrayDecl(es):
                var r:Array<Expr> = rebuildArray(es, rebuildMethod);
                if (r == null) {
                    return null;
                } else {
                    return EArrayDecl(r);
                }
            case EForIn(e1, e2, e3):
                var re1:Expr = rebuild(e1, rebuildMethod);
                var re2:Expr = rebuild(e2, rebuildMethod);
                var re3:Expr = rebuild(e3, rebuildMethod);
                if (re1 != null || re2 != null || re3 != null) {
                    if (re1 == null) re1 = e1;
                    if (re2 == null) re2 = e2;
                    if (re3 == null) re3 = e3;
                    return EForIn(re1, re2, re3);
                } else {
                    return null;
                }
            case EForEach(e1, e2, e3):
                var re1:Expr = rebuild(e1, rebuildMethod);
                var re2:Expr = rebuild(e2, rebuildMethod);
                var re3:Expr = rebuild(e3, rebuildMethod);
                if (re1 != null || re2 != null || re3 != null) {
                    if (re1 == null) re1 = e1;
                    if (re2 == null) re2 = e2;
                    if (re3 == null) re3 = e3;
                    return EForEach(re1, re2, re3);
                } else {
                    return null;
                }
            case EWhile(e1, e2, e3):
                var re1:Expr = rebuild(e1, rebuildMethod);
                var re2:Expr = rebuild(e2, rebuildMethod);
                if (re1 != null || re2 != null) {
                    if (re1 == null) re1 = e1;
                    if (re2 == null) re2 = e2;
                    return EWhile(re1, re2, e3);
                } else {
                    return null;
                }
            case EIf(e1, e2, e3):
                var re1:Expr = rebuild(e1, rebuildMethod);
                var re2:Expr = rebuild(e2, rebuildMethod);
                var re3:Expr = rebuild(e3, rebuildMethod);
                if (re1 != null || re2 != null || re3 != null) {
                    if (re1 == null) re1 = e1;
                    if (re2 == null) re2 = e2;
                    if (re3 == null) re3 = e3;
                    return EIf(re1, re2, re3);
                } else {
                    return null;
                }
            case EFor(e1, e2, e3, e4):
                var re1:Array<Expr> = rebuildArray(e1, rebuildMethod);
                var re2:Array<Expr> = rebuildArray(e2, rebuildMethod);
                var re3:Array<Expr> = rebuildArray(e3, rebuildMethod);
                var re4:Expr = rebuild(e4, rebuildMethod);
                if (re1 != null || re2 != null || re3 != null || re4 != null) {
                    if (re1 == null) re1 = e1;
                    if (re2 == null) re2 = e2;
                    if (re3 == null) re3 = e3;
                    if (re4 == null) re4 = e4;
                    return EFor(re1, re2, re3, re4);
                } else {
                    return null;
                }
            case ETry(e, catches): //ETry( e : Expr, catches : Array<{ name : String, t : Null<T>, e : Expr }> )
                var re:Expr = rebuild(e, rebuildMethod);
                var needRebuild = false;
                var rcatches:Array<{ name : String, t : Null<T>, e : Expr }> = [];
                for (c in catches) {
                    var rce:Expr = rebuild(c.e, rebuildMethod);
                    if (rce != null) {
                        needRebuild = true;
                        rcatches.push({
                           name:c.name,
                           t:c.t,
                           e:rce
                        });
                    } else {
                        rcatches.push(c);
                    }
                }
                if (re != null || needRebuild) {
                    if (re == null) re = e;
                    return ETry(re, rcatches);
                } else {
                    return null;
                }
            case ESwitch(e, cases, def)://ESwitch( e : Expr, cases : Array<SwitchCase>, def : Null<SwitchDefault>)
                var re:Expr = rebuild(e, rebuildMethod);
                var needRebuild = false;
                var rcases:Array<SwitchCase> = [];
                for (c in cases) {
                    var rc = rebuildSwitchCase(c, rebuildMethod);
                    if (rc == null) {
                        rcases.push(c);
                    } else {
                        rcases.push(rc);
                        needRebuild = true;
                    }
                }
                var rdef:SwitchDefault = null;
                if (def != null) {
                    rdef = rebuildSwitchDefault(def, rebuildMethod);
                }
                if (re != null || rdef != null || needRebuild) {
                    if (re == null) re = e;
                    if (rdef == null) rdef = def;
                    return ESwitch(re, rcases, rdef);
                } else {
                    return null;
                }
            case ENew(t, params):
                var rparams:Array<Expr> = rebuildArray(params, rebuildMethod);
                if (rparams != null) {
                    if (rparams == null) rparams = params;
                    return ENew(t, rparams);
                } else {
                    return null;
                }
            case ENamespaceAccess(e, f):
                var re:Expr = rebuild(e, rebuildMethod);
                if (re == null) return null;
                return ENamespaceAccess(re, f);
            case EArray(e, index):
                var re:Expr = rebuild(e, rebuildMethod);
                var rindex:Expr = rebuild(index, rebuildMethod);
                if (re == null && index == null) return null;
                if (re == null) re = e;
                if (rindex == null) rindex = index;
                return EArray(re, rindex);
            case EField(e, f):
                var re:Expr = rebuild(e, rebuildMethod);
                if (re == null) return null;
                return EField(re, f);
            case ECall(e, params):
                var re:Expr = rebuild(e, rebuildMethod);
                var rparams:Array<Expr> = rebuildArray(params, rebuildMethod);
                if (re != null || rparams != null) {
                    if (re == null) re = e;
                    if (rparams == null) rparams = params;
                    return ECall(re, rparams);
                } else {
                    return null;
                }
            case EUnop(op, prefix, e):
                var re:Expr = rebuild(e, rebuildMethod);
                if (re == null) return null;
                return EUnop(op, prefix, re);
            case EReturn(e):
                var re:Expr = rebuild(e, rebuildMethod);
                if (re == null) return null;
                return EReturn(re);
            case EParent(e):
                var re:Expr = rebuild(e, rebuildMethod);
                if (re == null) return null;
                return EParent(re);
            case ETernary(cond, e1, e2):
                var rcond:Expr = rebuild(cond, rebuildMethod);
                var re1:Expr = rebuild(e1, rebuildMethod);
                var re2:Expr = rebuild(e2, rebuildMethod);
                if (rcond != null || re1 != null || re2 != null) {
                    if (rcond == null) rcond = cond;
                    if (re1 == null) re1 = e1;
                    if (re2 == null) re2 = e2;
                    return ETernary(rcond, re1, re2);
                } else {
                    return null;
                }
            case EBinop(op, e1, e2, newLineAfterOp):
                var re1:Expr = rebuild(e1, rebuildMethod);
                var re2:Expr = rebuild(e2, rebuildMethod);
                if (re1 != null || re2 != null) {
                    if (re1 == null) re1 = e1;
                    if (re2 == null) re2 = e2;
                    return EBinop(op, re1, re2, newLineAfterOp);
                } else {
                    return null;
                }
            case ETypedExpr(e, t):
                var re:Expr = rebuild(e, rebuildMethod);
                if (re == null) return null;
                return ETypedExpr(re, t);
            case EVars(vars):
                if (vars.length == 1) {
                    var v = vars[0];
                    if (v.val != null) {
                        var rval:Expr = rebuild(v.val, rebuildMethod);
                        if (rval == null) return null;
                        return EVars([{name:v.name, t:v.t, val:rval}]);
                    }
                }
            case EObject(fields):
                var needRebuild:Bool = false;
                var resultFields:Array<{ name : String, e : Expr }> = [];
                for (i in 0...fields.length) {
                    var re:Expr = rebuild(fields[i].e, rebuildMethod);
                    if (re != null) {
                        resultFields.push({name:fields[i].name, e:re});
                        needRebuild = true;
                    } else {
                        resultFields.push(fields[i]);
                    }
                }
                if (needRebuild) {
                    return EObject(resultFields);
                }
            case ECommented(a, b, c, e):
                e = rebuild(e, rebuildMethod);
                if (e == null) return null;
                return ECommented(a, b, c, e);
            default:
        }
        return null;
    }

    private static function rebuildSwitchDefault(def:SwitchDefault, rebuildMethod:Expr->RebuildResult):SwitchDefault {
        var el:Array<Expr> = rebuildArray(def.el, rebuildMethod);
        var meta:Array<Expr> = rebuildArray(def.meta, rebuildMethod);
        var vals:Array<Expr> = null;
        var before:SwitchCase = null;
        if (Reflect.hasField(def, "vals") && def.vals != null) {
            vals = rebuildArray(def.vals, rebuildMethod);
        }
        if (Reflect.hasField(def, "before") && def.before != null) {
            before = rebuildSwitchCase(def.before, rebuildMethod);
        }
        if (el != null || meta != null || before != null || vals != null) {
            if (el == null) el = def.el;
            if (meta == null) meta = def.meta;
            var rdef:SwitchDefault = {
                el:el,
                meta:meta
            }
            if (vals != null) {
                rdef.vals = vals;
            } else if (def.vals != null) {
                rdef.vals = def.vals;
            }
            if (before != null) {
                rdef.before = before;
            } else if (def.before != null) {
                rdef.before = def.before;
            }
            return rdef;
        } else {
            return null;
        }
    }

    private static function rebuildSwitchCase(c:SwitchCase, rebuildMethod:Expr->RebuildResult):SwitchCase {
        var rval:Expr = rebuild(c.val, rebuildMethod);
        var rel:Array<Expr> = rebuildArray(c.el, rebuildMethod);
        var rmeta:Array<Expr> = rebuildArray(c.meta, rebuildMethod);
        if (rval != null || rel != null || rmeta != null) {
            if (rval == null) rval = c.val;
            if (rel == null) rel = c.el;
            if (rmeta == null) rmeta = c.meta;
            return {
                val: rval,
                el: rel,
                meta: rmeta
            }
        } else {
            return null;
        }
    }

    private static function rebuildArgs(f:Function, rebuildMethod:Expr->RebuildResult):Void {
        //Array<{ name : String, t : Null<T>, val : Null<Expr>, exprs:Array<Expr> }>
        for (v in f.args) {
            switch(v.val) {
                case null:
                case EConst(_):
                case EIdent("null"):
                default:
                    var rv:Expr = rebuild(v.val, rebuildMethod);
                    if (rv != null) {
                        v.val = rv;
                    }
            }
        }
    }
}