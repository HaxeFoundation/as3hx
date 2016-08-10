package as3hx.parsers;

import as3hx.As3;
import as3hx.Parser;

class DefinitionParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config, path:String, filename:String, meta:Array<Expr>) : Definition {
        var parseClass = ClassParser.parse.bind(tokenizer, types, cfg);
        var parseFunDef = FunctionParser.parseDef.bind(tokenizer, types, cfg);
        var parseNsDef = NsParser.parse.bind(tokenizer);
        var parseUse = UseParser.parse.bind(tokenizer);

        Debug.dbgln("parseDefinition()" + meta, tokenizer.line);
        var kwds = [];
        while( true ) {
            var id = tokenizer.id();
            switch( id ) {
            case "public", "internal", "final", "dynamic": kwds.push(id);
            case "use":
                parseUse();
                continue;
            case "class":
                var c = parseClass(path, filename, kwds,meta,false);
                types.defd.push(c);
                return CDef(c);
            case "interface":
                var c = parseClass(path, filename, kwds,meta,true);
                types.defd.push(c);
                return CDef(c);
            case "function":
                return FDef(parseFunDef(kwds, meta));
            case "namespace":
                return NDef(parseNsDef(kwds, meta));
            default: ParserUtils.unexpected(TId(id));
            }
        }
        return null;
    }
}
