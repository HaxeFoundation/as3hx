package as3hx;
import as3hx.As3.Definition;
import as3hx.As3.Program;
import as3hx.As3.T;
import as3hx.As3.Expr;
import as3hx.RebuildUtils.RebuildResult;

/**
 * ...
 * @author ...
 */
class SignalRebuild
{
    private var cfg:Config;
    private var typer:Typer;

    private var currentField:String = null;
    private var currentFieldType:T;

    private var succededReplace:Bool = false;

    private static var toCleanUp:Array<Program> = [];

    public function new(cfg:Config, typer:Typer) {
        this.cfg = cfg;
        this.typer = typer;
    }

    public function apply(program:Program):Void {
        var t1:Float = haxe.Timer.stamp();
        RebuildUtils.rebuildProgram(program, cfg, typer, rebuildSignals);
        var t2:Float = haxe.Timer.stamp();
        rebuildParameters(program);
        var t3:Float = haxe.Timer.stamp();
        refineVariableTypes(program);
        var t4:Float = haxe.Timer.stamp();
        var name:String = "null";
        switch(program.defs[0]) {
            case CDef(c):name = c.name;
            default:
        }
        //trace(name + " " + (t2 - t1) + " " + (t3 - t2) + " " + (t4 - t3));
    }

    public function refineVariableTypes(program:Program):Void {
        RebuildUtils.rebuildProgram(program, cfg, typer, rebuildVariableTypes);
    }

    private function isSignalType(s:String):Bool {
        return s != null && (s.indexOf("Signal<") == 0 || s.indexOf("signals.Signal<") == 0);
    }

    private function isNativeSignalType(s:String):Bool {
        return s != null && (s.indexOf("NativeSignal") == 0 || s.indexOf("signals.NativeSignal") == 0);
    }

    private function rebuildVariableTypes(expr:Expr):RebuildResult {
        switch (expr) {
            case ECall(e, params) :
                switch(e) {
                    case EField(e, field):
                        var s:String = typer.getExprType(e);
                        if (field == "add" || field == "addOnce" || field == "remove") {
                            if (isSignalType(s)) {
                                var p:Array<T> = [];
                                var types:String = s.substring(s.indexOf("<") + 1, s.length - 1);
                                if (types == "T" || types == "Type" || types == "T->Void" || types == "Type->Void") return null;
                                var split:Array<String> = types.split("->");
                                if (split.length == 1) {
                                    split.push("Void");
                                }
                                for (s in split) {
                                    p.push(typer.expandType(TPath([s])));
                                }
                                typer.overrideExprType(params[0], TFunction(p));
                            } else if (isNativeSignalType(s)) {
                                var p:Array<T> = [TPath(["Dynamic"]), TPath(["Void"])];
                                typer.overrideExprType(params[0], TFunction(p));
                            }
                        } else if (field == "dispatch") {
                            if (isSignalType(s)) {
                                var p:Array<T> = [];
                                var types:String = s.substring(s.indexOf("<") + 1, s.length - 1);
                                if (types == "T" || types == "Type" || types == "T->Void" || types == "Type->Void") return null;
                                if (types == "Void") types = "Void->Void";
                                for (s in types.split("->")) {
                                    //p.push(TPath([s]));
                                    p.push(typer.expandType(TPath([s])));
                                }
                                var rparams:Array<Expr> = [];
                                for (i in 0...params.length) {
                                    rparams.push(ETypedExpr(params[i], p[i]));
                                }
                                return RebuildResult.RReplace(ECall(EField(e, field), rparams));
                            }
                        }
                    default:
                }
            default:
        }
        return null;
    }

    private function tryOverrideType(name:String, t:T):Void {
        typer.overrideIdentType(name, typer.expandType(t));
    }

    public static function cleanup(cfg:Config, typer:Typer):Void {
        var s:SignalRebuild = new SignalRebuild(cfg, typer);
        for (i in 0...5) {
            var prevToCleanUp:Array<Program> = toCleanUp.copy();
            toCleanUp = [];
            var list:Array<String> = [];
            for (p in prevToCleanUp) {
                s.apply(p);
                if (p.defs.length > 0) {
                    switch(p.defs[0]) {
                        case CDef(c):
                            list.push(p.pack + "." + c.name);
                        default:
                    }
                }
            }
            neko.Lib.println("SignalRebuild cleanUp " + prevToCleanUp.length + " left: " + list);
            if (toCleanUp.length == 0) {
                neko.Lib.println("SignalRebuild cleanUp complete");
                break;
            }
        }
    }

