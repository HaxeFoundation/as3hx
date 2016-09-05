package as3hx.parsers;

import as3hx.As3;
import as3hx.Tokenizer;
import as3hx.Parser;

class FunctionParser {

    public static function parse(tokenizer:Tokenizer, types:Types, cfg:Config, isInterfaceFun:Bool):Function {
        var parseType = TypeParser.parse.bind(tokenizer, types, cfg);
        var parseExpr = ExprParser.parse.bind(tokenizer, types, cfg);

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
        if( !ParserUtils.opt(tokenizer, TPClose) ) {
            while( true ) {
                var tk = tokenizer.token();
                switch (tk) {
                    case TDot: //as3 var args start with "..."
                        tokenizer.ensure(TDot);
                        tokenizer.ensure(TDot);
                        f.varArgs = tokenizer.id();
                        if(ParserUtils.opt(tokenizer, TColon)) {
                            var t = tokenizer.token();
                            switch(t) {
                                case TId("Array"):
                                    tokenizer.add(t);
                                    tokenizer.ensure(t);
                                case TOp("*"):
                                    tokenizer.add(t);
                                    tokenizer.ensure(t);
                                default:
                            }
                        }
                        tokenizer.ensure(TPClose);
                        break;
                    case TId(s): //argument's name
                        var name = ParserUtils.escapeName(s);
                        var t = null, val = null;
                        expressions.push(EIdent(name));

                        if( ParserUtils.opt(tokenizer, TColon) ) { // ":" 
                            t = parseType(); //arguments type
                            expressions.push(ETypedExpr(null, t));
                        }

                        if( ParserUtils.opt(tokenizer, TOp("=")) ) {
                            val = parseExpr(false); //optional argument's default value
                            expressions.push(val);
                        }

                        f.args.push( { name : name, t : t, val : val, exprs:expressions } );
                        expressions = []; // reset for next argument

                        if( ParserUtils.opt(tokenizer, TPClose) ) // ")" end of arguments
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
        if( ParserUtils.opt(tokenizer, TColon) ) {
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

        if(tokenizer.peek() == TBrOpen) {
            f.expr = parseExpr(true);
            switch(ParserUtils.removeNewLineExpr(f.expr)) {
            case EObject(fl):
                if(fl.length == 0) {
                    f.expr = EBlock([]);
                } else {
                    throw "unexpected " + Std.string(f.expr);
                }
            case EBlock(fl):
                null;
            default:
                throw "unexpected " + Std.string(f.expr);
            }
        }
        Debug.closeDebug("end parseFun()", tokenizer.line);
        rebuildLocalFunctions(f);
        return f;
    }

    public static function parseDef(tokenizer:Tokenizer, types:Types, cfg:Config, kwds:Array<String>, meta:Array<Expr>):FunctionDef {
        var parseFunction = FunctionParser.parse.bind(tokenizer, types, cfg);
        Debug.dbgln("parseFunDef()", tokenizer.line);
        var fname = tokenizer.id();
        var f = parseFunction(false);
        return {
            kwds : kwds,
            meta : meta,
            name : fname,
            f : f
        };
    }
    
    inline static function rebuildLocalFunctions(f:Function) {
        switch(f.expr) {
            case EBlock(e):
                var result = [];
                for(i in 0...e.length) {
                    var f:Expr->Expr = null;
                    f = function(expr) return switch(expr) {
                        case EFunction(f, name):
                            if(name != null) {
                                var t = f.args.map(function(it) return it.t);
                                if(f.varArgs != null) t.push(TPath(["Array<Dynamic>"]));
                                if(t.length == 0) t.push(TPath(["Void"]));
                                t.push(f.ret.t);
                                var type = TFunction(t);
                                expr = EVars([{
                                    name: name,
                                    t: type,
                                    val: ETypedExpr(EFunction({
                                        args:f.args,
                                        varArgs:f.varArgs,
                                        expr:f.expr,
                                        ret:f.ret
                                    }, null), type)
                                }]);
                            }
                            return expr;
                        case ENL(e) if(e != null): ENL(f(e));
                        default: expr;
                    }
                    result[i] = f(e[i]);
                }
                f.expr = EBlock(result);
            default:
        }
    }
}