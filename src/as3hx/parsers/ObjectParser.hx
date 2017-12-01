package as3hx.parsers;

import as3hx.Tokenizer;
import as3hx.parsers.ExprParser;
import as3hx.As3;
import as3hx.Parser;

class ObjectParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config):Expr {
        var parseExprNext = ExprParser.parseNext.bind(tokenizer, types, cfg);
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);
        Debug.openDebug("parseObject()", tokenizer.line, true);
        var fl = new Array();

        while( true ) {
            var tk = tokenizer.token();
            var id = null;
            switch(ParserUtils.uncomment(tk)) {
            case TId(i): id = ParserUtils.escapeName(i);
            case TConst(c):
                switch( c ) {
                case CInt(v): if( v.charCodeAt(1) == "x".code ) id = Std.string(Std.parseInt(v)) else id = v;
                case CFloat(f): id = f;
                case CString(s): id = s;
                }
            case TBrClose:
                break;
            case TNL(t):
                tokenizer.add(t);
                continue;
            default:
                ParserUtils.unexpected(tk);
            }
            tokenizer.ensure(TColon);
            fl.push({ name : id, e : parseExpr(false) });

            var parseNextField:Bool = false;
            var finishObject:Bool = false;
            while (!parseNextField && !finishObject) {
                tk = tokenizer.token();
                switch(tk) {
                case TCommented(s,b,e):
                    var o = fl[fl.length-1];
                    o.e = ParserUtils.tailComment(o.e, tk);
                    tokenizer.add(e);
                case TNL(e):
                    tokenizer.add(e);
                case TBrClose:
                    finishObject = true;
                case TComma:
                    parseNextField = true;
                default:
                    ParserUtils.unexpected(tk);
                }
            }
            if (finishObject) break;
        }
        var rv = parseExprNext(EObject(fl), 0);
        Debug.closeDebug("parseObject() -> " + rv, tokenizer.line);
        return rv;
    }
}
