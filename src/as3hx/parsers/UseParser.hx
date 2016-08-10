package as3hx.parsers;

import as3hx.Tokenizer;

class UseParser {
    public static function parse(tokenizer:Tokenizer) {
        tokenizer.ensure(TId("namespace"));
        var ns = tokenizer.id();
        tokenizer.end();
    }
}
