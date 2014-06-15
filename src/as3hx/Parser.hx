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
import as3hx.parsers.NsParser;
import as3hx.parsers.UseParser;
import as3hx.parsers.MetadataParser;
import as3hx.parsers.ObjectParser;
import as3hx.parsers.CaseBlockParser;
import as3hx.parsers.XMLReader;
import as3hx.parsers.StructureParser;
import as3hx.parsers.TypeParser;
import as3hx.parsers.E4XParser;
import as3hx.parsers.ImportParser;
import as3hx.Error;

using as3hx.Debug;

typedef Types = {
    var seen : Array<Dynamic>;
    var defd : Array<Dynamic>;
    var gen : Array<GenType>;
}

typedef Parsers = {
    var parseCaseBlock:Parsers->Array<Expr>;
    var parseExpr:Parsers->Bool->Expr;
    var parseExprList:Parsers->Token->Array<Expr>;
    var parseExprNext:Parsers->Expr->Int->Expr;
    var parseExprFull:Parsers->Expr;
    var parseClass:Parsers->Array<String>->Array<Expr>->Bool->ClassDef;
    var parseClassVar:Parsers->Array<String>->Array<Expr>->Array<String>->ClassField;
    var parseClassFun:Parsers->Array<String>->Array<Expr>->Array<String>->Bool->ClassField;
    var parseDefinition:Parsers->Array<Expr>->Definition;
    var parseType:Parsers->T;
    var parseMetadata:Parsers->Expr;
    var parseUse:Void->Void;
    var parseInclude:String->(Void->Void)->Void;
    var parseImport:Void->Array<String>;
    var parseFunction:Parsers->Bool->Function;
    var parseFunctionDef:Parsers->Array<String>->Array<Expr>->FunctionDef;
    var parseNamespace:Array<String>->Array<Expr>->NamespaceDef;
    var parseE4X:Parsers->Expr;
    var parseStructure:Parsers->String->Expr;
    var parseObject:Parsers->Expr;
    var parsePackageName:Void->Array<String>;
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

    public function new(config:Config) {
        cfg = config;
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
            seen : [],
            defd : [],
            gen : []
        }

        var parsers:Parsers = {
            parseExpr: ExprParser.parse.bind(tokenizer, types, cfg),
            parseExprList: ExprParser.parseList.bind(tokenizer, types, cfg),
            parseExprNext: ExprParser.parseNext.bind(tokenizer, types, cfg),
            parseExprFull: ExprParser.parseFull.bind(tokenizer, types, cfg),
            parseCaseBlock: CaseBlockParser.parse.bind(tokenizer, types),
            parseClass: ClassParser.parse.bind(tokenizer, types, cfg, path, filename),
            parseClassVar: ClassParser.parseVar.bind(tokenizer, types, cfg),
            parseClassFun: ClassParser.parseFun.bind(tokenizer, types, cfg),
            parseDefinition: DefinitionParser.parse.bind(tokenizer, types, cfg),
            parseType: TypeParser.parse.bind(tokenizer, types, cfg),
            parseMetadata: MetadataParser.parse.bind(tokenizer, types, cfg),
            parseUse: UseParser.parse.bind(tokenizer),
            parseInclude: IncludeParser.parse.bind(tokenizer, path, filename),
            parseImport: ImportParser.parse.bind(tokenizer, cfg),
            parseFunction: FunctionParser.parse.bind(tokenizer, types, cfg),
            parseFunctionDef: FunctionParser.parseDef.bind(tokenizer, types, cfg),
            parseNamespace: NsParser.parse.bind(tokenizer),
            parseE4X: E4XParser.parse.bind(tokenizer, types, cfg),
            parseStructure: StructureParser.parse.bind(tokenizer, types, cfg),
            parseObject: ObjectParser.parse.bind(tokenizer, types, cfg),
            parsePackageName: PackageNameParser.parse.bind(tokenizer)
        }

        return ProgramParser.parse(tokenizer, types, cfg, parsers);
    }
}
