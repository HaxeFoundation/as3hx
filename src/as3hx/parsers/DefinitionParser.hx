package as3hx.parsers;

import as3hx.As3;

class DefinitionParser {

    public static function parse(tokenizer:Tokenizer, typesSeen, cfg, genTypes, typesDefd, path, filename, meta:Array<Expr>) : Definition {
        var parseClass = ClassParser.parse.bind(tokenizer, typesSeen, cfg);
        var parseFunDef = FunctionParser.parseDef.bind(tokenizer, typesSeen, cfg);
        var parseNsDef = NsParser.parse.bind(tokenizer);

        Debug.dbgln("parseDefinition()" + meta, tokenizer.line);
        var kwds = [];
        while( true ) {
            var id = tokenizer.id();
            switch( id ) {
            case "public", "internal", "final", "dynamic": kwds.push(id);
            case "use":
                UseParser.parse(tokenizer);
                continue;
            case "class":
                var c = parseClass(genTypes, path, filename, kwds,meta,false);
                typesDefd.push(c);
                return CDef(c);
            case "interface":
                var c = parseClass(genTypes, path, filename, kwds,meta,true);
                typesDefd.push(c);
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
