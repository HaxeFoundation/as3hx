package as3hx.parsers;

import as3hx.Tokenizer;
import as3hx.As3;
import as3hx.Parser;
import neko.Lib;

class TypeParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config):T {
        var parseType = parse.bind(tokenizer, types, cfg);
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);

        Debug.dbgln("parseType()", tokenizer.line);
        // this is a ugly hack in order to fix lexer issue with "var x:*=0"
        var tmp = tokenizer.opPriority.get("*=");
        tokenizer.opPriority.remove("*=");
        if(ParserUtils.opt(tokenizer, TOp("*"))) {
            tokenizer.opPriority.set("*=",tmp);
            return TStar;
        }
        tokenizer.opPriority.set("*=",tmp);

        // for _i = new (obj as Class)() as DisplayObject;
        switch(tokenizer.peek()) {
			//case TId("this"): return TComplex(parseExpr(false));
            case TPOpen: return TComplex(parseExpr(false));
            default:
        }

        var t = tokenizer.id();
        if(t == "Vector") {
            tokenizer.ensure(TDot);
            tokenizer.ensure(TOp("<"));
            var t = parseType();
            splitEndTemplateOps(tokenizer);
            tokenizer.ensure(TOp(">"));
            types.seen.push(TVector(t));
            return TVector(t);
        }
        var t2 = tokenizer.token();
        switch(t2) {
            case TCommented(s, true, t3):
                var typeFromComment:T = OverrideTypeComment.extractType(t, s, types);
                if (typeFromComment != null) {
                    tokenizer.add(t3);
                    return typeFromComment;
                } else {
                    tokenizer.add(t2);
                }
            default:
                tokenizer.add(t2);
        }
        if (t == "Array") {
            var k:T = null;
            var t2 = tokenizer.token();
            switch(t2) {
                case TCommented(s, true, t3):
                    var arg = s.substring(2, s.length - 2);
                    if (~/\w+/g.match(arg)) {
                        t = t + "<" + arg + ">";
                        types.seen.push(TPath([arg]));
                        tokenizer.add(t3);
                    }
                default:
                    tokenizer.add(t2);
            }
            return TPath([t]);
        }
        if (t == "Dictionary") {
            var k:T = null;
            var v:T = null;
            if (cfg.useAngleBracketsNotationForDictionaryTyping) {
                var t2 = tokenizer.token();
                switch(t2) {
                    case TDot:
                        tokenizer.ensure(TOp("<"));
                        k = parseType();
                        tokenizer.ensure(TComma);
                        v = parseType();
                        tokenizer.ensure(TOp(">"));
                    default:
                        tokenizer.add(t2);
                }
            } else {
                var t2 = tokenizer.token();
                switch(t2) {
                    case TCommented(s, true, t3):
                        s = s.substring(2, s.length - 2);
                        var commaIndex:Int = s.indexOf(",");
                        if (commaIndex != -1) {
                            k = TPath(s.substr(0, commaIndex).split("."));
                            v = TPath(s.substr(commaIndex + 1).split("."));
                            types.seen.push(TPath(["Dictionary"]));
                            tokenizer.add(t3);
                        }
                    default:
                        tokenizer.add(t2);
                }
            }
            if (!cfg.dictionaryToHash) {
                types.seen.push(TPath(["Dictionary"]));
            }
            if (k == null) {
                k = TPath(["Object"]);
            }
            if (v == null) {
                v = TPath(["Object"]);
            }
			types.seen.push(k);
			types.seen.push(v);
            return TDictionary(k, v);
        }
        if(!cfg.functionToDynamic && t == "Function") {
            var result = TPath([t]);
            types.seen.push(result);
            return result;
        }

        var a = [t];
        var tk = tokenizer.token();
        while(true) {
            //trace(Std.string(tk));
            switch(tk) {
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
        var result = TPath(a);
        for(it in types.seen) {
            switch(it) {
                case TPath(p):
                    if(Lambda.foreach(a, function(it) return p.indexOf(it) != -1)) {//this condition can fail on classes com.a.b.Class && com.b.a.Class
                        return result;
                    }
                default:
            }
        }
        types.seen.push(result);
        return result;
    }

    private static function splitEndTemplateOps(tokenizer:Tokenizer) {
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
}
