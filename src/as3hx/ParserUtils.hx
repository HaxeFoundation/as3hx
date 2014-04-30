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

}