    private function rebuildParameters(program:Program):Void {
        for (d in program.defs) {
            switch (d) {
                case CDef(c):
                    var path:String = (program.pack.length > 0 ? program.pack.join(".") + "." : "") + c.name;
                    typer.enterClass(path, c);
                    for (field in c.fields) {
                        currentField = field.name;
                        switch(field.kind) {
                            case FVar(t, val):
                            case FFun(f):
                                typer.enterFunction(f, field.name, c);
                                currentFieldType = f.ret.t;
                                switch (currentFieldType) {
                                    case null:
                                    case TPath(pathArray):
                                        var p:String = pathArray.join(".");
                                        if (p == "Signal" || p == "org.osflash.signals.Signal" || p == "idv.cjcat.signals.Signal" || p == "signals.Signal") {
                                            succededReplace = false;
                                            var expr:Expr = RebuildUtils.rebuild(f.expr, rebuildParams);
                                            if (!succededReplace) {
                                                if (toCleanUp.indexOf(program) == -1) {
                                                    toCleanUp.push(program);
                                                }
                                            }
                                        }
                                        if (p == "ISignal" || p == "org.osflash.signals.ISignal" || p == "idv.cjcat.signals.ISignal" || p == "signals.ISignal") {
                                            succededReplace = false;
                                            var expr:Expr = RebuildUtils.rebuild(f.expr, rebuildParamsInterface);
                                            if (!succededReplace) {
                                                if (toCleanUp.indexOf(program) == -1) {
                                                    toCleanUp.push(program);
                                                }
                                            }
                                        }
                                    default:
                                }
                                typer.leaveFunction();
                            default:
                        }
                    }
                case FDef(f):
                    //var expr:Expr = RebuildUtils.rebuild(f.f.expr, rebuildParams);
                    //if (expr != null) {
                        //f.f.expr = expr;
                    //}
                default:
            }
        }
    }

    private function rebuildParams(expr:Expr):RebuildResult {
        switch(expr) {
            case EReturn(e):
                if (e != null) {
                    var t:String = typer.getExprType(e);
                    if (t != null && t != "null" && t != "Signal") {
                        succededReplace = true;
                        tryOverrideType(currentField, TPath([t]));
                    }
                }
            default:
        }
        return null;
    }

    private function rebuildParamsInterface(expr:Expr):RebuildResult {
        switch(expr) {
            case EReturn(e):
                if (e != null) {
                    var t:String = typer.getExprType(e);
                    if (t != null && t != "null" && t != "Signal") {
                        succededReplace = true;
                        t = StringTools.replace(t, "<Void>", "<Void->Void>");
                        tryOverrideType(currentField, TPath([StringTools.replace(t, "Signal", "ISignal")]));
                    }
                }
            default:
        }
        return null;
    }

    private function rebuildSignals(expr:Expr):RebuildResult {
        switch(expr) {
            case EBinop("=", e1, e2, newLineAfterOp):
                var types = getNewSignalType(typer.getExprType(e1), typer.getExprType(e2));
                if (types != null) {
                    var t:T = TPath([types]);
                    switch(e1) {
                        case EIdent(v):
                            var variableType:T = typer.expandType(t);
                            if (typer.getExprType(e1) == "ISignal") {
                                types = StringTools.replace(types, "<Void>", "<Void->Void>");
                                variableType = TPath([StringTools.replace(typer.expandStringType(types), "Signal", "ISignal")]);
                            }
                            tryOverrideType(v, variableType);
                        default:
                    }
                    return RebuildResult.RReplace(EBinop("=", e1, ENew(TPath([typer.shortenStringType(types)]), []), newLineAfterOp));
                }
            case EVars(vars):
                for (v in vars) {
                    if (v.val == null) continue;

                    var ts:String = typer.tstring(v.t);
                    var types = getNewSignalType(ts, typer.getExprType(v.val));
                    if (types != null) {
                        var a:Array<String> = [types];
                        //var a:Array<String> = ["Signal<" + types + ">"];
                        var t:T = TPath(a);
                        if (ts == "ISignal") {
                            a[0] = StringTools.replace(a[0], "<Void>", "<Void->Void>");
                            a[0] = "I" + a[0];
                        }
                        tryOverrideType(v.name, t);
                        v.t = truncateFullPath(types);
                    }
                }
            default:
        }
        return null;
    }

    private function truncateFullPath(complexType:String):T {
        var delimiters:Array<String> = [];
        var types:Array<Array<String>> = Typer.getTypeParams(complexType, delimiters);
        var shortTypes:Array<String> = [];
        for (p in types) {
            shortTypes.push(p[p.length - 1]);
        }
        var s:String = shortTypes[0] + "<" + shortTypes[1];
        for (i in 2...shortTypes.length) {
            s += "->" + shortTypes[i];
        }
        return TPath([s + ">"]);
    }

    private function getNewSignalType(oldType:String, newType:String):String {
        if (newType != null && newType.indexOf("Signal<") == 0 && typer.shortenStringType(oldType) != newType) {
            return newType;
        } else {
            return null;
        }
    }
}