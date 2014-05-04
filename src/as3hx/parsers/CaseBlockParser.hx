package as3hx.parsers;

class CaseBlockParser {

    public static function parse(tokenizer:Tokenizer, typesSeen, cfg) {
        var parseExpr = ExprParser.parse.bind(tokenizer, typesSeen, cfg);

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
