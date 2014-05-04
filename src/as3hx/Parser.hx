package as3hx;
import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.ParserUtils;
import as3hx.parsers.ProgramParser;
import as3hx.parsers.PackageNameParser;
import as3hx.parsers.DefinitionParser;
import as3hx.parsers.ExprParser;
import as3hx.parsers.IncludeParser;
import as3hx.parsers.FunctionParser;
import as3hx.parsers.ClassParser;
import as3hx.parsers.UseParser;
import as3hx.parsers.MetadataParser;
import as3hx.parsers.CaseBlockParser;
import as3hx.parsers.XMLReader;
import as3hx.parsers.StructureParser;
import as3hx.parsers.TypeParser;
import as3hx.parsers.E4XParser;
import as3hx.parsers.ImportParser;
import as3hx.Error;

using as3hx.Debug;

typedef Types = {
    var typesSeen : Array<Dynamic>;
    var typesDefd : Array<Dynamic>;
    var genTypes : Array<GenType>;
}

/**
 * ...
 * @author Nicolas Cannasse
 * @author Russell Weir
 */
class Parser {

    public var tokenizer : Tokenizer;

    // implementation
    var path : String;
    var filename : String;
    var cfg : Config;
    var typesSeen : Array<Dynamic>;
    var typesDefd : Array<Dynamic>;
    var genTypes : Array<GenType>;

    public function new(config:Config) {
        cfg = config;
        typesSeen = new Array<Dynamic>();
        typesDefd = new Array<Dynamic>();
        genTypes = new Array<GenType>();
    }

    public function parseString( s : String, path : String, filename : String ) {
        //convert Windows newline to Unix ones
        s = StringTools.replace(s, '\r\n', '\n');
        this.path = path;
        this.filename = filename;
        return parse( new haxe.io.StringInput(s) );
    }

    public function parse( s : haxe.io.Input ) {
        tokenizer = new Tokenizer(s);

        var types: Types = {
            typesSeen : typesSeen,
            typesDefd : typesDefd,
            genTypes : genTypes
        }

        return ProgramParser.parse(tokenizer, types, cfg, path, filename);
    }
}
