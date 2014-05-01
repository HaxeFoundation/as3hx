package as3hx;
import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.ParserUtils;
import as3hx.parsers.ObjectParser;
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
                meta.push(parseMetadata());
                continue;
            case TId(id):
                switch( id ) {
                case "import":
                    var impt = parseImport();

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
                    parseUse();
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
                    meta.push(ParserUtils.makeECommented(tk, parseMetadata()));
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
    
    function parseUse() {
        tokenizer.ensure(TId("namespace"));
        var ns = tokenizer.id();
        tokenizer.end();
    }

    function parseImport() {
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
                    // Will put this into the nme namespace for now, and merge it
                    // to nme if it works
                    if (id == "flash_proxy") return ["nme","utils","Proxy"];
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

    function parseMetadata() : Expr {
        Debug.dbg("parseMetadata()", tokenizer.line);
        tokenizer.ensure(TBkOpen);
        var name = tokenizer.id();
        var args = [];
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TPOpen) )
            while( !ParserUtils.opt(tokenizer.token, tokenizer.add, TPClose) ) {
                var n = null;
                switch(tokenizer.peek()) {
                case TId(i):
                    n = tokenizer.id();
                    if(!ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("="))) {
                        args.push( { name : null, val : EIdent(n) } );
                        ParserUtils.opt(tokenizer.token, tokenizer.add, TComma);
                        continue;
                    }
                case TConst(_):
                    null;
                default:
                    ParserUtils.unexpected(tokenizer.peek());
                }
                var e = parseExpr();
                args.push( { name : n, val :e } );
                ParserUtils.opt(tokenizer.token, tokenizer.add, TComma);
            }
        tokenizer.ensure(TBkClose);
        Debug.dbgln(" -> " + { name : name, args : args }, tokenizer.line);
        return EMeta({ name : name, args : args });
    }
    
    function parseDefinition(meta:Array<Expr>) : Definition {
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
                var c = parseClass(kwds,meta,false);
                typesDefd.push(c);
                return CDef(c);
            case "interface":
                var c = parseClass(kwds,meta,true);
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
        var f = parseFun();
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
    
    function parseClass(kwds,meta:Array<Expr>,isInterface:Bool) : ClassDef {
        var cname = tokenizer.id();
        var classMeta = meta;
        var imports = [];
        meta = [];
        Debug.openDebug("parseClass("+cname+")", tokenizer.line, true);
        var fields = new Array();
        var impl = [], extend = null, inits = [];
        var condVars:Array<String> = [];
        while( true ) {
            if( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("implements")) ) {
                impl.push(parseType());
                while( ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) )
                    impl.push(parseType());
                continue;
            }
            if( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("extends")) ) {
                if(!isInterface) {
                    extend = parseType();
                    if(cfg.testCase) {
                        switch(extend) {
                            case TPath(a):
                                var ex = a.join(".");
                                if(ex == "Sprite" || ex == "flash.display.Sprite")
                                    extend = null;
                            default:
                        }
                    }
                }
                else {
                    impl.push(parseType());
                    while( ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) )
                        impl.push(parseType());
                }
                continue;
            }
            break;
        }
        tokenizer.ensure(TBrOpen);

        var pf : Bool->Bool->Void = null;

        pf = function(included:Bool,inCondBlock:Bool) {
        while( true ) {
            // check for end of class
            if( ParserUtils.opt2(tokenizer.token, tokenizer.add, TBrClose, meta) ) break;
            var kwds = [];
            // parse all comments and metadata before next field
            while( true ) {
                var tk = tokenizer.token();
                switch( tk ) {
                case TSemicolon:
                    continue;
                case TBkOpen:
                    tokenizer.add(tk);
                    meta.push(parseMetadata());
                    continue;
                case TCommented(s,b,t):
                    tokenizer.add(t);
                    meta.push(ECommented(s,b,false,null));
                case TNL(t):
                    tokenizer.add(t);
                    meta.push(ENL(null));
                case TEof:
                    if(included)
                        return;
                    tokenizer.add(tk);
                    break;
                default:
                    tokenizer.add(tk);
                    break;
                }
            }

            while( true )  {
                var t = tokenizer.token();
                switch( t ) {
                case TId(id):
                    switch( id ) {
                    case "public", "static", "private", "protected", "override", "internal", "final": kwds.push(id);
                    case "const":
                        kwds.push(id);
                        do {
                            fields.push(parseClassVar(kwds, meta, condVars.copy()));
                            meta = [];
                        } while( ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) );
                        tokenizer.end();
                        if (condVars.length != 0 && !inCondBlock) {
                            return;
                        }
                        break;
                    case "var":
                        do {
                            fields.push(parseClassVar(kwds, meta, condVars.copy()));
                            meta = [];
                        } while( ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) );
                        tokenizer.end();
                        if (condVars.length != 0 && !inCondBlock) {
                            return;
                        }
                        break;
                    case "function":
                        fields.push(parseClassFun(kwds, meta, condVars.copy(), isInterface));
                        meta = [];
                        if (condVars.length != 0 && !inCondBlock) {
                            return;
                        }
                        break;
                    case "import":
                        var impt = parseImport();
                        if (impt.length > 0) imports.push(impt);
                        tokenizer.end();
                        break;
                    case "use":
                        parseUse();
                        break;
                    case "include":
                        t = tokenizer.token();
                        switch(t) {
                            case TConst(c):
                                switch(c) {
                                    case CString(path):
                                        parseInclude(path,pf.bind(true, false));
                                        tokenizer.end();
                                    default:
                                        ParserUtils.unexpected(t);
                                }
                            default:
                                ParserUtils.unexpected(t);
                        }
                    default:
                        kwds.push(id);
                    }
                case TCommented(s,b,t):
                    tokenizer.add(t);
                    meta.push(ECommented(s,b,false,null));
                case TEof:
                    if(included)
                        return;
                    tokenizer.add(t);
                    while( kwds.length > 0 )
                        tokenizer.add(TId(kwds.pop()));
                    inits.push(parseExpr());
                    tokenizer.end();
                case TNs:
                    if (kwds.length != 1) {
                        ParserUtils.unexpected(t);
                    }
                    var ns = kwds.pop();
                    t = tokenizer.token();
                    switch(t) {
                        case TId(id):
                            if (Lambda.has(cfg.conditionalVars, ns + "::" + id)) {
                                // this is a user supplied conditional compilation variable
                                Debug.openDebug("conditional compilation: " + ns + "::" + id, tokenizer.line);
                                condVars.push(ns + "_" + id);
                                meta.push(ECondComp(ns + "_" + id, null, null));
                                t = tokenizer.token();

                                var f:Token->Void = null;
                                f = function(t) {
                                    switch (t) {
                                        case TBrOpen:
                                            pf(false, true);

                                        case TCommented(s,b,t):
                                            f(t);   

                                        case TNL(t):
                                            meta.push(ENL(null));
                                            f(t);    

                                        default:
                                            tokenizer.add(t);
                                            pf(false, false);
                                        } 
                                }
                                f(t);
                              
                                condVars.pop();
                                Debug.closeDebug("end conditional compilation: " + ns + "::" + id, tokenizer.line);
                                break;
                            } else {
                                ParserUtils.unexpected(t);
                            }
                        default:
                            ParserUtils.unexpected(t);
                    }
                case TNL(t):
                    tokenizer.add(t);
                    meta.push(ENL(null));

                default:
                    Debug.dbgln("init block: " + t, tokenizer.line);
                    tokenizer.add(t);
                    while( kwds.length > 0 )
                        tokenizer.add(TId(kwds.pop()));
                    inits.push(parseExpr());
                    tokenizer.end();
                    break;
                }
            }
        }
        };
        pf(false, false);

        //trace("*** " + meta);
        for(m in meta) {
            switch(m) {
            case ECommented(s,b,t,e):
                if(ParserUtils.uncommentExpr(m) != null)
                    throw "Assert error: " + m;
                var a = ParserUtils.explodeCommentExpr(m);
                for(i in a) {
                    switch(i) {
                        case ECommented(s,b,t,e):
                            fields.push({name:null, meta:[ECommented(s,b,false,null)], kwds:[], kind:FComment, condVars:[]});
                        default:
                            throw "Assert error: " + i;
                    }
                }
            default:
                throw "Assert error: " + m;
            }
        }
        Debug.closeDebug("parseClass("+cname+") finished", tokenizer.line);
        return {
            meta : classMeta,
            kwds : kwds,
            imports : imports,
            isInterface : isInterface,
            name : cname,
            fields : fields,
            implement : impl,
            extend : extend,
            inits : inits
        };
    }

    function splitEndTemplateOps() {
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

    function parseType() {
        Debug.dbgln("parseType()", tokenizer.line);
        // this is a ugly hack in order to fix lexer issue with "var x:*=0"
        var tmp = tokenizer.opPriority.get("*=");
        tokenizer.opPriority.remove("*=");
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("*")) ) {
            tokenizer.opPriority.set("*=",tmp);
            return TStar;
        }
        tokenizer.opPriority.set("*=",tmp);

        // for _i = new (obj as Class)() as DisplayObject;
        switch(tokenizer.peek()) {
        case TPOpen: return TComplex(parseExpr());
        default:
        }

        var t = tokenizer.id();
        if( t == "Vector" ) {
            tokenizer.ensure(TDot);
            tokenizer.ensure(TOp("<"));
            var t = parseType();
            splitEndTemplateOps();
            tokenizer.ensure(TOp(">"));
            typesSeen.push(TVector(t));
            return TVector(t);
        } else if (cfg.dictionaryToHash && t == "Dictionary") {
            tokenizer.ensure(TDot);
            tokenizer.ensure(TOp("<"));
            var k = parseType();
            tokenizer.ensure(TComma);
            var v = parseType();
            splitEndTemplateOps();
            tokenizer.ensure(TOp(">"));
            typesSeen.push(TDictionary(k, v));
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
        typesSeen.push(TPath(a));
        return TPath(a);
    }

    function parseClassVar(kwds,meta,condVars:Array<String>) : ClassField {
        Debug.openDebug("parseClassVar(", tokenizer.line);
        var name = tokenizer.id();
        Debug.dbgln(name + ")", tokenizer.line, false);
        var t = null, val = null;
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TColon) )
            t = parseType();
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("=")) )
            val = parseExpr();

        var rv = {
            meta : meta,
            kwds : kwds,
            name : StringTools.replace(name, "$", "__DOLLAR__"),
            kind : FVar(t, val),
            condVars : condVars
        };
        
        var genType = ParserUtils.generateTypeIfNeeded(rv);
        if (genType != null)
            this.genTypes.push(genType);

        Debug.closeDebug("parseClassVar -> " + rv, tokenizer.line);
        return rv;
    }

    function parseClassFun(kwds:Array<String>,meta,condVars:Array<String>, isInterface:Bool) : ClassField {
        Debug.openDebug("parseClassFun(", tokenizer.line);
        var name = tokenizer.id();
        if( name == "get" || name == "set" ) {
            switch (tokenizer.peek()) {
                case TPOpen:
                    // not a property
                    null;
                default:
                    // a property, so better have an id next
                    kwds.push(name);
                    name = tokenizer.id();
            }
        }
        Debug.dbgln(Std.string(kwds) + " " + name + ")", tokenizer.line, false);
        var f = parseFun(isInterface);
        tokenizer.end();
        Debug.closeDebug("end parseClassFun()", tokenizer.line);
        return {
            meta : meta,
            kwds : kwds,
            name : StringTools.replace(name, "$", "__DOLLAR__"),
            kind : FFun(f),
            condVars : condVars
        };
    }
    
    function parseFun(isInterfaceFun : Bool = false) : Function {
        Debug.openDebug("parseFun()", tokenizer.line, true);
        var f = {
            args : [],
            varArgs : null,
            ret : {t:null, exprs:[]},
            expr : null
        };
        tokenizer.ensure(TPOpen);

                   
        //for each method argument (except var args)
        //store the whole expression, including
        //comments and newline
        var expressions:Array<Expr> = [];
        if( !ParserUtils.opt(tokenizer.token, tokenizer.add, TPClose) ) {
 
            while( true ) {
               
                var tk = tokenizer.token();
                switch (tk) {
                    case TDot: //as3 var args start with "..."
                        tokenizer.ensure(TDot);
                        tokenizer.ensure(TDot);
                        f.varArgs = tokenizer.id();
                        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TColon) )
                            tokenizer.ensure(TId("Array"));
                        tokenizer.ensure(TPClose);
                        break;

                    case TId(s): //argument's name
                        var name = s, t = null, val = null;
                        expressions.push(EIdent(s));

                        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TColon) ) { // ":" 
                            t = parseType(); //arguments type
                            expressions.push(ETypedExpr(null, t));
                        }

                        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("=")) ) {
                            val = parseExpr(); //optional argument's default value
                            expressions.push(val);
                        }

                        f.args.push( { name : name, t : t, val : val, exprs:expressions } );
                        expressions = []; // reset for next argument

                        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TPClose) ) // ")" end of arguments
                            break;
                        tokenizer.ensure(TComma);

                    case TCommented(s,b,t): //comment in between arguments
                        tokenizer.add(t);
                        expressions.push(ParserUtils.makeECommented(tk, null));

                    case TNL(t):  //newline in between arguments
                        tokenizer.add(t);
                        expressions.push(ENL(null));

                    default: 

                }
            }
        }

        //hold each expr for the function return until
        //the opening bracket, including comments and
        //newlines
        var retExpressions:Array<Expr> = [];

        //parse return type 
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TColon) ) {
            var t = parseType();
            retExpressions.push(ETypedExpr(null, t));
            f.ret.t = t;
        }
            
        //parse until '{' or ';' (for interface method)   
        while (true) {
            var tk = tokenizer.token();
            switch (tk) {
                case TNL(t): //parse new line before '{' or ';'
                    tokenizer.add(t);
                    
                    //corner case, in AS3 interface method don't
                    //have to end with a ";". So If we encounter a
                    //newline after the return definition, we assume
                    //this is the end of the method definition
                    if (isInterfaceFun) {
                         f.ret.exprs = retExpressions;
                         break;
                    }
                    else {
                        retExpressions.push(ENL(null));
                    }

                 case TCommented(s,b,t): //comment before '{' or ';'
                   tokenizer.add(t);
                   retExpressions.push(ParserUtils.makeECommented(tk, null));    

                case TBrOpen, TSemicolon: //end of method return 
                    tokenizer.add(tk);
                    f.ret.exprs = retExpressions;
                    break;

                default:
            }
        }       

        if( tokenizer.peek() == TBrOpen ) {
            f.expr = parseExpr(true);
            switch(ParserUtils.removeNewLineExpr(f.expr)) {
            case EObject(fl):
                if(fl.length == 0) {
                    f.expr = EBlock([]);
                } else {
                    throw "unexpected " + Std.string(f.expr);
                }
            case EBlock(_):
                null;
            default:
                throw "unexpected " + Std.string(f.expr);
            }
        }
        Debug.closeDebug("end parseFun()", tokenizer.line);
        return f;
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


    
    function parseFullExpr() {
        Debug.dbgln("parseFullExpr()", tokenizer.line);
        var e = parseExpr();
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TColon) ) {
            switch( e ) {
            case EIdent(l): e = ELabel(l);
            default: tokenizer.add(TColon);
            }
        }
        if( !ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) )
            tokenizer.end();
        return e;
    }

    function parseExpr(funcStart:Bool=false) : Expr {
        var tk = tokenizer.token();
        Debug.dbgln("parseExpr("+tk+")", tokenizer.line);
        switch( tk ) {
        case TId(id):
            var e = parseStructure(id);
            if( e == null )
                e = EIdent(id);
            return parseExprNext(e);
        case TConst(c):
            return parseExprNext(EConst(c));
        case TPOpen:
            var e = parseExpr();
            tokenizer.ensure(TPClose);
            return parseExprNext(EParent(e));
        case TBrOpen:
            tk = tokenizer.token();
          
            Debug.dbgln("parseExpr: "+tk, tokenizer.line);
            switch( tk ) {
            case TBrClose:
                if(funcStart) return EBlock([]);
                return parseExprNext(EObject([]));
            case TId(_),TConst(_):
                var tk2 = tokenizer.token();
                tokenizer.add(tk2);
                tokenizer.add(tk);
                switch( tk2 ) {
                case TColon:
                    return parseExprNext(
                            ObjectParser.parse(tokenizer.token, tokenizer.add, tokenizer.ensure,
                                parseExpr, 
                                parseExprNext,
                                tokenizer.line));
                default:
                }
            default:
                tokenizer.add(tk);
            }
            var a = new Array();

            //check for corner case, block contains only comments and
            //newlines. In this case, get all comments and add them to 
            //content of block expression
            if (ParserUtils.uncomment(ParserUtils.removeNewLine(tk)) == TBrClose) {
                var ta = ParserUtils.explodeComment(tk);
                for (t in ta) {
                    switch (t) {
                        case TCommented(s,b,t): a.push(ECommented(s,b,false, null));
                        case TNL(t): a.push(ENL(null));
                        default:
                    }
                }
            }
                
            while( !ParserUtils.opt(tokenizer.token, tokenizer.add, TBrClose) ) {
                var e = parseFullExpr();
                a.push(e);
            }
            return EBlock(a);
        case TOp(op):
            if( op.charAt(0) == "/" ) {
                var str = op.substr(1);
                var c = tokenizer.nextChar();
                while( c != "/".code ) {
                    str += String.fromCharCode(c);
                    c = tokenizer.nextChar();
                }
                c = tokenizer.nextChar();
                var opts = "";
                while( c >= "a".code && c <= "z".code ) {
                    opts += String.fromCharCode(c);
                    c = tokenizer.nextChar();
                }
                tokenizer.pushBackChar(c);
                return parseExprNext(ERegexp(str, opts));
            }
            var found;
            for( x in tokenizer.unopsPrefix )
                if( x == op )
                    return makeUnop(op, parseExpr());
            if( op == "<" )
                return EXML(readXML());
            return ParserUtils.unexpected(tk);
        case TBkOpen:
            var a = new Array();
            tk = tokenizer.token();
            while( ParserUtils.removeNewLine(tk) != TBkClose ) {
                tokenizer.add(tk);
                a.push(parseExpr());
                tk = tokenizer.token();
                if( tk == TComma )
                    tk = tokenizer.token();
            }
            return parseExprNext(EArrayDecl(a));
        case TCommented(s,b,t):
            tokenizer.add(t);
            return ECommented(s,b,false,parseExpr());
        case TNL(t):    
            tokenizer.add(t);
            return ENL(parseExpr());
        default:
            return ParserUtils.unexpected(tk);
        }
    }

    function makeUnop( op, e ) {
        return switch( e ) {
        case EBinop(bop,e1,e2, n): EBinop(bop,makeUnop(op,e1),e2, n);
        default: EUnop(op,true,e);
        }
    }

    function makeBinop( op, e1, e, newLineBeforeOp : Bool = false ) {
        return switch( e ) {
        case EBinop(op2, e2, e3, n):
            var p1 = tokenizer.opPriority.get(op);
            var p2 = tokenizer.opPriority.get(op2);
            if( p1 < p2 || (p1 == p2 && op.charCodeAt(op.length-1) != "=".code) )
                EBinop(op2,makeBinop(op,e1,e2, newLineBeforeOp),e3, newLineBeforeOp);
            else
                EBinop(op,e1,e, newLineBeforeOp);
        default: EBinop(op ,e1,e, newLineBeforeOp);
        }
    }

    function parseStructure(kwd) : Expr {
        Debug.dbgln("parseStructure("+kwd+")", tokenizer.line);
        return switch( kwd ) {
        case "if":
            tokenizer.ensure(TPOpen);
            var cond = parseExpr();
            tokenizer.ensure(TPClose);
            var e1 = parseExpr();
            tokenizer.end();
            var elseExpr = if( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("else"), true) ) parseExpr() else null;
            switch (cond) {
                case ECondComp(v, e, e2):
                    //corner case, the condition is an AS3 preprocessor 
                    //directive, it must contain the block to wrap it 
                    //in Haxe #if #end preprocessor directive
                    ECondComp(v, e1, elseExpr);
                default:
                    //regular if statement,,check for an "else" block
                    
                    EIf(cond,e1,elseExpr);
            }

        case "var", "const":
            var vars = [];
            while( true ) {
                var name = tokenizer.id(), t = null, val = null;
                if( ParserUtils.opt(tokenizer.token, tokenizer.add, TColon) )
                    t = parseType();
                if( ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("=")) )
                    val = ETypedExpr(parseExpr(), t);
                vars.push( { name : name, t : t, val : val } );
                if( !ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) )
                    break;
            }
            EVars(vars);
        case "while":
            tokenizer.ensure(TPOpen);
            var econd = parseExpr();
            tokenizer.ensure(TPClose);
            var e = parseExpr();
            EWhile(econd,e, false);
        case "for":
            if( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("each")) ) {
                tokenizer.ensure(TPOpen);
                var ev = parseExpr();
                switch(ev) {
                    case EBinop(op, e1, e2, n):
                        if(op == "in") {
                            tokenizer.ensure(TPClose);
                            return EForEach(e1, e2, parseExpr());
                        }
                        ParserUtils.unexpected(TId(op));
                    default:
                        ParserUtils.unexpected(TId(Std.string(ev)));
                }
            } else {
                tokenizer.ensure(TPOpen);
                var inits = [];
                if( !ParserUtils.opt(tokenizer.token, tokenizer.add, TSemicolon) ) {
                    var e = parseExpr();
                    switch(e) {
                        case EBinop(op, e1, e2, n):
                            if(op == "in") {
                                tokenizer.ensure(TPClose);
                                return EForIn(e1, e2, parseExpr());
                            }
                        default:
                    }
                    if( ParserUtils.opt(tokenizer.token, tokenizer.add, TComma) ) {
                        inits = parseExprList(TSemicolon);
                        inits.unshift(e);
                    } else {
                        tokenizer.ensure(TSemicolon);
                        inits = [e];
                    }
                }
                var conds = parseExprList(TSemicolon);
                var incrs = parseExprList(TPClose);
                EFor(inits, conds, incrs, parseExpr());
            }
        case "break":
            var label = switch( tokenizer.peek() ) {
            case TId(n): tokenizer.token(); n;
            default: null;
            };
            EBreak(label);
        case "continue": EContinue;
        case "else": ParserUtils.unexpected(TId(kwd));
        case "function":
            var name = switch( tokenizer.peek() ) {
            case TId(n): tokenizer.token(); n;
            default: null;
            };
            EFunction(parseFun(),name);
        case "return":
            EReturn(if( tokenizer.peek() == TSemicolon ) null else parseExpr());
        case "new":
            if(ParserUtils.opt(tokenizer.token, tokenizer.add, TOp("<"))) {
                // o = new <VectorType>[a,b,c..]
                var t = parseType();
                tokenizer.ensure(TOp(">"));
                if(tokenizer.peek() != TBkOpen)
                    ParserUtils.unexpected(tokenizer.peek());
                ECall(EVector(t), [parseExpr()]);
            } else {
                var t = parseType();
                // o = new (iconOrLabel as Class)() as DisplayObject
                var cc = switch (t) {
                                    case TComplex(e1) : 
                                    switch (e1) {
                                        case EBinop(op, e2, e3, n): 
                                        if (op == "as") {
                                            switch (e2) {
                                                case ECall(e4, a): 
                                                EBinop(op, ECall(EField(EIdent("Type"), "createInstance"), [e4, EArrayDecl(a)]), e3, n);
                                                default: 
                                                null;
                                            }
                                        }
                                        return null;
                                        default: 
                                        null;
                                    }
                                    default: 
                                    null;
                }
                if (cc != null) cc; else ENew(t,if( ParserUtils.opt(tokenizer.token, tokenizer.add, TPOpen) ) parseExprList(TPClose) else []);
            }
        case "throw":
            EThrow( parseExpr() );
        case "try":
            var e = parseExpr();
            var catches = new Array();
            while( ParserUtils.opt(tokenizer.token, tokenizer.add, TId("catch")) ) {
                tokenizer.ensure(TPOpen);
                var name = tokenizer.id();
                tokenizer.ensure(TColon);
                var t = parseType();
                tokenizer.ensure(TPClose);
                var e = parseExpr();
                catches.push( { name : name, t : t, e : e } );
            }
            ETry(e, catches);
        case "switch":
            tokenizer.ensure(TPOpen);
            var e = EParent(parseExpr());
            tokenizer.ensure(TPClose);

            var def = null, cl = [], meta = [];
            tokenizer.ensure(TBrOpen);

            //parse all "case" and "default"
            while(true) {
                var tk = tokenizer.token();
                switch (tk) {
                    case TBrClose: //end of switch
                        break;
                    case TId(s):
                        if (s == "default") {
                            tokenizer.ensure(TColon);
                            def = { el : parseCaseBlock(), meta : meta };
                            meta = [];
                        }
                        else if (s == "case"){
                            var val = parseExpr();
                            tokenizer.ensure(TColon);
                            var el = parseCaseBlock();
                            cl.push( { val : val, el : el, meta : meta } );
                            
                            //reset for next case or default
                            meta = [];
                        }
                        else {
                            ParserUtils.unexpected(tk);
                        }
                    case TNL(t): //keep newline as meta for a case/default
                        tokenizer.add(t);
                        meta.push(ENL(null));
                    case TCommented(s,b,t): //keep comment as meta for a case/default
                        tokenizer.add(t);
                        meta.push(ECommented(s,b,false,null));        

                    default:
                        ParserUtils.unexpected(tk);     
                }
            }
            
            ESwitch(e, cl, def);
        case "do":
            var e = parseExpr();
            tokenizer.ensure(TId("while"));
            var cond = parseExpr();
            EWhile(cond, e, true);
        case "typeof":
            var e = parseExpr();
            switch(e) {
            case EBinop(op, e1, e2, n):
                //if(op != "==" && op != "!=")
                //  ParserUtils.unexpected(TOp(op));
            case EParent(e1):
            case EIdent(id):
                null;
            default:
                ParserUtils.unexpected(TId(Std.string(e)));
            }
            ETypeof(e);
        case "delete":
            var e = parseExpr();
            tokenizer.end();
            EDelete(e);
        case "getQualifiedClassName":
            tokenizer.ensure(TPOpen);
            var e = parseExpr();
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("Type"), "getClassName"), [e]);
        case "getQualifiedSuperclassName":
            tokenizer.ensure(TPOpen);
            var e = parseExpr();
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getSuperClass"), [e])]);
        case "getDefinitionByName":
            tokenizer.ensure(TPOpen);
            var e = parseExpr();
            tokenizer.ensure(TPClose);
            ECall(EField(EIdent("Type"), "resolveClass"), [e]);
        case "getTimer":
            
            //consume the parenthesis from the getTimer AS3 call
            while(!ParserUtils.opt(tokenizer.token, tokenizer.add, TPClose)) {
                tokenizer.token();
            }
            
            ECall(EField(EIdent("Math"), "round"), [EBinop("*", ECall(EField(EIdent("haxe.Timer"), "stamp"), []), EConst(CInt("1000")), false)]);
        default:
            null;
        }
    }

    function parseCaseBlock() {
        Debug.dbgln("parseCaseBlock()", tokenizer.line);
        var el = [];
        while( true ) {
            var tk = tokenizer.peek();
            switch( tk ) {
            case TId(id): if( id == "case" || id == "default" ) break;
            case TBrClose: break;
            default:
            }
            el.push(parseExpr());
            tokenizer.end();
        }
        return el;
    }
    
    function parseExprNext( e1 : Expr, pendingNewLines : Int = 0 ):Expr {
        var tk = tokenizer.token();
        Debug.dbgln("parseExprNext("+e1+") ("+tk+")", tokenizer.line);
        switch( tk ) {
        case TOp(op):
            for( x in tokenizer.unopsSuffix )
                if( x == op ) {
                    if( switch(e1) { case EParent(_): true; default: false; } ) {
                        tokenizer.add(tk);
                        return e1;
                    }
                    return parseExprNext(EUnop(op,false,e1));
                }
            return makeBinop(op,e1,parseExpr(), pendingNewLines != 0);
        case TNs:
            switch(e1) {
            case EIdent(i):
                switch(i) {
                    case "public":
                        return parseExprNext(ECommented("/* AS3HX WARNING namespace modifier " + i + ":: */", true, false, null));
                    default: 
                }
                tk = tokenizer.token();
                switch(tk) {
                    case TId(id):
                        if (Lambda.has(cfg.conditionalVars, i + "::" + id)) {
                            // this is a user supplied conditional compilation variable
                            Debug.openDebug("conditional compilation: " + i + "::" + id, tokenizer.line);
                            switch (tokenizer.peek()) {
                                case TPClose:
                                    Debug.closeDebug("end conditional compilation: " + i + "::" + id, tokenizer.line);
                                    //corner case, the conditional compilation is within an "if" statement
                                    //example if(CONFIG::MY_CONFIG) { //code block }
                                    //normal "if" statement parsing will take care of it
                                    return ECondComp(i + "_" + id, null, null);
                                default:    
                                    var e = parseExpr();
                                    Debug.closeDebug("end conditional compilation: " + i + "::" + id, tokenizer.line);
                                    return ECondComp(i + "_" + id, e, null);
                            }

                        } else switch(tokenizer.peek()) {
                            case TBrOpen: // functions inside a namespace
                                return parseExprNext(ECommented("/* AS3HX WARNING namespace modifier " + i + "::"+id+" */", true, false, null));
                            default:
                        }
                    default:
                }
            default:
            }
            Debug.dbgln("WARNING parseExprNext unable to create namespace for " + Std.string(e1), tokenizer.line);
            tokenizer.add(tk);
            return e1;
        case TDot:
            tk = tokenizer.token();
            Debug.dbgln(Std.string(ParserUtils.uncomment(tk)), tokenizer.line);
            var field = null;
            switch(ParserUtils.uncomment(ParserUtils.removeNewLine(tk))) {
            case TId(id):
                field = StringTools.replace(id, "$", "__DOLLAR__");
                if( ParserUtils.opt(tokenizer.token, tokenizer.add, TNs) )
                    field = field + "::" + tokenizer.id();
            case TOp(op):
                if( op != "<" || switch(e1) { case EIdent(v): v != "Vector" && v != "Dictionary"; default: true; } ) ParserUtils.unexpected(tk);
                var t = parseType();

                var v = switch (e1) {
                    case EIdent(v): v;
                    default: null; 
                }
                
                //for Dictionary, expected syntax is "Dictionary.<Key, Value>"
                if (v == "Dictionary" && cfg.dictionaryToHash) {
                    tokenizer.ensure(TComma);
                    tokenizer.id();
                }

                tokenizer.ensure(TOp(">"));
                return parseExprNext(EVector(t));
            case TPOpen:
                var e2 = parseE4XFilter();
                tokenizer.ensure(TPClose);
                return EE4XFilter(e1, e2);
            case TAt:
                //xml.attributes() is equivalent to xml.@*.
                var i : String = null;
                if(ParserUtils.opt(tokenizer.token, tokenizer.add, TBkOpen)) {
                    tk = tokenizer.token();
                    switch(ParserUtils.uncomment(tk)) {
                        case TConst(c):
                            switch(c) {
                                case CString(s):
                                    i = s;
                                default:
                                    ParserUtils.unexpected(tk);
                            }
                        case TId(s):
                            i = s;
                        default:
                            ParserUtils.unexpected(tk);
                    }
                    tokenizer.ensure(TBkClose);
                }
                else
                    i = tokenizer.id();
                return parseExprNext(EE4XAttr(e1, EIdent(i)));
            case TDot:
                var id = tokenizer.id();
                return parseExprNext(EE4XDescend(e1, EIdent(id)));
            default: ParserUtils.unexpected(tk);
            }
            return parseExprNext(EField(e1,field));
        case TPOpen:
            return parseExprNext(ECall(e1,parseExprList(TPClose)));
        case TBkOpen:
            var e2 = parseExpr();
            tk = tokenizer.token();
            if( tk != TBkClose ) ParserUtils.unexpected(tk);
            return parseExprNext(EArray(e1,e2));
        case TQuestion:
            var e2 = parseExpr();
            tk = tokenizer.token();
            if( tk != TColon ) ParserUtils.unexpected(tk);
            var e3 = parseExpr();
            return ETernary(e1, e2, e3);
        case TId(s):
            switch( s ) {
            case "is": return makeBinop("is", e1, parseExpr(), pendingNewLines != 0);
            case "as": return makeBinop("as",e1,parseExpr(), pendingNewLines != 0);
            case "in": return makeBinop("in",e1,parseExpr(), pendingNewLines != 0);
            default:

                if (pendingNewLines != 0) {
                    //add all newlines which were declared before
                    //the identifier
                    while(pendingNewLines > 0) {
                        tk = TNL(tk);
                        pendingNewLines--;
                    }
                }
                tokenizer.add(tk);
                return e1;
            }
        case TNL(t):

            //push a token back and wrap it in newline if previous
            //token was newline
            var addToken : Token->Void = function(tk) {
                if (pendingNewLines != 0)
                    tokenizer.add(TNL(tk));
                else 
                    tokenizer.add(tk);
            }

            switch (t) {
                case TPClose:
                    addToken(tk);
                    return e1;    
                case TCommented(s,b,t):
                    addToken(t);
                    return ECommented(s,b,true, parseExprNext(e1, ++pendingNewLines));
                default:  
                    tokenizer.add(t);
                    return parseExprNext(e1, ++pendingNewLines);  
            }

        case TCommented(s,b,t):
            tokenizer.add(t);
            return ECommented(s,b,true, parseExprNext(e1));
           
        default:
            Debug.dbgln("parseExprNext stopped at " + tk, tokenizer.line);
            tokenizer.add(tk);
            return e1;
        }
    }

    function parseExprList( etk ) : Array<Expr> {
        Debug.dbgln("parseExprList()", tokenizer.line);

        var args = new Array();
        var f = function(t) {
            if(args.length == 0) return;
            args[args.length-1] = ParserUtils.tailComment(args[args.length-1], t);
        }
        if( ParserUtils.opt(tokenizer.token, tokenizer.add, etk) )
            return args;
        while( true ) {
            args.push(parseExpr());
            var tk = tokenizer.token();
            switch( tk ) {
            case TComma:
            case TCommented(_,_,_):
                var t = ParserUtils.uncomment(tk);
                if(t == etk) {
                    f(tk);
                    break;
                }
                switch(t) {
                case TComma:
                    f(tk);
                case TNL(t):
                    f(tk);
                    args.push(ENL(null));
                    if (t == etk) break;
                default:
                    if( tk == etk ) break;
                    ParserUtils.unexpected(tk);
                }
            case TNL(t):
                args.push(ENL(null));
                switch (t) {
                    case TCommented(s,b,t2):
                        f(t);
                    default:    
                }
                 var t = ParserUtils.uncomment(t);
                if (t == etk) break;
            default:
                if( tk == etk ) break;
                ParserUtils.unexpected(tk);
            }
        }
        return args;
    }

    function parseE4XFilter() : Expr {
        var tk = tokenizer.token();
        Debug.dbgln("parseE4XFilter("+tk+")", tokenizer.line);
        switch(tk) {
            case TAt:
                var i : String = null;
                if(ParserUtils.opt(tokenizer.token, tokenizer.add, TBkOpen)) {
                    tk = tokenizer.token();
                    switch(ParserUtils.uncomment(tk)) {
                        case TConst(c):
                            switch(c) {
                                case CString(s):
                                    i = s;
                                default:
                                    ParserUtils.unexpected(tk);
                            }
                        default:
                            ParserUtils.unexpected(tk);
                    }
                    tokenizer.ensure(TBkClose);
                }
                else
                    i = tokenizer.id();
                if(i.charAt(0) != "@")
                    i = "@" + i;
                return parseE4XFilterNext(EIdent(i));
            case TId(id):
                var e = parseStructure(id);
                if( e != null )
                    return ParserUtils.unexpected(tk);
                return parseE4XFilterNext(EIdent(id));
            case TConst(c):
                return parseE4XFilterNext(EConst(c));
            case TCommented(s,b,t):
                tokenizer.add(t);
                return ECommented(s,b,false,parseE4XFilter());
            default:
                return ParserUtils.unexpected(tk);
        }
    }

    function parseE4XFilterNext( e1 : Expr ) : Expr {
        var tk = tokenizer.token();
        Debug.dbgln("parseE4XFilterNext("+e1+") ("+tk+")", tokenizer.line);
        //parseE4XFilterNext(EIdent(groups)) (TBkOpen) [Parser 1506]
        switch( tk ) {
            case TOp(op):
                for( x in tokenizer.unopsSuffix )
                    if( x == op )
                        ParserUtils.unexpected(tk);
                return makeBinop(op,e1,parseE4XFilter());
            case TPClose:
                Debug.dbgln("parseE4XFilterNext stopped at " + tk, tokenizer.line);
                tokenizer.add(tk);
                return e1;
            case TDot:
                tk = tokenizer.token();
                var field = null;
                switch(ParserUtils.uncomment(tk)) {
                    case TId(id):
                        field = StringTools.replace(id, "$", "__DOLLAR__");
                        if( ParserUtils.opt(tokenizer.token, tokenizer.add, TNs) )
                            field = field + "::" + tokenizer.id();
                    case TAt:
                        var i : String = null;
                        if(ParserUtils.opt(tokenizer.token, tokenizer.add, TBkOpen)) {
                            tk = tokenizer.token();
                            switch(ParserUtils.uncomment(tk)) {
                                case TConst(c):
                                    switch(c) {
                                        case CString(s):
                                            i = s;
                                        default:
                                            ParserUtils.unexpected(tk);
                                    }
                                default:
                                    ParserUtils.unexpected(tk);
                            }
                            tokenizer.ensure(TBkClose);
                        }
                        else
                            i = tokenizer.id();
                        return parseE4XFilterNext(EE4XAttr(e1, EIdent(i)));
                    default:
                        ParserUtils.unexpected(tk);
                }
                return parseE4XFilterNext(EField(e1,field));
            case TPOpen:
                return parseE4XFilterNext(ECall(e1,parseExprList(TPClose)));
            case TBkOpen:
                var e2 = parseExpr();
                tk = tokenizer.token();
                if( tk != TBkClose ) ParserUtils.unexpected(tk);
                return parseE4XFilterNext(EArray(e1, e2));
            default:
                return ParserUtils.unexpected( tk );
        }
    }
    
    function readXML() {
        Debug.dbgln("readXML()", tokenizer.line);
        var buf = new StringBuf();
        var input = tokenizer.input;
        buf.addChar("<".code);
        buf.addChar(tokenizer.char);

        //corner case : check wether this is a satndalone CDATA element
        //(not wrapped in XML element)
        var isCDATA = tokenizer.char == "!".code; 
        
        tokenizer.char = 0;
        try {
            var prev = 0;
            while(true) {
                var c = input.readByte();
                if(c == "\n".code) tokenizer.line++;
                buf.addChar(c);
                if( c == ">".code ) break;
                prev = c;
            }
            if( prev == "/".code )
                return buf.toString();
            if (isCDATA)
                return buf.toString();    
            while(true) {
                var c = input.readByte();
                if(c == "\n".code) tokenizer.line++;
                if( c == "<".code ) {
                    c = input.readByte();
                    if(c == "\n".code) tokenizer.line++;
                    if( c == "/".code ) {
                        buf.add("</");
                        break;
                    }
                    if (c == "!".code) { // CDATA element
                        buf.add("<");
                    }
                    else {
                        tokenizer.char = c;
                        buf.add(readXML());
                        continue;
                    }
                }
                buf.addChar(c);
            }
            while(true) {
                var c = input.readByte();
                if(c == "\n".code) tokenizer.line++;
                buf.addChar(c);
                if( c == ">".code ) break;
            }
            return buf.toString();
        } catch( e : haxe.io.Eof ) {
            throw EUnterminatedXML;
        }
    }
}
