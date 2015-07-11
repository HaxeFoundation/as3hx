package as3hx.parsers;

class ImportParser {

    public static function parse(tokenizer:Tokenizer, cfg) {
        Debug.dbg("parseImport()", tokenizer.line);
        var a = [tokenizer.id()];
        while( true ) {
            var tk = tokenizer.token();
            switch( tk ) {
            case TDot:
                tk = tokenizer.token();
                switch(tk) {
                case TId(id): 
                    if (id == "getQualifiedClassName") return [];
                    if (id == "getQualifiedSuperclassName") return [];
                    if (id == "getTimer") return [];
                    if (id == "getDefinitionByName") return [];
                    // TODO: this is flash.utils.Proxy need to create a compat class
                    // http://blog.int3ractive.com/2010/05/using-flash-proxy-class.html
                    if (id == "flash_proxy") return ["flash","utils","Proxy"];
                    // import __AS3__.vec.Vector;
                    if (id == "Vector" && a[0] == "__AS3__") return [];
                    // import flash.utils.Dictionary;
                    if (cfg.dictionaryToHash && id == "Dictionary" && a.length == 2 && a[0] == "flash" && a[1] == "utils") return [];
                    a.push(id);
                case TOp(op):
                    if( op == "*" ) {
                        a.push(op);
                        break;
                    }
                    ParserUtils.unexpected(tk);
                default: ParserUtils.unexpected(tk);
                }
            case TCommented(s,b,t):
                tokenizer.add(t);
            default:
                tokenizer.add(tk);
                break;
            }
        }
        Debug.dbgln(" -> " + a, tokenizer.line);
        if(cfg.testCase && a.join(".") == "flash.display.Sprite")
            return [];
        return a;
    }
}
