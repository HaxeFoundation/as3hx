package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;

class StructureParser {

    public static function parse(tokenizer:Tokenizer, typesSeen:Array<Dynamic>, cfg:Config, kwd) : Expr {
        var parseExpr = ExprParser.parse.bind(tokenizer, typesSeen, cfg);
        var parseExprList = ExprParser.parseList.bind(tokenizer, typesSeen, cfg);
        var parseType = TypeParser.parse.bind(tokenizer, typesSeen, cfg);
        var parseFunction = FunctionParser.parse.bind(tokenizer, typesSeen, cfg);
        var parseCaseBlock = CaseBlockParser.parse.bind(tokenizer, typesSeen, cfg);

        Debug.dbgln("parseStructure("+kwd+")", tokenizer.line);
        return switch( kwd ) {
        case "if":
            tokenizer.ensure(TPOpen);
            var cond = parseExpr(false);
            tokenizer.ensure(TPClose);
            var e1 = parseExpr(false);
            tokenizer.end();
            var elseExpr = if( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("else"), true) ) parseExpr(false) else null;
            switch (cond) {
                case ECondComp(v, e, e2):
                    //corner case, the condition is an AS3 preprocessor 
                    //directive, it must contain the block to wrap it 
                    //in Haxe #if #end preprocessor directive
                    ECondComp(v, e1, elseExpr);
                default:
                    //regular if statement,,check for an "else" block
                    
                    EIf(cond,e1,elseExpr);
            }

        case "var", "const":
            var vars = [];
            while( true ) {
                var name = tokenizer.id(), t = null, val = null;
                if( ParserUtils.opt(tokenizer.token, tokenizer.add, TColon) )
                    t = parseType();
                if( ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("=")) )
                    val = ETypedExpr(parseExpr(false), t);
                vars.push( { name : name, t : t, val : val } );
                if( !ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) )
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
            if( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("each")) ) {
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
                if( !ParserUtils.opt(tokenizer.token, tokenizer.add, TSemicolon) ) {
                    var e = parseExpr(false);
                    switch(e) {
                        case EBinop(op, e1, e2, n):
                            if(op == "in") {
                                tokenizer.ensure(TPClose);
                                return EForIn(e1, e2, parseExpr(false));
                            }
                        default:
                    }
                    if( ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) ) {
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
            var name = switch( tokenizer.peek() ) {
            case TId(n): tokenizer.token(); n;
            default: null;
            };
            EFunction(parseFunction(),name);
        case "return":
            EReturn(if( tokenizer.peek() == TSemicolon ) null else parseExpr(false));
        case "new":
            if(ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("<"))) {
                // o = new <VectorType>[a,b,c..]
                var t = parseType();
                tokenizer.ensure(TOp(">"));
                if(tokenizer.peek() != TBkOpen)
                    ParserUtils.unexpected(tokenizer.peek());
                ECall(EVector(t), [parseExpr(false)]);
            } else {
                var t = parseType();
                // o = new (iconOrLabel as Class)() as DisplayObject
                var cc = switch (t) {
                                    case TComplex(e1) : 
                                    switch (e1) {
                                        case EBinop(op, e2, e3, n): 
                                        if (op == "as") {
                                            switch (e2) {
                                                case ECall(e4, a): 
                                                EBinop(op, ECall(EField(EIdent("Type"), "createInstance"), [e4, EArrayDecl(a)]), e3, n);
                                                default: 
                                                null;
                                            }
                                        }
                                        return null;
                                        default: 
                                        null;
                                    }
                                    default: 
                                    null;
                }
                if (cc != null) cc; else ENew(t,if( ParserUtils.opt(tokenizer.token, tokenizer.add, TPOpen) ) parseExprList(TPClose) else []);
            }
        case "throw":
            EThrow( parseExpr(false) );
        case "try":
            var e = parseExpr(false);
            var catches = new Array();
            while( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("catch")) ) {
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

            var def = null, cl = [], meta = [];
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
                            def = { el : parseCaseBlock(), meta : meta };
                            meta = [];
                        }
                        else if (s == "case"){
                            var val = parseExpr(false);
                            tokenizer.ensure(TColon);
                            var el = parseCaseBlock();
                            cl.push( { val : val, el : el, meta : meta } );
                            
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
            case EBinop(op, e1, e2, n):
                //if(op != "==" && op != "!=")
                //  ParserUtils.unexpected(TOp(op));
            case EParent(e1):
            case EIdent(id):
                null;
            default:
                ParserUtils.unexpected(TId(Std.string(e)));
            }
            ETypeof(e);
        case "delete":
            var e = parseExpr(false);
            tokenizer.end();
            EDelete(e);
        case "getQualifiedClassName":
            tokenizer.ensure(TPOpen);
            var e = parseExpr(false);
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
            while(!ParserUtils.opt(tokenizer.token, tokenizer.add, TPClose)) {
                tokenizer.token();
            }
            
            ECall(EField(EIdent("Math"), "round"), [EBinop("*", ECall(EField(EIdent("haxe.Timer"), "stamp"), []), EConst(CInt("1000")), false)]);
        default:
            null;
        }
    }
}
