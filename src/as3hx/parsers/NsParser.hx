package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;

class NsParser {

    public static function parse(tokenizer:Tokenizer, kwds:Array<String>, meta:Array<Expr>) : NamespaceDef {
        Debug.dbgln("parseNsDef()", tokenizer.line);
        var name = tokenizer.id();
        var value = null;
        if( ParserUtils.opt(tokenizer, TOp("=")) ) {
            var t = tokenizer.token();
            value = switch( t ) {
            case TConst(c):
                switch( c ) {
                case CString(str): str;
                default: ParserUtils.unexpected(t);
                }
            default:
                ParserUtils.unexpected(t);
            };
        }
        return {
            kwds : kwds,
            meta : meta,
            name : name,
            value : value
        };
    }
}
