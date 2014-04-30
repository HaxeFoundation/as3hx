package as3hx;
import as3hx.As3;

enum Token {
    TEof;
    TConst( c : Const );
    TId( s : String );
    TOp( s : String );
    TPOpen;
    TPClose;
    TBrOpen;
    TBrClose;
    TDot;
    TComma;
    TSemicolon;
    TBkOpen;
    TBkClose;
    TQuestion;
    TColon;
    TAt;
    TNs;
    TNL( t : Token );
    TCommented( s : String, isBlock:Bool, t : Token );
}

class Tokenizer {

    public function new() {

    }

    private static function constString( c ) {
        return switch(c) {
        case CInt(v): v;
        case CFloat(f): f;
        case CString(s): s; // TODO : escape + quote
        }
    }

    public static function tokenString( t ) {
        return switch( t ) {
        case TEof: "<eof>";
        case TConst(c): constString(c);
        case TId(s): s;
        case TOp(s): s;
        case TPOpen: "(";
        case TPClose: ")";
        case TBrOpen: "{";
        case TBrClose: "}";
        case TDot: ".";
        case TComma: ",";
        case TSemicolon: ";";
        case TBkOpen: "[";
        case TBkClose: "]";
        case TQuestion: "?";
        case TColon: ":";
        case TAt: "@";
        case TNs: "::";
        case TNL(t): "<newline>";
        case TCommented(s,b,t): s + " " + tokenString(t);
        }
    }
}
