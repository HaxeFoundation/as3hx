package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.Parser;

class StructureParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config, kwd:String) : Expr {
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);
        var parseExprList = ExprParser.parseList.bind(tokenizer, types, cfg);
        var parseType = TypeParser.parse.bind(tokenizer, types, cfg);
        var parseFunction = FunctionParser.parse.bind(tokenizer, types, cfg);
        var parseCaseBlock = CaseBlockParser.parse.bind(tokenizer, types, cfg);

        Debug.dbgln("parseStructure(" + kwd + ")", tokenizer.line);
        return switch(kwd) {
        case "if":
            var f:Expr->Expr = null;
            f = function(ex) {
                return switch(ex) {
                    case ENL(e): f(e);
                    case EBlock(_): ex;
                    default: EBlock([ex]);
                }
            }
            tokenizer.ensure(TPOpen);
            var cond = parseExpr(false);
            tokenizer.ensure(TPClose);
            var e1 = parseExpr(false);
            e1 = f(e1);
            tokenizer.end();
            var elseExpr = if(ParserUtils.opt(tokenizer, TId("else"), true)) parseExpr(false) else null;
            if(elseExpr != null) elseExpr = f(elseExpr);
            switch(cond) {
                case ECondComp(v, e, e2):
                    //corner case, the condition is an AS3 preprocessor 
                    //directive, it must contain the block to wrap it 
                    //in Haxe #if #end preprocessor directive
                    ECondComp(v, e1, elseExpr);
                default:
                    //regular if statement,,check for an "else" block
                    EIf(cond, e1, elseExpr);
            }
        case "var", "const":
            var vars = [];
            while( true ) {
                var name = tokenizer.id(), t = null, val = null;
                name = ParserUtils.escapeName(name);
                if( ParserUtils.opt(tokenizer, TColon) )
                    t = parseType();
                if( ParserUtils.opt(tokenizer, TOp("=")) )
                    val = ETypedExpr(parseExpr(false), t);
                vars.push( { name : name, t : t, val : val } );
                if( !ParserUtils.opt(tokenizer, TComma) )
                    break;
            }
            EVars(vars);
        case "while":
            tokenizer.ensure(TPOpen);
            var econd = parseExpr(false);
            tokenizer.ensure(TPClose);
            var e = parseExpr(false);
            EWhile(econd,e, false);
        case "for":
            if( ParserUtils.opt(tokenizer, TId("each")) ) {
                tokenizer.ensure(TPOpen);
                var ev = parseExpr(false);
                switch(ev) {
                    case EBinop(op, e1, e2, n):
                        if(op == "in") {
                            tokenizer.ensure(TPClose);
                            return EForEach(e1, e2, parseExpr(false));
                        }
                        ParserUtils.unexpected(TId(op));
                    default:
                        ParserUtils.unexpected(TId(Std.string(ev)));
                }
            } else {
                tokenizer.ensure(TPOpen);
                var inits = [];
                if( !ParserUtils.opt(tokenizer, TSemicolon) ) {
                    var e = parseExpr(false);
                    switch(e) {
                        case EBinop(op, e1, e2, n):
                            if(op == "in") {
                                tokenizer.ensure(TPClose);
                                return EForIn(e1, e2, parseExpr(false));
                            }
                        default:
                    }
                    if( ParserUtils.opt(tokenizer, TComma) ) {
                        inits = parseExprList(TSemicolon);
                        inits.unshift(e);
                    } else {
                        tokenizer.ensure(TSemicolon);
                        inits = [e];
                    }
                }
                var conds = parseExprList(TSemicolon);
                var incrs = parseExprList(TPClose);
                EFor(inits, conds, incrs, parseExpr(false));
            }
        case "break":
            var label = switch( tokenizer.peek() ) {
            case TId(n): tokenizer.token(); n;
            default: null;
            };
            EBreak(label);
        case "continue": EContinue;
        case "else": ParserUtils.unexpected(TId(kwd));
        case "function":
            var name = switch(tokenizer.peek()) {
                case TId(n):
                    tokenizer.token();
                    n;
                default: null;
            };
            EFunction(parseFunction(false), name);
        case "return":
            var t = tokenizer.peek();
            var e = switch(t) {
                case TSemicolon | TBrClose: null;
                case _: parseExpr(false);
            }
            EReturn(e);
        case "new":
            if(ParserUtils.opt(tokenizer, TOp("<"))) {
                // o = new <VectorType>[a,b,c..]
                var t = parseType();
                tokenizer.ensure(TOp(">"));
                if(tokenizer.peek() != TBkOpen)
                    ParserUtils.unexpected(tokenizer.peek());
                ECall(EVector(t), [parseExpr(false)]);
            } else {
                var t = parseType();
                // o = new (iconOrLabel as Class)() as DisplayObject
                var cc = switch(t) {
                    case TComplex(e1) :
                        switch (e1) {
                            case EBinop(op, e2, e3, n): 
                                if (op == "as") {
                                    switch (e2) {
                                        case ECall(e4, a): 
                                            EBinop(op, ECall(EField(EIdent("Type"), "createInstance"), [e4, EArrayDecl(a)]), e3, n);
                                        default:  null;
                                    }
                                }
                                return null;
                            default: null;
                        }
                    default: null;
                }
                if (cc != null) cc; else ENew(t,if( ParserUtils.opt(tokenizer, TPOpen) ) parseExprList(TPClose) else []);
            }
        case "throw":
            EThrow( parseExpr(false) );
        case "try":
            var e = parseExpr(false);
            var catches = new Array();
            while( ParserUtils.opt(tokenizer, TId("catch")) ) {
                tokenizer.ensure(TPOpen);
                var name = tokenizer.id();
                tokenizer.ensure(TColon);
                var t = parseType();
                tokenizer.ensure(TPClose);
                var e = parseExpr(false);
                catches.push( { name : name, t : t, e : e } );
            }
            ETry(e, catches);
        case "switch":
            tokenizer.ensure(TPOpen);
            var e = EParent(parseExpr(false));
            tokenizer.ensure(TPClose);

            var def:SwitchDefault = null, cl = [], meta = [];
            tokenizer.ensure(TBrOpen);

            //parse all "case" and "default"
            while(true) {
                var tk = tokenizer.token();
                switch (tk) {
                    case TBrClose: //end of switch
                        break;
                    case TId(s):
                        if (s == "default") {
                            tokenizer.ensure(TColon);
                            def = { el : parseCaseBlock(), meta : meta, before: null };
                            meta = [];
                        }
                        else if (s == "case"){
                            var val = parseExpr(false);
                            tokenizer.ensure(TColon);
                            var el = parseCaseBlock();

                            // default already set, and is empty
                            // we assign this case to default
                            if(def != null && def.el.length == 0) {
                                def.el = el;
                                def.meta = def.meta.concat(meta);
                                if(def.vals == null) def.vals = [];
                                def.vals.push(val);
                            }
                            // default already set, and has same
                            // content as this case
                            else if(def != null && def.el == el){
                                def.meta = def.meta.concat(meta);
                                def.el = el;
                                if(def.vals == null) def.vals = [];
                                def.vals.push(val);
                            }
                            // normal case, default not set yet, or differs
                            else {
                                var caseObj = { val : val, el : el, meta : meta }
                                // default already set, but case follows it
                                // mark that default is before this case
                                if(def != null && def.before == null) {
                                    def.before = caseObj;
                                }
                                cl.push(caseObj);
                            }
                            
                            //reset for next case or default
                            meta = [];
                        }
                        else {
                            ParserUtils.unexpected(tk);
                        }
                    case TNL(t): //keep newline as meta for a case/default
                        tokenizer.add(t);
                        meta.push(ENL(null));
                    case TCommented(s,b,t): //keep comment as meta for a case/default
                        tokenizer.add(t);
                        meta.push(ECommented(s,b,false,null));

                    default:
                        ParserUtils.unexpected(tk);
                }
            }
            
            ESwitch(e, cl, def);
        case "do":
            var e = parseExpr(false);
            tokenizer.ensure(TId("while"));
            var cond = parseExpr(false);
            EWhile(cond, e, true);
        case "typeof":
            var e = parseExpr(false);
            switch(e) {
                case EBinop(_, _, _, _):
                    //if(op != "==" && op != "!=")
                    //  ParserUtils.unexpected(TOp(op));
                case EParent(_):
                case EIdent(_):
                case EConst(_):
                default: ParserUtils.unexpected(TId(Std.string(e)));
            }
            ETypeof(e);
        case "delete":
            var e = parseExpr(false);
            tokenizer.end();
            EDelete(e);
        case "getQualifiedClassName":
            tokenizer.ensure(TPOpen);
            var e = parseExpr(false);
            e = switch(e) {
                case EIdent(v) if(v == "this"): ECall(EField(EIdent("Type"), "getClass"), [e]);
                default: e;
            }
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("Type"), "getClassName"), [e]);
        case "getQualifiedSuperclassName":
            tokenizer.ensure(TPOpen);
            var e = parseExpr(false);
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getSuperClass"), [e])]);
        case "getDefinitionByName":
            tokenizer.ensure(TPOpen);
            var e = parseExpr(false);
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("Type"), "resolveClass"), [e]);
        case "getTimer":
            //consume the parenthesis from the getTimer AS3 call
            while(!ParserUtils.opt(tokenizer, TPClose)) {
                tokenizer.token();
            }
            ECall(EField(EIdent("Math"), "round"), [EBinop("*", ECall(EField(EIdent("haxe.Timer"), "stamp"), []), EConst(CInt("1000")), false)]);
        case "setTimeout" | "setInterval":
            var params = getParams(tokenizer, parseExpr);
            if(params != null) return ECall(EField(EIdent("as3hx.Compat"), kwd), params);
            return null;
        case "clearTimeout" | "clearInterval":
            tokenizer.ensure(TPOpen);
            var e = parseExpr(false);
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("as3hx.Compat"), kwd), [e]);
        case "parseInt" | "parseFloat" if(cfg.useCompat):
            var params = getParams(tokenizer, parseExpr);
            if(params != null) return ECall(EField(EIdent("as3hx.Compat"), kwd), params);
            null;
        case "parseInt" | "parseFloat":
            tokenizer.ensure(TPOpen);
            var e = parseExpr(false);
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("Std"), kwd), [e]);
        case "navigateToURL":
            var params = getParams(tokenizer, parseExpr);
            if(params != null) return ECall(EField(EIdent("flash.Lib"), "getURL"), params);
            return null;
        default: null;
        }
    }
    
    static function getParams(tokenizer:Tokenizer, parseExpr) {
        return switch(tokenizer.token()) {
            case TPOpen:
                var params = [];
                var parCount = 1;
                while(parCount > 0) {
                    var t = tokenizer.token();
                    switch(t) {
                        case TPOpen: parCount++;
                        case TPClose:
                            parCount--;
                            if(params.length > 0) params[params.length - 1] = EParent(params[params.length - 1]);
                        case TComma:
                        case TOp(op) if(params.length > 0):
                            params[params.length - 1] = ParserUtils.makeBinop(tokenizer, op, params[params.length - 1], parseExpr(false));
                        case _:
                            tokenizer.add(t);
                            if(params.length < 2) params.push(parseExpr(false));
                            else {
                                if(params.length == 2) params.push(EArrayDecl([]));
                                switch(params[2]) {
                                    case EArrayDecl(e): e.push(parseExpr(false));
                                    case _:
                                }
                            }
                    }
                }
                params;
            case _: null;
        }
    }
}
