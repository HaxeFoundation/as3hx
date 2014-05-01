package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;

class StructureParser {

    public static function parseStructure(kwd, parseType, token, 
            parseCaseBlock, line, parseFun, peek, add, id, ensure, parseExpr, end, parseExprList) : Expr {
        Debug.dbgln("parseStructure("+kwd+")", line);
        return switch( kwd ) {
        case "if":
            ensure(TPOpen);
            var cond = parseExpr();
            ensure(TPClose);
            var e1 = parseExpr();
            end();
            var elseExpr = if( ParserUtils.opt(token, add, TId("else"), true) ) parseExpr() else null;
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
                var name = id(), t = null, val = null;
                if( ParserUtils.opt(token, add, TColon) )
                    t = parseType();
                if( ParserUtils.opt(token, add, TOp("=")) )
                    val = ETypedExpr(parseExpr(), t);
                vars.push( { name : name, t : t, val : val } );
                if( !ParserUtils.opt(token, add, TComma) )
                    break;
            }
            EVars(vars);
        case "while":
            ensure(TPOpen);
            var econd = parseExpr();
            ensure(TPClose);
            var e = parseExpr();
            EWhile(econd,e, false);
        case "for":
            if( ParserUtils.opt(token, add, TId("each")) ) {
                ensure(TPOpen);
                var ev = parseExpr();
                switch(ev) {
                    case EBinop(op, e1, e2, n):
                        if(op == "in") {
                            ensure(TPClose);
                            return EForEach(e1, e2, parseExpr());
                        }
                        ParserUtils.unexpected(TId(op));
                    default:
                        ParserUtils.unexpected(TId(Std.string(ev)));
                }
            } else {
                ensure(TPOpen);
                var inits = [];
                if( !ParserUtils.opt(token, add, TSemicolon) ) {
                    var e = parseExpr();
                    switch(e) {
                        case EBinop(op, e1, e2, n):
                            if(op == "in") {
                                ensure(TPClose);
                                return EForIn(e1, e2, parseExpr());
                            }
                        default:
                    }
                    if( ParserUtils.opt(token, add, TComma) ) {
                        inits = parseExprList(TSemicolon);
                        inits.unshift(e);
                    } else {
                        ensure(TSemicolon);
                        inits = [e];
                    }
                }
                var conds = parseExprList(TSemicolon);
                var incrs = parseExprList(TPClose);
                EFor(inits, conds, incrs, parseExpr());
            }
        case "break":
            var label = switch( peek() ) {
            case TId(n): token(); n;
            default: null;
            };
            EBreak(label);
        case "continue": EContinue;
        case "else": ParserUtils.unexpected(TId(kwd));
        case "function":
            var name = switch( peek() ) {
            case TId(n): token(); n;
            default: null;
            };
            EFunction(parseFun(),name);
        case "return":
            EReturn(if( peek() == TSemicolon ) null else parseExpr());
        case "new":
            if(ParserUtils.opt(token, add, TOp("<"))) {
                // o = new <VectorType>[a,b,c..]
                var t = parseType();
                ensure(TOp(">"));
                if(peek() != TBkOpen)
                    ParserUtils.unexpected(peek());
                ECall(EVector(t), [parseExpr()]);
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
                if (cc != null) cc; else ENew(t,if( ParserUtils.opt(token, add, TPOpen) ) parseExprList(TPClose) else []);
            }
        case "throw":
            EThrow( parseExpr() );
        case "try":
            var e = parseExpr();
            var catches = new Array();
            while( ParserUtils.opt(token, add, TId("catch")) ) {
                ensure(TPOpen);
                var name = id();
                ensure(TColon);
                var t = parseType();
                ensure(TPClose);
                var e = parseExpr();
                catches.push( { name : name, t : t, e : e } );
            }
            ETry(e, catches);
        case "switch":
            ensure(TPOpen);
            var e = EParent(parseExpr());
            ensure(TPClose);

            var def = null, cl = [], meta = [];
            ensure(TBrOpen);

            //parse all "case" and "default"
            while(true) {
                var tk = token();
                switch (tk) {
                    case TBrClose: //end of switch
                        break;
                    case TId(s):
                        if (s == "default") {
                            ensure(TColon);
                            def = { el : parseCaseBlock(), meta : meta };
                            meta = [];
                        }
                        else if (s == "case"){
                            var val = parseExpr();
                            ensure(TColon);
                            var el = parseCaseBlock();
                            cl.push( { val : val, el : el, meta : meta } );
                            
                            //reset for next case or default
                            meta = [];
                        }
                        else {
                            ParserUtils.unexpected(tk);
                        }
                    case TNL(t): //keep newline as meta for a case/default
                        add(t);
                        meta.push(ENL(null));
                    case TCommented(s,b,t): //keep comment as meta for a case/default
                        add(t);
                        meta.push(ECommented(s,b,false,null));        

                    default:
                        ParserUtils.unexpected(tk);     
                }
            }
            
            ESwitch(e, cl, def);
        case "do":
            var e = parseExpr();
            ensure(TId("while"));
            var cond = parseExpr();
            EWhile(cond, e, true);
        case "typeof":
            var e = parseExpr();
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
            var e = parseExpr();
            end();
            EDelete(e);
        case "getQualifiedClassName":
            ensure(TPOpen);
            var e = parseExpr();
            ensure(TPClose);
            ECall(EField(EIdent("Type"), "getClassName"), [e]);
        case "getQualifiedSuperclassName":
            ensure(TPOpen);
            var e = parseExpr();
            ensure(TPClose);
            ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getSuperClass"), [e])]);
        case "getDefinitionByName":
            ensure(TPOpen);
            var e = parseExpr();
            ensure(TPClose);
            ECall(EField(EIdent("Type"), "resolveClass"), [e]);
        case "getTimer":
            
            //consume the parenthesis from the getTimer AS3 call
            while(!ParserUtils.opt(token, add, TPClose)) {
                token();
            }
            
            ECall(EField(EIdent("Math"), "round"), [EBinop("*", ECall(EField(EIdent("haxe.Timer"), "stamp"), []), EConst(CInt("1000")), false)]);
        default:
            null;
        }
    }
}
