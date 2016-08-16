package as3hx;

import as3hx.Tokenizer;
import as3hx.Error;
import as3hx.Parser;
import as3hx.As3;

class ParserUtils {

    public static inline function escapeName(name:String):String {
        return switch(name) {
            case "cast": "__DOLLAR__cast";
            default: StringTools.replace(name, "$", "__DOLLAR__");
        }
    }
    
    /**
     * Takes a token that may be a comment and returns
     * an array of tokens that will have the comments
     * at the beginning
     */
    public static function explodeComment(tk:Token) : Array<Token> {
        var a = [];
        var f : Token->Void = null;
        f = function(t) {
            if(t == null)
                return;
            switch(t) {
            case TCommented(s,b,t2):
                a.push(TCommented(s,b,null));
                f(t2);
            case TNL(t):
                a.push(TNL(null));
                f(t);
            default:
                a.push(t);
            }
        }
        f(tk);
        return a;
    }

    public static function uncomment(?tk:Token):Token {
        if(tk == null) return null;
        return switch(tk) {
            case TCommented(s,b,e): uncomment(e);
            default: tk;
        }
    }

    public static function uncommentExpr(?e:Expr):Expr {
        if(e == null) return null;
        return switch(e) {
            case ECommented(s,b,t,e2): uncommentExpr(e2);
            default: e;
        }
    }

    public static function explodeCommentExpr(e) : Array<Expr> {
        var a = [];
        var f : Expr->Void = null;
        f = function(e) {
            if(e == null)
                return;
            switch(e) {
            case ECommented(s,b,t,e2):
                a.push(ECommented(s,b,t,null));
                f(e2);
            default:
                a.push(e);
            }
        }
        f(e);
        return a;
    }

    /**
     * Takes an expression e and adds the comment 'tk' to it
     * as a trailing comment, iif tk is a TCommented, discarding
     * whatever the comment target token is.
     */
    public static function tailComment(e:Expr, tk:Token) : Expr {
        //TCommented( s : String, isBlock:Bool, t : Token );
        // to
        //ECommented(s : String, isBlock:Bool, isTail:Bool, e : Expr);
        return switch(tk) {
        case TCommented(s,b,t):
            switch(t) {
            case TCommented(s2,b2,t2):
                return tailComment(ECommented(s, b, true, e), t2);
            default:
                return ECommented(s, b, true, e);
            }
        default:
            e;
        }
    }

    /**
     * Takes ctk, a TCommented, and replaces the target token
     * with 'e', creating an ECommented
     */
    public static function makeECommented(ctk:Token, e:Expr) : Expr {
        return switch(ctk) {
        case TCommented(s,b,t):
            return switch(t) {
            case TCommented(_,_,_):
                ECommented(s,b,false,makeECommented(t, e));
            default:
                ECommented(s,b,false,e);
            }
        default:
            throw "Assert error: unexpected " + ctk;
        }
    }

    /**
     * Takes a token which may be a newline. If it
     * is, return the token wrapped by the newline,
     * else return the token. If the token is a comment,
     * it may also return the wrapped tokent inside optionnaly
     */
    public static function removeNewLine(t : Token, removeComments : Bool = true) : Token {
        return switch(t) {
            case TNL(t2):
                return removeNewLine(t2, removeComments);
            case TCommented(s,b,t2):
                //remove comment by default
                if (removeComments) {
                    return removeNewLine(t2, removeComments);
                } else {
                    return t;
                }
            default:
                return t;    
        }
    }

    /**
     * Same as removeNewLine but for expression instead of token
     */
    public static function removeNewLineExpr(e : Expr, removeComments : Bool = true) : Expr {
        return switch(e) {
            case ENL(e2): removeNewLineExpr(e2, removeComments);
            case ECommented(s,b,t,e2):
                if (removeComments) {
                    return removeNewLineExpr(e2, removeComments);
                } else {
                    return e;
                }
            default: e;
        }
    }

    public static function unexpected(tk:Token) : Dynamic {
        throw EUnexpected(Tokenizer.tokenString(tk));
        return null;
    }

