package as3hx.parsers;

import as3hx.Tokenizer;

class PackageNameParser {

    public static function parse(tokenizer:Tokenizer):Array<String> {
        Debug.dbg("parsePackageName()", tokenizer.line);
        var a = [tokenizer.id()];
        while( true ) {
            var tk = tokenizer.token();
            switch( tk ) {
            case TDot:
                tk = tokenizer.token();
                switch(tk) {
                case TId(id): a.push(id);
                default: ParserUtils.unexpected(tk);
                }
            default:
                tokenizer.add(tk);
                break;
            }
        }
        Debug.dbgln(" -> " + a, tokenizer.line);
        return a;
    }
}
