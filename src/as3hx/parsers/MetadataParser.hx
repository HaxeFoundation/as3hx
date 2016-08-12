package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.Parser;

class MetadataParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config) : Expr {
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);
        Debug.dbg("parseMetadata()", tokenizer.line);
        tokenizer.ensure(TBkOpen);
        var name = tokenizer.id();
        var args = [];
        if(ParserUtils.opt(tokenizer, TPOpen))
            while(!ParserUtils.opt(tokenizer, TPClose)) {
                var n = null;
                switch(tokenizer.peek()) {
                    case TId(i):
                        n = tokenizer.id();
                        if(!ParserUtils.opt(tokenizer, TOp("="))) {
                            args.push({name : null, val : EIdent(n)});
                            ParserUtils.opt(tokenizer, TComma);
                            continue;
                        }
                    case TConst(_):
                    default: ParserUtils.unexpected(tokenizer.peek());
                }
                var e = parseExpr(false);
                args.push({name : n, val : e});
                ParserUtils.opt(tokenizer, TComma);
            }
        tokenizer.ensure(TBkClose);
        Debug.dbgln(" -> " + { name : name, args : args }, tokenizer.line);
        return EMeta({ name : name, args : args });
    }

}
