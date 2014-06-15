package as3hx.parsers;

import as3hx.Parser;

class CaseBlockParser {

    public static function parse(tokenizer:Tokenizer, types:Types, parsers:Parsers) {
        var parseExpr = parsers.parseExpr.bind(parsers);

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
