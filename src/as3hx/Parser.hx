package as3hx;
import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.parsers.ProgramParser;

using as3hx.Debug;

typedef Types = {
    var seen : Array<T>;
    var defd : Array<Dynamic>;
    var gen : Array<GenType>;
}

/**
 * @author Nicolas Cannasse
 * @author Russell Weir
 */
class Parser {

    public var tokenizer : Tokenizer;

    // implementation
    var path : String;
    var filename : String;
    var cfg : Config;

    public function new(config:Config) {
        cfg = config;
    }

    public function parseString( s : String, path : String, filename : String ):Program {
        //convert Windows newline to Unix ones
        s = StringTools.replace(s, '\r\n', '\n');
        this.path = path;
        this.filename = filename;
        return parse( new haxe.io.StringInput(s) );
    }

    public function parse(s : haxe.io.Input):Program {
        tokenizer = new Tokenizer(s);
        var types: Types = {
            seen : [],
            defd : [],
            gen : []
        }
        return ProgramParser.parse(tokenizer, types, cfg, path, filename);
    }
}
