package as3hx.parsers;

import as3hx.Tokenizer;
import as3hx.As3;
import as3hx.Parser;

class TypeParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config):T {
        var parseType = parse.bind(tokenizer, types, cfg);
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);

        Debug.dbgln("parseType()", tokenizer.line);
        // this is a ugly hack in order to fix lexer issue with "var x:*=0"
        var tmp = tokenizer.opPriority.get("*=");
        tokenizer.opPriority.remove("*=");
        if( ParserUtils.opt(tokenizer, TOp("*")) ) {
            tokenizer.opPriority.set("*=",tmp);
            return TStar;
        }
        tokenizer.opPriority.set("*=",tmp);

        // for _i = new (obj as Class)() as DisplayObject;
        switch(tokenizer.peek()) {
        case TPOpen: return TComplex(parseExpr(false));
        default:
        }

        var t = tokenizer.id();
        if( t == "Vector" ) {
            tokenizer.ensure(TDot);
            tokenizer.ensure(TOp("<"));
            var t = parseType();
            splitEndTemplateOps(tokenizer);
            tokenizer.ensure(TOp(">"));
            types.seen.push(TVector(t));
            return TVector(t);
        } else if (cfg.dictionaryToHash && t == "Dictionary") {
            tokenizer.ensure(TDot);
            tokenizer.ensure(TOp("<"));
            var k = parseType();
            tokenizer.ensure(TComma);
            var v = parseType();
            splitEndTemplateOps(tokenizer);
            tokenizer.ensure(TOp(">"));
            types.seen.push(TDictionary(k, v));
            return TDictionary(k, v);
        }

        var a = [t];
        var tk = tokenizer.token();
        while( true ) {
            //trace(Std.string(tk));
            switch( tk ) {
            case TDot:
                tk = tokenizer.token();
                switch(ParserUtils.uncomment(tk)) {
                case TId(id): a.push(id);
                default: ParserUtils.unexpected(ParserUtils.uncomment(tk));
                }
            case TCommented(s,b,t):

                //this check prevents from losing the comment
                //token
                if (t == TDot) {
                    tk = t;
                    continue;
                }
                else {
                    tokenizer.add(tk);
                    break;
                }

            default:
                tokenizer.add(tk);
                break;
            }
            tk = tokenizer.token();
        }
        types.seen.push(TPath(a));
        return TPath(a);
    }

    private static function splitEndTemplateOps(tokenizer:Tokenizer) {
        switch( tokenizer.peek() ) {
            case TOp(s):
                tokenizer.token();
                var tl = [];
                while( s.charAt(0) == ">" ) {
                    tl.unshift(">");
                    s = s.substr(1);
                }
                if( s.length > 0 )
                    tl.unshift(s);
                for( op in tl )
                tokenizer.add(TOp(op));
            default:
        }
    }
}
