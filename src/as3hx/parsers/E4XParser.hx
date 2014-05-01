package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;

class E4XParser {

    public static function parse(tokenizer:Tokenizer, parseStructure:String->Expr, 
            makeBinop:String->Expr->Expr->?Bool->Expr,
            parseExpr:?Bool->Expr, parseExprList) : Expr {
        var tk = tokenizer.token();
        Debug.dbgln("parseE4XFilter("+tk+")", tokenizer.line);
        switch(tk) {
            case TAt:
                var i : String = null;
                if(ParserUtils.opt(tokenizer.token, tokenizer.add, TBkOpen)) {
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
                return parseNext(EIdent(i), tokenizer, parseStructure, makeBinop, parseExpr, parseExprList);
            case TId(id):
                var e = parseStructure(id);
                if( e != null )
                    return ParserUtils.unexpected(tk);
                return parseNext(EIdent(id), tokenizer, parseStructure, makeBinop, parseExpr, parseExprList);
            case TConst(c):
                return parseNext(EConst(c), tokenizer, parseStructure, makeBinop, parseExpr, parseExprList);
            case TCommented(s,b,t):
                tokenizer.add(t);
                return ECommented(s,b,false, parse(tokenizer, parseStructure, makeBinop, parseExpr, parseExprList));
            default:
                return ParserUtils.unexpected(tk);
        }
    }

    private static function parseNext( e1 : Expr , tokenizer:Tokenizer, parseStructure, 
            makeBinop:String->Expr->Expr->?Bool->Expr,
            parseExpr, parseExprList) : Expr {
        var tk = tokenizer.token();
        Debug.dbgln("parseE4XFilterNext("+e1+") ("+tk+")", tokenizer.line);
        //parseE4XFilterNext(EIdent(groups)) (TBkOpen) [Parser 1506]
        switch( tk ) {
            case TOp(op):
                for( x in tokenizer.unopsSuffix )
                    if( x == op )
                        ParserUtils.unexpected(tk);
                return makeBinop(op,e1, parse(tokenizer, parseStructure, makeBinop, parseExpr, parseExprList));
            case TPClose:
                Debug.dbgln("parseE4XFilterNext stopped at " + tk, tokenizer.line);
                tokenizer.add(tk);
                return e1;
            case TDot:
                tk = tokenizer.token();
                var field = null;
                switch(ParserUtils.uncomment(tk)) {
                    case TId(id):
                        field = StringTools.replace(id, "$", "__DOLLAR__");
                        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TNs) )
                            field = field + "::" + tokenizer.id();
                    case TAt:
                        var i : String = null;
                        if(ParserUtils.opt(tokenizer.token, tokenizer.add, TBkOpen)) {
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
                        return parseNext(EE4XAttr(e1, EIdent(i)), tokenizer, parseStructure, makeBinop, parseExpr, parseExprList);
                    default:
                        ParserUtils.unexpected(tk);
                }
                return parseNext(EField(e1,field), tokenizer, parseStructure, makeBinop, parseExpr, parseExprList);
            case TPOpen:
                return parseNext(ECall(e1,parseExprList(TPClose)), tokenizer, parseStructure, makeBinop, parseExpr, parseExprList);
            case TBkOpen:
                var e2 = parseExpr();
                tk = tokenizer.token();
                if( tk != TBkClose ) ParserUtils.unexpected(tk);
                return parseNext(EArray(e1, e2), tokenizer, parseStructure, makeBinop, parseExpr, parseExprList);
            default:
                return ParserUtils.unexpected( tk );
        }
    }
}
