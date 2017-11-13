package as3hx;
import as3hx.As3;
import as3hx.Error;
import as3hx.Tokenizer.Token;

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

    public var identChars : String;
    public var unopsPrefix : Array<String>;
    public var unopsSuffix : Array<String>;
    public var opPriority : Map<String,Int>;
    public var line : Int;
    public var pc : Int;

    public var input : haxe.io.Input;
    public var char : Int;
    var ops : Array<Bool>;
    var idents : Array<Bool>;
    var tokens : haxe.ds.GenericStack<Token>;

    public function new(s:haxe.io.Input) {
        line = 1;
        pc = 1;
        var p = [
            ["%", "*", "/"],
            ["+", "-"],
            ["<<", ">>", ">>>"],
            [">", "<", ">=", "<=", "is", "as", "in"],
            ["==", "!="],
            ["&"],
            ["^"],
            ["|"],
            ["&&"],
            ["||"],
            ["?:"],
            ["=", "+=", "-=", "*=", "%=", "/=", "<<=", ">>=", ">>>=", "&=", "^=", "|=", "&&=", "||="]
        ];
        opPriority = new Map();
        for( i in 0...p.length )
            for( op in p[i] )
                opPriority.set(op, i);
        unopsPrefix = ["!", "++", "--", "-", "+", "~"];
        for( op in unopsPrefix )
            if( !opPriority.exists(op) )
                opPriority.set(op, -1);
        unopsSuffix = ["++", "--"];
        identChars = "$ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";
        char = 0;
        input = s;
        char = 0;
        input = s;
        ops = new Array();
        idents = new Array();
        tokens = new haxe.ds.GenericStack<Token>();
        for( i in 0...identChars.length )
            idents[identChars.charCodeAt(i)] = true;
        for( op in opPriority.keys() )
            for( i in 0...op.length )
                if (!idents[op.charCodeAt(i)])
                    ops[op.charCodeAt(i)] = true;
    }

    private static function constString(c:Const):String {
        return switch(c) {
            case CInt(v): v;
            case CFloat(f): f;
            case CString(s): s; // TODO : escape + quote
        }
    }

    public static function tokenString(t:Token):String {
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

    public function token() : Token {
        if( !tokens.isEmpty() )
            return tokens.pop();

        var char = nextChar();
        while( true ) {
            switch( char ) {
            case 0: return TEof;
            case ' '.code,'\t'.code:
            case '\n'.code:
                line++;
                pc = 1;
                return TNL(token());
            case '\r'.code:
                line++;
                char = nextChar();
                if( char != "\n".code )
                    pushBackChar(char);
                pc = 1;
            case ';'.code: return TSemicolon;
            case '('.code: return TPOpen;
            case ')'.code: return TPClose;
            case ','.code: return TComma;
            case '.'.code, '0'.code, '1'.code, '2'.code, '3'.code, '4'.code, '5'.code, '6'.code, '7'.code, '8'.code, '9'.code:
                var buf = new StringBuf();
                while( char >= '0'.code && char <= '9'.code ) {
                    buf.addChar(char);
                    char = nextChar();
                }
                switch( char ) {
                case 'x'.code:
                    if( buf.toString() == "0" ) {
                        do {
                            buf.addChar(char);
                            char = nextChar();
                        } while( (char >= '0'.code && char <= '9'.code) || (char >= 'A'.code && char <= 'F'.code) || (char >= 'a'.code && char <= 'f'.code) );
                        pushBackChar(char);
                        return TConst(CInt(buf.toString()));
                    }
                    pushBackChar(char);
                    return TConst(CInt(buf.toString()));
                case 'e'.code:
                    if( buf.toString() == '.' ) {
                        pushBackChar(char);
                        return TDot;
                    }
                    buf.addChar(char);
                    char = nextChar();
                    if( char == '-'.code ) {
                        buf.addChar(char);
                        char = nextChar();
                    }
                    while( char >= '0'.code && char <= '9'.code ) {
                        buf.addChar(char);
                        char = nextChar();
                    }
                    pushBackChar(char);
                    return TConst(CFloat(buf.toString()));
                case '.'.code:
                    do {
                        buf.addChar(char);
                        char = nextChar();
                    } while( char >= '0'.code && char <= '9'.code );
                    switch( char ) {
                        case 'e'.code | 'E'.code:
                            if( buf.toString() == '.' ) {
                                pushBackChar(char);
                                return TDot;
                            }
                            buf.addChar(char);
                            char = nextChar();
                            switch(char) {
                                case '-'.code | '+'.code:
                                    buf.addChar(char);
                                    char = nextChar();
                            }
                            while( char >= '0'.code && char <= '9'.code ) {
                                buf.addChar(char);
                                char = nextChar();
                            }
                            pushBackChar(char);
                            return TConst(CFloat(buf.toString()));
                        default:
                            pushBackChar(char);
                    }
                    var str = buf.toString();
                    if( str.length == 1 ) return TDot;
                    return TConst(CFloat(str));
                default:
                    pushBackChar(char);
                    return TConst(CInt(buf.toString()));
                }
            case '{'.code: return TBrOpen;
            case '}'.code: return TBrClose;
            case '['.code: return TBkOpen;
            case ']'.code: return TBkClose;
            case '"'.code, "'".code: return TConst( CString(readString(char)) );
            case '?'.code: return TQuestion;
            case ':'.code:
                char = nextChar();
                if( char == ':'.code )
                    return TNs;
                pushBackChar(char);
                return TColon;
            case '@'.code: return TAt;
            case 0xC2: // UTF8-space
                if( nextChar() != 0xA0 )
                    throw EInvalidChar(char);
            case 0xEF: // BOM
                if( nextChar() != 187 || nextChar() != 191 )
                    throw EInvalidChar(char);
            default:
                if( ops[char] ) {
                    var op = String.fromCharCode(char);
                    while( true ) {
                        char = nextChar();
                        if( !ops[char] ) {
                            pushBackChar(char);
                            return TOp(op);
                        }
                        op += String.fromCharCode(char);
                        if( op == "//" ) {
                            var contents : String = "//";
                            try {
                                while( char != '\r'.code && char != '\n'.code ) {
                                    char = input.readByte();
                                    contents += String.fromCharCode(char);
                                }
                                pushBackChar(char);
                            } catch( e : Dynamic ) {
                            }
                            return TCommented(StringTools.trim(contents), false, token());
                        }
                        if( op == "/*" ) {
                            var old = line;
                            var contents : String = "/*";
                            try {
                                while( true ) {
                                    while( char != "*".code ) {
                                        if( char == "\n".code ) {
                                            line++;
                                        }
                                        else if( char == "\r".code ) {
                                            line++;
                                            char = input.readByte();
                                            contents += String.fromCharCode(char);
                                            if( char == "\n".code ) {
                                                char = input.readByte();
                                                contents += String.fromCharCode(char);
                                            }
                                            continue;
                                        }
                                        char = input.readByte();
                                        contents += String.fromCharCode(char);
                                    }
                                    char = input.readByte();
                                    contents += String.fromCharCode(char);
                                    if( char == '/'.code )
                                        break;
                                }
                            } catch( e : Dynamic ) {
                                line = old;
                                throw EUnterminatedComment;
                            }
                            return TCommented(contents, true, token());
                        }
                        else if( op == "!=" ) {
                            char = nextChar();
                            if(String.fromCharCode(char) != "=")
                                pushBackChar(char);
                        }
                        else if( op == "==" ) {
                            char = nextChar();
                            if(String.fromCharCode(char) != "=")
                                pushBackChar(char);
                        }
                        if( !opPriority.exists(op) ) {
                            pushBackChar(char);
                            return TOp(op.substr(0, -1));
                        }
                    }
                }
                if( idents[char] ) {
                    var id = String.fromCharCode(char);
                    while( true ) {
                        char = nextChar();
                        if( !idents[char] ) {
                            pushBackChar(char);
                            return TId(id);
                        }
                        id += String.fromCharCode(char);
                    }
                }
                throw EInvalidChar(char);
            }
            char = nextChar();
        }
        return null;
    }

    public function id():String {
        var t = token();
        return switch(ParserUtils.uncomment(ParserUtils.removeNewLine(t))) {
            case TId(i): i;
            default: ParserUtils.unexpected(t);
        }
    }

    public function peek() : Token {
        if(tokens.isEmpty())
            add(token());
        return ParserUtils.uncomment(ParserUtils.removeNewLine(tokens.first()));
    }

    public function nextChar():Int {
        var c = 0;
        if(char == 0) {
            pc++;
            return try input.readByte() catch(e : Dynamic) 0;
        }
        c = char;
        char = 0;
        return c;
    }

    public function pushBackChar(c:Int) {
        if(char != 0)
            throw "Unexpected character pushed back";
        char = c;
    }

    public function add(tk:Token) {
        tokens.add(tk);
    }

    /**
     * Ensures the next token (ignoring comments and newlines) is 'tk'.
     * @return array of comments before 'tk'
     */
    public function ensure(tk:Token) : Array<Token> {
        var t = token();

        //remove comment token
        var tu = ParserUtils.uncomment(t);

        //remove newline token
        var trnl = ParserUtils.removeNewLine(tu);
        if(!Type.enumEq(trnl, tk))
            ParserUtils.unexpected(trnl);
        var ta = ParserUtils.explodeComment(t);
        ta.pop();
        return ta;
    }

    function readString(until:Int):String {
        Debug.dbgln("readString()", line);
        var c;
        var b = new haxe.io.BytesOutput();
        var esc = false;
        var old = line;
        var s = input;
        while( true ) {
            try {
                c = s.readByte();
                if(c == "\n".code) line++;
            } catch( e : Dynamic ) {
                line = old;
                throw EUnterminatedString;
            }
            if( esc ) {
                esc = false;
                switch( c ) {
                /*
                case 'n'.code: b.writeByte(10);
                case 'r'.code: b.writeByte(13);
                case 't'.code: b.writeByte(9);
                case "'".code, '"'.code, '\\'.code: b.writeByte(c);
                case '/'.code: b.writeByte(c);
                case "u".code:
                    var code;
                    try {
                        code = s.readString(4);
                    } catch( e : Dynamic ) {
                        line = old;
                        throw EUnterminatedString;
                    }
                    var k = 0;
                    for( i in 0...4 ) {
                        k <<= 4;
                        var char = code.charCodeAt(i);
                        switch( char ) {
                        case 48,49,50,51,52,53,54,55,56,57: // 0-9
                            k += char - 48;
                        case 65,66,67,68,69,70: // A-F
                            k += char - 55;
                        case 97,98,99,100,101,102: // a-f
                            k += char - 87;
                        default:
                            throw EInvalidChar(char);
                        }
                    }
                    // encode k in UTF8
                    if( k <= 0x7F )
                        b.writeByte(k);
                    else if( k <= 0x7FF ) {
                        b.writeByte( 0xC0 | (k >> 6));
                        b.writeByte( 0x80 | (k & 63));
                    } else {
                        b.writeByte( 0xE0 | (k >> 12) );
                        b.writeByte( 0x80 | ((k >> 6) & 63) );
                        b.writeByte( 0x80 | (k & 63) );
                    }
                */
                default:
                    // here we assume all strings are output with
                    // double quotes, so don't escape the \ for them.
                    // remove this check if enabling block above
                    if(c != '"'.code)
                        b.writeByte('\\'.code);
                    b.writeByte(c);
                }
            } else if( c == '\\'.code )
                esc = true;
            else if( c == until )
                break;
            else {
//              if( c == '\n'.code ) line++;
                b.writeByte(c);
            }
        }
        return b.getBytes().toString();
    }

    public function end() {
        Debug.openDebug("function end()", line, true);
        while( ParserUtils.opt(this, TSemicolon) ) {
        }
        Debug.closeDebug("function end()", line);
    }
}
