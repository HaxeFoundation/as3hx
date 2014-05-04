package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;

class MetadataParser {

    public static function parse(tokenizer, typesSeen, cfg) : Expr {
        var parseExpr = ExprParser.parse.bind(tokenizer, typesSeen, cfg);
        Debug.dbg("parseMetadata()", tokenizer.line);
        tokenizer.ensure(TBkOpen);
        var name = tokenizer.id();
        var args = [];
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TPOpen) )
            while( !ParserUtils.opt(tokenizer.token, tokenizer.add, TPClose) ) {
                var n = null;
                switch(tokenizer.peek()) {
                case TId(i):
                    n = tokenizer.id();
                    if(!ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("="))) {
                        args.push( { name : null, val : EIdent(n) } );
                        ParserUtils.opt(tokenizer.token, tokenizer.add, TComma);
                        continue;
                    }
                case TConst(_):
                    null;
                default:
                    ParserUtils.unexpected(tokenizer.peek());
                }
                var e = parseExpr(false);
                args.push( { name : n, val :e } );
                ParserUtils.opt(tokenizer.token, tokenizer.add, TComma);
            }
        tokenizer.ensure(TBkClose);
        Debug.dbgln(" -> " + { name : name, args : args }, tokenizer.line);
        return EMeta({ name : name, args : args });
    }

}
