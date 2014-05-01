package as3hx;

enum Error {
    EInvalidChar( c : Int );
    EUnexpected( s : String );
    EUnterminatedString;
    EUnterminatedComment;
    EUnterminatedXML;
}
