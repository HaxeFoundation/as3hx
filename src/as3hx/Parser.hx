package as3hx;
import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.ParserUtils;
import as3hx.parsers.ProgramParser;
import as3hx.Error;

using as3hx.Debug;


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
        this.cfg = config;
        this.typesSeen = new Array<Dynamic>();
        this.typesDefd = new Array<Dynamic>();
        this.genTypes = new Array<GenType>();
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
        return ProgramParser.parse(tokenizer, typesSeen, cfg, genTypes, typesDefd, path, filename);
    }
}