    /**
     * In certain cases, a typedef will be generated 
     * for a class attribute, for better type safety
     */
    public static function generateTypeIfNeeded(classVar : ClassField)
    {
        //this only applies to static field attributes, as
        //they only define constants values
        if (!Lambda.has(classVar.kwds, "static")) {
            return null;
        }

        //this only applies to class attributes defining
        //an array
        var expr = null;
        switch (classVar.kind) {
            case FVar(t, val):
                switch (t) {
                    case TPath(t):
                        if (t[0] != "Array" || t.length > 1) {
                            return null;
                        }
                        expr = val;
                    default:
                        return null;
                }
            default:
                return null;
        }

        if (expr == null)
            return null;

        //only applies if the array is initialised at
        //declaration
        var arrayDecl = null;
        switch (expr) {
            case EArrayDecl(decl):
                arrayDecl = decl;
            default:
                return null;
        }
        
        //if the arary is empty, type can't be defined
        if (arrayDecl.length == 0) {
            return null;
        }
        
        //return the type of an object field
        var getType:Expr->String = function(e) {
            switch (e) {
                case EConst(c):
                    switch(c) {
                        case CInt(v):
                            return "Int";
                        case CFloat(v):
                            return "Float";
                        case CString(v):
                            return "String";      
                    }
                case EIdent(id):
                    if (id == "true" || id == "false") {
                        return "Bool";
                    }    
                    return "Dynamic";
                default:
                    return "Dynamic";
            }
        }

        //Type declaration is only created for array of objects,.
        //Type is retrieved from the first object fields, then 
        //all remaining objects in the array are check against this
        //type. If the type is different, then it is a mixed type
        //array and no type declaration should be created
        var fields = [];
        for (i in 0...arrayDecl.length) {
            var el = ParserUtils.removeNewLineExpr(arrayDecl[i]);
            switch(el) {
                case EObject(fl):
                    for (f in fl) {
                        if (i == 0) { //first object, we get the types
                            fields.push({name: f.name, t:getType(f.e)});
                        }
                        else { //for subsequent objects, check if they match the type
                            var match = false;
                            for (field in fields) {
                                if (field.name == f.name) {
                                    match = true;
                                }
                            }
                            if (!match) {
                                return null;
                            }
                        }
                    }
                default:
                    return null;
            }
        }

        //turn class attribute name to pascal case
        var getPascalCase:String->String = function(id) {
            id = id.toLowerCase();
            var arr = id.split("_");
            var ret = "";
            for (el in arr) {
                el = el.charAt(0).toUpperCase() + el.substr(1);
                ret += el;
            }
            return ret;
        }

        //type declaration is stored, will be written
        return {name:getPascalCase(classVar.name), fields:fields, fieldName:classVar.name};
    }

    /**
     * Checks that the next token is of type 'tk', returning
     * true if so, and the token is consumed. If keepComments
     * is set, all the comments will be pushed onto the token
     * stack along with the next token after 'tk'.
     */
    public static function opt(tokenizer:Tokenizer, tk:Token, keepComments:Bool=false) : Bool {
        var t = tokenizer.token();
        var tu = ParserUtils.uncomment(ParserUtils.removeNewLine(t));
        Debug.dbgln(Std.string(t) + " to " + Std.string(tu) + " ?= " + Std.string(tk));
        if(Type.enumEq(tu, tk)) {
            if(keepComments) {
                var ta = ParserUtils.explodeComment(t);
                // if only 'tk' exists in ta, we're done
                if(ta.length < 2) return true;
                ta.pop();
                t = tokenizer.token();
                var l = ta.length - 1;
                while(l >= 0) {
                    switch(ta[l]) {
                        case TCommented(s,b,t2):
                            if(t2 != null) throw "Assert error";
                            t = TCommented(s,b,t);
                        case TNL(t):
                        default: throw "Assert error";
                    }
                    l--;
                }
                tokenizer.add(t);
            }
            return true;
        }
        tokenizer.add(t);
        return false;
    }

    /**
     * Version of opt that will search for tk, and if it is the next token,
     * all the comments before it will be pushed to array 'cmntOut'
     */
    public static function opt2(tokenizer:Tokenizer, tk:Token, cmntOut:Array<Expr>) : Bool {
        var t = tokenizer.token();
        var tu = ParserUtils.uncomment(t);
        var trnl = ParserUtils.removeNewLine(tu);
        Debug.dbgln(Std.string(t) + " to " + Std.string(tu) + " ?= " + Std.string(tk));
        if( ! Type.enumEq(trnl, tk) ) {
            tokenizer.add(t);
            return false;
        }
        switch(t) {
            case TCommented(_,_,_):
                cmntOut.push(ParserUtils.makeECommented(t, null));
            default:
        }
        return true;
    }

    public static function makeUnop(op:String, e:Expr):Expr {
        return switch(e) {
            case EBinop(bop, e1, e2, n): EBinop(bop, makeUnop(op, e1), e2, n);
            default: EUnop(op, true, e);
        }
    }

    public static function makeBinop(tokenizer:Tokenizer, op:String, e1:Expr, e:Expr, newLineBeforeOp : Bool = false ) {
        return switch( e ) {
        case EBinop(op2, e2, e3, n):
            var p1 = tokenizer.opPriority.get(op);
            var p2 = tokenizer.opPriority.get(op2);
            if( p1 < p2 || (p1 == p2 && op.charCodeAt(op.length-1) != "=".code) )
                EBinop(op2,makeBinop(tokenizer, op,e1,e2, newLineBeforeOp),e3, newLineBeforeOp);
            else
                EBinop(op,e1,e, newLineBeforeOp);
        default: EBinop(op ,e1,e, newLineBeforeOp);
        }
    }
}
