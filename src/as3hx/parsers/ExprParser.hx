package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.Parser;

class ExprParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config, funcStart:Bool) : Expr {
        var parseExpr = parse.bind(tokenizer, types, cfg);
        var parseFullExpr = parseFull.bind(tokenizer, types, cfg);
        var parseExprNext = parseNext.bind(tokenizer, types, cfg);
        var parseExprList = parseList.bind(tokenizer, types, cfg);
        var parseStructure = StructureParser.parse.bind(tokenizer, types, cfg);
        var parseObject = ObjectParser.parse.bind(tokenizer, types, cfg);
        var readXML = XMLReader.read.bind(tokenizer);

        var tk = tokenizer.token();
        Debug.dbgln("parseExpr(" + tk + ")", tokenizer.line);
        switch( tk ) {
        case TId(id):
            var e = parseStructure(id);
            if(e == null)
                e = EIdent(ParserUtils.escapeName(id));
            return switch(e) {
                case EIf(_,_,_) | EFor(_,_,_,_) | EForIn(_,_,_) | EForEach(_,_,_) | EWhile(_,_,_) | ESwitch(_,_,_): e;
                default: parseExprNext(e, 0);
            }
        case TConst(c):
            return parseExprNext(EConst(c), 0);
        case TPOpen:
            var e = parseExpr(false);
            tokenizer.ensure(TPClose);
            return parseExprNext(EParent(e), 0);
        case TBrOpen:
            tk = tokenizer.token();
            
            Debug.dbgln("parseExpr: " + tk, tokenizer.line);
            
            switch(ParserUtils.removeNewLine(tk, false)) {
            case TBrClose:
                if(funcStart) return EBlock([]);
                return parseExprNext(EObject([]), 0);
            case TId(_), TConst(_):
                var tk2 = tokenizer.token();
                tokenizer.add(tk2);
                tokenizer.add(tk);
                switch( tk2 ) {
                case TColon:
                    return parseExprNext(parseObject(), 0);
                default:
                }
            default:
                tokenizer.add(tk);
            }
            var a = new Array();

            //check for corner case, block contains only comments and
            //newlines. In this case, get all comments and add them to 
            //content of block expression
            if (ParserUtils.uncomment(ParserUtils.removeNewLine(tk)) == TBrClose) {
                var ta = ParserUtils.explodeComment(tk);
                for (t in ta) {
                    switch (t) {
                        case TCommented(s,b,t): a.push(ECommented(s,b,false, null));
                        case TNL(t): a.push(ENL(null));
                        default:
                    }
                }
            }
            
            while(!ParserUtils.opt(tokenizer, TBrClose)) {
                var e = parseFullExpr();
                a.push(e);
            }
            return EBlock(a);
        case TOp(op):
            if(op.charAt(0) == "/") {
                var str = op.substr(1);
                var prevChar = 0;
                var c = tokenizer.nextChar();
                while(c != "/".code || prevChar == "\\".code) {
                    prevChar = c;
                    str += String.fromCharCode(c);
                    c = tokenizer.nextChar();
                }
                c = tokenizer.nextChar();
                var opts = "";
                while( c >= "a".code && c <= "z".code ) {
                    opts += String.fromCharCode(c);
                    c = tokenizer.nextChar();
                }
                tokenizer.pushBackChar(c);
                return parseExprNext(ERegexp(str, opts), 0);
            }
            for(x in tokenizer.unopsPrefix)
                if(x == op)
                    return ParserUtils.makeUnop(op, parseExpr(false));
            if(op == "<")
                return EXML(readXML());
            return ParserUtils.unexpected(tk);
        case TBkOpen:
            var a = new Array();
            tk = tokenizer.token();
            while( ParserUtils.removeNewLine(tk) != TBkClose ) {
                tokenizer.add(tk);
                a.push(parseExpr(false));
                tk = tokenizer.token();
                if( tk == TComma )
                    tk = tokenizer.token();
            }
            return parseExprNext(EArrayDecl(a), 0);
        case TCommented(s,b,t):
            tokenizer.add(t);
            return ECommented(s,b,false,parseExpr(false));
        case TNL(t):
            tokenizer.add(t);
            return ENL(parseExpr(false));
        default:
            return ParserUtils.unexpected(tk);
        }
    }

    public static function parseNext(tokenizer:Tokenizer, types:Types, cfg:Config, e1 : Expr, pendingNewLines : Int ):Expr {
        var parseExpr = parse.bind(tokenizer, types, cfg);
        var parseExprNext = parseNext.bind(tokenizer, types, cfg);
        var parseExprList = parseList.bind(tokenizer, types, cfg);
        var parseType= TypeParser.parse.bind(tokenizer, types, cfg);
        var parseE4X = E4XParser.parse.bind(tokenizer, types, cfg);

        var tk = tokenizer.token();
        Debug.dbgln("parseExprNext("+e1+") ("+tk+")", tokenizer.line);
        switch( tk ) {
        case TOp(op):
            for(x in tokenizer.unopsSuffix)
                if(x == op) {
                    switch(e1) {
                        case EParent(_):
                            tokenizer.add(tk);
                            return e1;
                        default: return parseExprNext(EUnop(op, false, e1), 0);
                    }
                }
            var e2 = parseExpr(false);
            switch(e2) {
                case ETernary(cond, te1, te2):
                    switch(op) {
                        case "=", "+=", "-=", "*=", "%=", "/=", "<<=", ">>=", ">>>=", "&=", "^=", "|=", "&&=", "||=":
                        case _: return ETernary(ParserUtils.makeBinop(tokenizer, op, e1, cond, pendingNewLines != 0), te1, te2);
                    }
                default:
            }
            return ParserUtils.makeBinop(tokenizer, op, e1, e2, pendingNewLines != 0);
        case TNs:
            switch(e1) {
            case EIdent(i):
                switch(i) {
                    case "public":
                        return parseExprNext(ECommented("/* AS3HX WARNING namespace modifier " + i + ":: */", true, false, null), 0);
                    default: 
                }
                tk = tokenizer.token();
                switch(tk) {
                    case TId(id):
                        if (Lambda.has(cfg.conditionalVars, i + "::" + id)) {
                            // this is a user supplied conditional compilation variable
                            Debug.openDebug("conditional compilation: " + i + "::" + id, tokenizer.line);
                            switch (tokenizer.peek()) {
                                case TPClose:
                                    Debug.closeDebug("end conditional compilation: " + i + "::" + id, tokenizer.line);
                                    //corner case, the conditional compilation is within an "if" statement
                                    //example if(CONFIG::MY_CONFIG) { //code block }
                                    //normal "if" statement parsing will take care of it
                                    return ECondComp(i + "_" + id, null, null);
                                default:    
                                    var e = parseExpr(false);
                                    Debug.closeDebug("end conditional compilation: " + i + "::" + id, tokenizer.line);
                                    return ECondComp(i + "_" + id, e, null);
                            }
                        } else switch(tokenizer.peek()) {
                            case TBrOpen: // functions inside a namespace
                                return parseExprNext(ECommented("/* AS3HX WARNING namespace modifier " + i + "::"+id+" */", true, false, null), 0);
                            default:
                        }
                    default:
                }
            default:
            }
            Debug.dbgln("WARNING parseExprNext unable to create namespace for " + Std.string(e1), tokenizer.line);
            tokenizer.add(tk);
            return e1;
        case TDot:
            tk = tokenizer.token();
            Debug.dbgln(Std.string(ParserUtils.uncomment(tk)), tokenizer.line);
            var field = null;
            switch(ParserUtils.uncomment(ParserUtils.removeNewLine(tk))) {
            case TId(id):
                field = ParserUtils.escapeName(id);
                if( ParserUtils.opt(tokenizer, TNs) )
                    field = field + "::" + tokenizer.id();
            case TOp(op):
                if( op != "<" || switch(e1) { case EIdent(v): v != "Vector" && v != "Dictionary"; default: true; } ) ParserUtils.unexpected(tk);
                var t = parseType();

                var v = switch(e1) {
                    case EIdent(v): v;
                    default: null;
                }
                
                //for Dictionary, expected syntax is "Dictionary.<Key, Value>"
                if (v == "Dictionary" && cfg.dictionaryToHash) {
                    tokenizer.ensure(TComma);
                    tokenizer.id();
                }

                tokenizer.ensure(TOp(">"));
                return parseExprNext(EVector(t), 0);
            case TPOpen:
                var e2 = parseE4X();
                tokenizer.ensure(TPClose);
                return EE4XFilter(e1, e2);
            case TAt:
                //xml.attributes() is equivalent to xml.@*.
                var i : String = null;
                if(ParserUtils.opt(tokenizer, TBkOpen)) {
                    tk = tokenizer.token();
                    switch(ParserUtils.uncomment(tk)) {
                        case TConst(c):
                            switch(c) {
                                case CString(s):
                                    i = s;
                                default:
                                    ParserUtils.unexpected(tk);
                            }
                        case TId(s):
                            i = s;
                        default:
                            ParserUtils.unexpected(tk);
                    }
                    tokenizer.ensure(TBkClose);
                }
                else
                    i = tokenizer.id();
                return parseExprNext(EE4XAttr(e1, EIdent(i)), 0);
            case TDot:
                var id = tokenizer.id();
                return parseExprNext(EE4XDescend(e1, EIdent(id)), 0);
            default: ParserUtils.unexpected(tk);
            }
            return parseExprNext(EField(e1,field), 0);
        case TPOpen:
            return parseExprNext(ECall(e1, parseExprList(TPClose)), 0);
        case TBkOpen:
            var e2 = parseExpr(false);
            tk = tokenizer.token();
            if( tk != TBkClose ) ParserUtils.unexpected(tk);
            return parseExprNext(EArray(e1,e2), 0);
        case TQuestion:
            var e2 = parseExpr(false);
            tk = tokenizer.token();
            if( tk != TColon ) ParserUtils.unexpected(tk);
            var e3 = parseExpr(false);
            return ETernary(e1, e2, e3);
        case TId(s):
            switch(s) {
            case "is" | "as" | "in":
                var e2 = parseExpr(false);
                return switch(e2) {
                    case ETernary(cond, te1, te2):
                        ETernary(ParserUtils.makeBinop(tokenizer, s, e1, cond, pendingNewLines != 0), te1, te2);
                    default: ParserUtils.makeBinop(tokenizer, s, e1, e2, pendingNewLines != 0);
                }
            default:
                if (pendingNewLines != 0) {
                    //add all newlines which were declared before
                    //the identifier
                    while(pendingNewLines > 0) {
                        tk = TNL(tk);
                        pendingNewLines--;
                    }
                }
                tokenizer.add(tk);
                return e1;
            }
        case TNL(t):

            //push a token back and wrap it in newline if previous
            //token was newline
            var addToken : Token->Void = function(tk) {
                if (pendingNewLines != 0)
                    tokenizer.add(TNL(tk));
                else 
                    tokenizer.add(tk);
            }

            switch (t) {
                case TPClose:
                    addToken(tk);
                    return e1;    
                case TCommented(s,b,t):
                    addToken(t);
                    return ECommented(s,b,true, parseExprNext(e1, ++pendingNewLines));
                default:  
                    tokenizer.add(t);
                    return parseExprNext(e1, ++pendingNewLines);
            }

        case TCommented(s,b,t):
            tokenizer.add(t);
            return ECommented(s,b,true, parseExprNext(e1, 0));
           
        default:
            Debug.dbgln("parseExprNext stopped at " + tk, tokenizer.line);
            tokenizer.add(tk);
            return e1;
        }
    }

    public static function parseFull(tokenizer:Tokenizer, types:Types, cfg:Config):Expr {
        var parseExpr = parse.bind(tokenizer, types, cfg);
        Debug.dbgln("parseFullExpr()", tokenizer.line);
        var e = parseExpr(false);
        if( ParserUtils.opt(tokenizer, TColon) ) {
            switch( e ) {
            case EIdent(l): e = ELabel(l);
            default: tokenizer.add(TColon);
            }
        }
        if( !ParserUtils.opt(tokenizer, TComma) )
            tokenizer.end();
        return e;
    }

    public static function parseList(tokenizer:Tokenizer, types:Types, cfg:Config, etk:Token) : Array<Expr> {
        var parseExpr = parse.bind(tokenizer, types, cfg);
        Debug.dbgln("parseExprList()", tokenizer.line);

        var args = new Array();
        var f = function(t) {
            if(args.length == 0) return;
            args[args.length-1] = ParserUtils.tailComment(args[args.length-1], t);
        }
        if (ParserUtils.opt(tokenizer, etk)) return args;
        var exprToToken = new Map<Expr, Token>();
        while(true) {
            var tk = tokenizer.token();
            tokenizer.add(tk);
            var expr = parseExpr(false);
            exprToToken.set(expr, tk);
            args.push(expr);
            tk = tokenizer.token();
            switch(tk) {
                case TComma:
                    var ntk = tokenizer.token();
                    switch(ntk) {
                        case TCommented(s, b, t):
                            var index = args.length - 1;
                            var lastExpr = args[index];
                            args[index] = ECommented(s, b, true, lastExpr);
                            tokenizer.add(t);
                        default:
                            tokenizer.add(ntk);
                    }
                case TCommented(_,_,_):
                    var t = ParserUtils.uncomment(tk);
                    if(t == etk) {
                        f(tk);
                        break;
                    }
                    switch(t) {
                        case TComma:
                            f(tk);
                        case TNL(t):
                            f(tk);
                            args.push(ENL(null));
                            if(t == etk) break;
                        default:
                            if(tk == etk) break;
                            ParserUtils.unexpected(tk);
                    }
                case TNL(t):
                    args.push(ENL(null));
                    switch (t) {
                        case TCommented(s,b,t2): f(t);
                        default:
                    }
                    var t = ParserUtils.uncomment(t);
                    if(t == etk) break;
                default:
                    if(tk == etk) break;
                    ParserUtils.unexpected(tk);
            }
        }
        return args.filter(function(e) return !e.match(ENL(null)));
    }
}
