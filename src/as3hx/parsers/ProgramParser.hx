package as3hx.parsers;

import as3hx.Config;
import as3hx.Parser;
import as3hx.As3;
import as3hx.Tokenizer;

class ProgramParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config, path:String, filename:String) : Program {
        var parsePackageName = PackageNameParser.parse.bind(tokenizer);
        var parseMetadata = MetadataParser.parse.bind(tokenizer, types, cfg);
        var parseImport = ImportParser.parse.bind(tokenizer, cfg);
        var parseInclude = IncludeParser.parse.bind(tokenizer);
        var parseDefinition = DefinitionParser.parse.bind(tokenizer, types, cfg);
        var parseUse = UseParser.parse.bind(tokenizer);

        Debug.dbgln("parseProgram()", tokenizer.line);
        var pack = [];
        var header:Array<Expr> = [];

        // look for first 'package'
        var tk = tokenizer.token();
        var a = ParserUtils.explodeComment(tk);

        for(t in a) {
            switch(t) {
                case TId(s):
                    if(s != "package")
                        ParserUtils.unexpected(t);
                    if(ParserUtils.opt(tokenizer, TBrOpen))
                        pack = []
                    else {
                        pack = parsePackageName();
                        tokenizer.ensure(TBrOpen);
                    }
                case TCommented(s,b,t):
                    if(t != null) throw "Assert error " + Tokenizer.tokenString(t);
                    header.push(ECommented(s,b,false,null));
                case TNL(t): header.push(ENL(null));
                default: ParserUtils.unexpected(t);
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
                switch(id) {
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
                                        switch(meta[meta.length - 1]) {
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
                                default: imports.push(impt);
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
                    var d = parseDefinition(path, filename, meta);
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
                                case CString(p):
                                    var oldClosed = closed;
                                    closed = false;
                                    parseInclude(path, filename, p, pf.bind(true));
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
                    if(ParserUtils.opt(tokenizer, TNs)) {
                        var ns : String = id;
                        var t = ParserUtils.uncomment(tokenizer.token());
                        switch(t) {
                            case TId(id2): id = id2;
                            default: ParserUtils.unexpected(t);
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
                    else if(ParserUtils.opt(tokenizer, TSemicolon)) {
                        // class names without an import statement used
                        // for forcing compilation and linking.
                        inits.push(EIdent(id));
                        continue;
                    } else {
                        switch(tk) {
                            case TId(s):
                                inits.push(EIdent(id));
                                continue;
                            default: ParserUtils.unexpected(tk);
                        }
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
        if(!closed) ParserUtils.unexpected(TEof);
        for(it in types.gen) {
            it.name = it.name + "Typedef";
        }
        if(defs.length > 0) {
            switch(defs[0]) {
                case CDef(c):
                    var enl = ENL(null);
                    var isEImport:Expr->Bool = function(e) return e.match(EImport(_));
                    var meta = [];
                    for(it in c.meta.filter(isEImport)) {
                        meta.push(it);
                        meta.push(enl);
                    }
                    if(meta.length > 0) meta.push(enl);
                    var isENL:Expr->Bool = enl.equals;
                    for(it in c.meta) {
                        var length = meta.length;
                        if(isEImport(it) || (length > 0 && isENL(it) && isENL(meta[length - 1]))) continue;
                        meta.push(it);
                    }
                    c.meta = meta;
                default:
            }
        }
        return {
            header : header,
            pack : pack,
            imports : imports,
            typesSeen : types.seen,
            typesDefd : types.defd,
            genTypes : types.gen,
            defs : defs,
            footer : meta
        };
    }
}
