package as3hx.parsers;

import as3hx.As3.Expr;
import as3hx.Parser;

class CaseBlockParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config):Array<Expr> {
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);

        Debug.dbgln("parseCaseBlock()", tokenizer.line);
        var el = [];
        while( true ) {
            var tk = tokenizer.peek();
            switch( tk ) {
            case TId(id): if( id == "case" || id == "default" ) break;
            case TBrClose: break;
            default:
            }
            el.push(parseExpr(false));
            tokenizer.end();
        }
        return el;
    }
}
