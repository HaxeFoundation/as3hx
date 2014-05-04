package as3hx;
import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.ParserUtils;
import as3hx.parsers.ObjectParser;
import as3hx.parsers.UseParser;
import as3hx.parsers.ExprParser;
import as3hx.parsers.FunctionParser;
import as3hx.parsers.ClassParser;
import as3hx.parsers.MetadataParser;
import as3hx.parsers.CaseBlockParser;
import as3hx.parsers.XMLReader;
import as3hx.parsers.StructureParser;
import as3hx.parsers.TypeParser;
import as3hx.parsers.E4XParser;
import as3hx.parsers.ImportParser;
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
        return parseProgram();
    }

    public function parseInclude(p:String, call:Void->Void) {
        var oldInput = tokenizer.input;
        var oldLine = tokenizer.line;
        var oldPath = path;
        var oldFilename = filename;
        var file = path + "/" + p;
        var parts = file.split("/");
        filename = parts.pop();
        path = parts.join("/");
        Debug.openDebug("Parsing included file " + file + "\n", tokenizer.line);
        if (!sys.FileSystem.exists(file)) throw "Error: file '" + file + "' does not exist, at " + oldLine;
        var content = sys.io.File.getContent(file);
        tokenizer.line = 1;
        tokenizer.input = new haxe.io.StringInput(content);
        try {
            call();
        } catch(e:Dynamic) {
            throw "Error " + e + " while parsing included file " + file + " at " + oldLine;
        }
        tokenizer.input = oldInput;
        tokenizer.line = oldLine;
        path = oldPath;
        filename = oldFilename;
        Debug.closeDebug("Finished parsing file " + file, tokenizer.line);
    }
    
    function parseProgram() : Program {
        Debug.dbgln("parseProgram()", tokenizer.line);
        var pack = [];
        var header:Array<Expr> = [];

        // look for first 'package'
        var tk = tokenizer.token();
        var a = ParserUtils.explodeComment(tk);

        for(t in a) {
            switch(t) {
            case TId(s):
                if( s != "package" )
                    ParserUtils.unexpected(t);
                if( ParserUtils.opt(tokenizer.token, tokenizer.add, TBrOpen) )
                    pack = []
                else {
                    pack = parsePackageName();
                    tokenizer.ensure(TBrOpen);
                }
                
            case TCommented(s,b,t):
                if(t != null) throw "Assert error " + Tokenizer.tokenString(t);
                header.push(ECommented(s,b,false,null));
            case TNL(t):    
                header.push(ENL(null));
            default:
                ParserUtils.unexpected(t);
            }
        }
        
        

        // parse package
        var imports = [];
        var inits : Array<Expr> = [];
        var defs = [];
        var meta : Array<Expr> = [];
        var closed = false;
        var inNamespace = false;
        var inCondBlock = false;
        var outsidePackage = false;
        var hasOustidePackageMetaImport = false;

        var pf : Bool->Void = null;
        pf = function(included:Bool) {
        while( true ) {
            var tk = tokenizer.token();
            switch( tk ) {
            case TBrClose: // }
                if( inNamespace ) {
                    inNamespace = false;
                    continue;
                }
                else if( !closed ) {
                    closed = true;
                    outsidePackage = true;
                    continue;
                }
                else if (inCondBlock) {
                    inCondBlock = false;
                    continue;
                }
            case TBrOpen: // {
                if(inNamespace)
                    continue;
                // private classes outside of first package {}
                if( !closed ) {
                    ParserUtils.unexpected(tk);
                }
                closed = false;
                continue;
            case TEof:
                if( included )
                    return;
                if( closed )
                    break;
            case TBkOpen: // [
                tokenizer.add(tk);
                meta.push(MetadataParser.parse(tokenizer, typesSeen, cfg));
                continue;
            case TId(id):
                switch( id ) {
                case "import":
                    var impt = ImportParser.parse(tokenizer, cfg);

                    //outsidePackage = false;
                    //note : when parsing package, user defined imports
                    //are stored as meta, this way, comments can be kept
                    if (impt.length > 0) {
                        if (!outsidePackage) {
                            meta.push(EImport(impt));
                        }
                        //coner case : import for AS3 private class, for those,
                        //need to add them to regular import list or to first
                        //class metadata so that they
                        //get written at the top of file, as in Haxe all imports
                        //must be at the top of the file
                        //
                        //note : this is very hackish
                        else {
                            //no class def available, put in general import list
                            if (defs.length == 0) {
                                imports.push(impt);
                            }

                            //else check if can add to first class meta
                            switch (defs[0]) {
                                case CDef(c):

                                    //also put the newline preceding the import
                                    //in the first class meta
                                    if (meta.length > 0) {
                                        switch(meta[meta.length-1]) {
                                            case ENL(e):
                                                if (e == null) {
                                                    c.meta.push(meta.pop());
                                                }
                                            default:
                                        }
                                    }

                                    //remove extra new line generated for before
                                    //class generation if not first moved import
                                    if (hasOustidePackageMetaImport) {
                                        c.meta.pop();
                                        c.meta.pop();
                                    }
                                    
                                    //put the import in the first class meta
                                    c.meta.push(EImport(impt));

                                    //add new line before class definition
                                    c.meta.push(ENL(null));
                                    c.meta.push(ENL(null));

                                    hasOustidePackageMetaImport = true;

                                //put in regular import list
                                default:    
                                    imports.push(impt);
                            }
                        }

                    }
                       
                    tokenizer.end();
                    continue;
                case "use":
                    UseParser.parse(tokenizer);
                    continue;
                case "final", "public", "class", "internal", "interface", "dynamic", "function":
                    inNamespace = false;
                    tokenizer.add(tk);
                    var d = parseDefinition(meta);
                    switch(d) {
                        case CDef(c):
                            for(i in c.imports)
                                imports.push(i);
                            for(i in inits)
                                c.inits.push(i);
                            c.imports = [];
                            inits = [];
                        default:
                    }
                    defs.push(d);
                    meta = [];
                    continue;
                case "include":
                    tk = tokenizer.token();
                    switch(tk) {
                        case TConst(c):
                            switch(c) {
                                case CString(path):
                                    var oldClosed = closed;
                                    closed = false;
                                    parseInclude(path,pf.bind(true));
                                    tokenizer.end();
                                    closed = oldClosed;
                                default:
                                    ParserUtils.unexpected(tk);
                            }
                        default:
                            ParserUtils.unexpected(tk);
                    }
                    continue;
                default:

                    if(ParserUtils.opt(tokenizer.token, tokenizer.add, TNs)) {
                        var ns : String = id;
                        var t = ParserUtils.uncomment(tokenizer.token());

                        switch(t) {
                            case TId(id2):
                                id = id2;
                            default:
                                ParserUtils.unexpected(t);
                        }

                        if (Lambda.has(cfg.conditionalVars, ns + "::" + id)) {
                            // this is a user supplied conditional compilation variable
                            Debug.openDebug("conditional compilation: " + ns + "::" + id, tokenizer.line);
                           // condVars.push(ns + "_" + id);
                            meta.push(ECondComp(ns + "_" + id, null, null));
                            inCondBlock = true;
                            t = tokenizer.token();
                            switch (t) {
                                case TBrOpen:
                                    pf(false);
                                default:
                                    tokenizer.add(t);
                                    pf(false);
                            }
                           // condVars.pop();
                            Debug.closeDebug("end conditional compilation: " + ns + "::" + id, tokenizer.line);
                            continue;
                        } else {
                            ParserUtils.unexpected(t);
                        }
                    }
                    else if(ParserUtils.opt(tokenizer.token, tokenizer.add, TSemicolon)) {
                        // class names without an import statement used
                        // for forcing compilation and linking.
                        inits.push(EIdent(id));
                        continue;
                    } else {
                        ParserUtils.unexpected(tk);
                    }
                }
            case TSemicolon:
                continue;
            case TNL(t):
                meta.push(ENL(null));
                tokenizer.add(t);
                continue;   
            case TCommented(s,b,t):
                var t = ParserUtils.uncomment(tk);
                switch(t) {
                case TBkOpen:
                    tokenizer.add(t);
                    meta.push(ParserUtils.makeECommented(tk, MetadataParser.parse(tokenizer, typesSeen, cfg)));
                    continue;
                default:
                    tokenizer.add(t);
                    meta.push(ParserUtils.makeECommented(tk, null));
                }
                continue;
            default:
            }
            ParserUtils.unexpected(tk);
        }
        };
        pf(false);
        if( !closed )
            ParserUtils.unexpected(TEof);

        return {
            header : header,
            pack : pack,
            imports : imports,
            typesSeen : typesSeen,
            typesDefd : typesDefd,
            genTypes : genTypes,
            defs : defs,
            footer : meta
        };
    }
    
    
    function parseDefinition(meta:Array<Expr>) : Definition {
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
                var c = ClassParser.parse(tokenizer, typesSeen, cfg, genTypes, path, filename, kwds,meta,false);
                typesDefd.push(c);
                return CDef(c);
            case "interface":
                var c = ClassParser.parse(tokenizer, typesSeen, cfg, genTypes, path, filename, kwds,meta,true);
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
    
    function parseFunDef(kwds, meta) : FunctionDef {
        Debug.dbgln("parseFunDef()", tokenizer.line);
        var fname = tokenizer.id();
        var f = FunctionParser.parse(tokenizer, typesSeen, cfg, false);
        return {
            kwds : kwds,
            meta : meta,
            name : fname,
            f : f
        };
    }
    
    function parseNsDef(kwds, meta) : NamespaceDef {
        Debug.dbgln("parseNsDef()", tokenizer.line);
        var name = tokenizer.id();
        var value = null;
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("=")) ) {
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
    
    function parsePackageName() {
        Debug.dbg("parsePackageName()", tokenizer.line);
        var a = [tokenizer.id()];
        while( true ) {
            var tk = tokenizer.token();
            switch( tk ) {
            case TDot:
                tk = tokenizer.token();
                switch(tk) {
                case TId(id): a.push(id);
                default: ParserUtils.unexpected(tk);
                }
            default:
                tokenizer.add(tk);
                break;
            }
        }
        Debug.dbgln(" -> " + a, tokenizer.line);
        return a;
    }
}
