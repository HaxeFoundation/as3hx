package as3hx.parsers;

import as3hx.As3;
import as3hx.Config;
import as3hx.Tokenizer;
import as3hx.Parser;

class ClassParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config, path:String, filename:String, kwds:Array<String>, meta:Array<Expr>,isInterface:Bool) : ClassDef {
        var parseType = TypeParser.parse.bind(tokenizer, types, cfg);
        var parseMetadata = MetadataParser.parse.bind(tokenizer, types, cfg);
        var parseClassVar = parseVar.bind(tokenizer, types, cfg);
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);
        var parseClassFun = parseFun.bind(tokenizer, types, cfg);
        var parseUse = UseParser.parse.bind(tokenizer);
        var parseInclude = IncludeParser.parse.bind(tokenizer, path, filename);
        var parseImport = ImportParser.parse.bind(tokenizer, cfg);

        var cname = tokenizer.id();
        var classMeta = meta;
        var imports = [];
        meta = [];
        Debug.openDebug("parseClass("+cname+")", tokenizer.line, true);
        var fields = new Array();
        var impl = [], extend = null, inits = [];
        var condVars:Array<String> = [];
        while( true ) {
            if( ParserUtils.opt(tokenizer, TId("implements")) ) {
                impl.push(parseType());
                while( ParserUtils.opt(tokenizer, TComma) )
                    impl.push(parseType());
                continue;
            }
            if( ParserUtils.opt(tokenizer, TId("extends")) ) {
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
                    while( ParserUtils.opt(tokenizer, TComma) )
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
            if( ParserUtils.opt2(tokenizer, TBrClose, meta) ) break;
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
                        } while( ParserUtils.opt(tokenizer, TComma) );
                        tokenizer.end();
                        if (condVars.length != 0 && !inCondBlock) {
                            return;
                        }
                        break;
                    case "var":
                        do {
                            fields.push(parseClassVar(kwds, meta, condVars.copy()));
                            meta = [];
                        } while( ParserUtils.opt(tokenizer, TComma) );
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
                    inits.push(parseExpr(false));
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
                    inits.push(parseExpr(false));
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
            case ENL(_):
            default:
                throw "Assert error: " + m;
            }
        }
        Debug.closeDebug("parseClass(" + cname+") finished", tokenizer.line);
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

    public static function parseVar(tokenizer, types:Types, cfg:Config, kwds, meta, condVars:Array<String>) : ClassField {
        var parseType = TypeParser.parse.bind(tokenizer, types, cfg);
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);

        Debug.openDebug("parseClassVar(", tokenizer.line);
        var name = tokenizer.id();
        Debug.dbgln(name + ")", tokenizer.line, false);
        var t = null, val = null;
        if( ParserUtils.opt(tokenizer, TColon) )
            t = parseType();
        if( ParserUtils.opt(tokenizer, TOp("=")) )
            val = parseExpr(false);

        var rv = {
            meta : meta,
            kwds : kwds,
            name : ParserUtils.escapeName(name),
            kind : FVar(t, val),
            condVars : condVars
        };
        
        var genType = ParserUtils.generateTypeIfNeeded(rv);
        if (genType != null)
            types.gen.push(genType);

        Debug.closeDebug("parseClassVar -> " + rv, tokenizer.line);
        return rv;
    }

    public static function parseFun(tokenizer, types:Types, cfg, kwds:Array<String>,meta,condVars:Array<String>, isInterface:Bool) : ClassField {
        var parseFunction = FunctionParser.parse.bind(tokenizer, types, cfg);

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
        var f = parseFunction(isInterface);
        tokenizer.end();
        Debug.closeDebug("end parseClassFun()", tokenizer.line);
        return {
            meta : meta,
            kwds : kwds,
            name : ParserUtils.escapeName(name),
            kind : FFun(f),
            condVars : condVars
        };
    }
}
