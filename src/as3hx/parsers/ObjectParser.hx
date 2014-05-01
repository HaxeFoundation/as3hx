package as3hx.parsers;

import as3hx.Tokenizer;
import as3hx.As3;

class ObjectParser {

    public static function parse(token:Void->Token, add,
            ensure, parseExpr:?Bool->Expr, 
            parseExprNext:Expr->?Int->Expr, line) {
        Debug.openDebug("parseObject()", line, true);
        var fl = new Array();

        while( true ) {
            var tk = token();
            var id = null;
            switch( ParserUtils.uncomment(tk) ) {
            case TId(i): id = i;
            case TConst(c):
                switch( c ) {
                case CInt(v): if( v.charCodeAt(1) == "x".code ) id = Std.string(Std.parseInt(v)) else id = v;
                case CFloat(f): id = f;
                case CString(s): id = s;
                }
            case TBrClose:
                break;
            case TNL(t):
                add(t);
                continue;
            default:
                ParserUtils.unexpected(tk);
            }
            ensure(TColon);
            fl.push({ name : id, e : parseExpr() });
            tk = token();
            switch(tk) {
            case TCommented(s,b,e):
                var o = fl[fl.length-1];
                o.e = ParserUtils.tailComment(o.e, tk);
            default:
            }
            switch( ParserUtils.uncomment(tk) ) {
            case TBrClose:
                break;
            case TComma:
                null;
            default:
                ParserUtils.unexpected(tk);
            }
        }
        var rv = parseExprNext(EObject(fl));
        Debug.closeDebug("parseObject() -> " + rv, line);
        return rv;
    }

}
