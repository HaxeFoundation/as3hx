package as3hx;

import as3hx.Tokenizer;
import as3hx.As3;

class ParserUtils {

    /**
     * Takes a token that may be a comment and returns
     * an array of tokens that will have the comments
     * at the beginning
     **/
    public static function explodeComment(tk) : Array<Token> {
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

    public static function uncomment(tk) {
        if(tk == null)
            return null;
        return switch(tk) {
        case TCommented(s,b,e):
            uncomment(e);
        default:
            tk;
        }
    }

    public static function uncommentExpr(e) {
        if(e == null)
            return null;
        return switch(e) {
        case ECommented(s,b,t,e2):
            uncommentExpr(e2);
        default:
            e;
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
     **/
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
     **/
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
            case ENL(e2):
                return removeNewLineExpr(e2, removeComments);
            case ECommented(s,b,t,e2):
                if (removeComments) {
                    return removeNewLineExpr(e2, removeComments);
                } else {
                    return e;
                }
            default:
                return e;    
        }
    }
}
