package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.parsers.StructureParser;
import as3hx.Parser;

class E4XParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config) : Expr {
        var parseE4XNext = parseNext.bind(tokenizer, types, cfg);
        var parseE4X = parse.bind(tokenizer, types, cfg);
        var parseStructure = StructureParser.parse.bind(tokenizer, types, cfg);
        
        var tk = tokenizer.token();
        Debug.dbgln("parseE4XFilter("+tk+")", tokenizer.line);
        switch(tk) {
            case TAt:
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
                        default:
                            ParserUtils.unexpected(tk);
                    }
                    tokenizer.ensure(TBkClose);
                }
                else
                    i = tokenizer.id();
                if(i.charAt(0) != "@")
                    i = "@" + i;
                return parseE4XNext(EIdent(i));
            case TId(id):
                var e = parseStructure(id);
                if( e != null )
                    return ParserUtils.unexpected(tk);
                return parseE4XNext(EIdent(id));
            case TConst(c):
                return parseE4XNext(EConst(c));
            case TCommented(s,b,t):
                tokenizer.add(t);
                return ECommented(s,b,false, parseE4X());
            default:
                return ParserUtils.unexpected(tk);
        }
    }

    private static function parseNext(tokenizer:Tokenizer, types:Types, cfg, e1 : Expr ) : Expr {
        var parseE4X = parse.bind(tokenizer, types, cfg);
        var parseE4XNext = parseNext.bind(tokenizer, types, cfg);
        var parseExprList = ExprParser.parseList.bind(tokenizer, types, cfg);
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);

        var tk = tokenizer.token();
        Debug.dbgln("parseE4XFilterNext("+e1+") ("+tk+")", tokenizer.line);
        //parseE4XFilterNext(EIdent(groups)) (TBkOpen) [Parser 1506]
        switch( tk ) {
            case TOp(op):
                for( x in tokenizer.unopsSuffix )
                    if( x == op )
                        ParserUtils.unexpected(tk);
                return ParserUtils.makeBinop(tokenizer, op,e1, parseE4X());
            case TPClose:
                Debug.dbgln("parseE4XFilterNext stopped at " + tk, tokenizer.line);
                tokenizer.add(tk);
                return e1;
            case TDot:
                tk = tokenizer.token();
                var field = null;
                switch(ParserUtils.uncomment(tk)) {
                    case TId(id):
                        field = ParserUtils.escapeName(id);
                        if( ParserUtils.opt(tokenizer, TNs) )
                            field = field + "::" + tokenizer.id();
                    case TAt:
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
                                default:
                                    ParserUtils.unexpected(tk);
                            }
                            tokenizer.ensure(TBkClose);
                        }
                        else
                            i = tokenizer.id();
                        return parseE4XNext(EE4XAttr(e1, EIdent(i)));
                    default:
                        ParserUtils.unexpected(tk);
                }
                return parseE4XNext(EField(e1, field));
            case TPOpen:
                return parseE4XNext(ECall(e1, parseExprList(TPClose)));
            case TBkOpen:
                var e2 = parseExpr(false);
                tk = tokenizer.token();
                if( tk != TBkClose ) ParserUtils.unexpected(tk);
                return parseE4XNext(EArray(e1, e2));
            default:
                return ParserUtils.unexpected( tk );
        }
    }
}
