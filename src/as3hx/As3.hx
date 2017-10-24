package as3hx;

enum Const {
    CInt( v : String );
    CFloat( f : String );
    CString( s : String );
}

typedef Metadata = { name : String, args : Array<{ name : String, val : Expr }> };

enum Expr {
    EConst( c : Const );
    EIdent( v : String );
    EVars( vars : Array<{ name : String, t : Null<T>, val : Null<Expr> }> );
    EParent( e : Expr );
    EBlock( e : Array<Expr> );
    EField( e : Expr, f : String );
    EBinop( op : String, e1 : Expr, e2 : Expr, newLineAfterOp : Bool );
    EUnop( op : String, prefix : Bool, e : Expr );
    ECall( e : Expr, params : Array<Expr> );
    EIf( cond : Expr, e1 : Expr, ?e2 : Expr );
    ETernary( cond : Expr, e1 : Expr, ?e2 : Expr );
    EWhile( cond : Expr, e : Expr, doWhile : Bool );
    EFor( inits : Array<Expr>, conds : Array<Expr>, incrs : Array<Expr>, e : Expr );
    EForEach( ev : Expr, e : Expr, block : Expr );
    EForIn( ev : Expr, e : Expr, block : Expr );
    EBreak( ?label : String );
    EContinue;
    EFunction( f : Function, name : Null<String> );
    EReturn( ?e : Expr );
    EArray( e : Expr, index : Expr );
    EArrayDecl( e : Array<Expr> );
    ENew( t : T, params : Array<Expr> );
    EThrow( e : Expr );
    ETry( e : Expr, catches : Array<{ name : String, t : Null<T>, e : Expr }> );
    EObject( fl : Array<{ name : String, e : Expr }> );
    ERegexp( str : String, opts : String );
    ESwitch( e : Expr, cases : Array<SwitchCase>, def : Null<SwitchDefault>);
    EVector( t : T ); // Vector.<T> call
    EE4XDescend( e1 : Expr, e2 : Expr ); // e1..childNode
    EE4XAttr( e1 : Expr, e2 : Expr ); // e1.@e2, e1.@["foo"], e1["@foo"]
    EE4XFilter( e1 : Expr, e2 : Expr ); // e1.(weight > 300) search
    EXML( s : String );
    ELabel( name : String );
    ETypeof( e : Expr );
    ECommented(s : String, isBlock:Bool, isTail:Bool, e : Expr);
    EMeta( m : Metadata );
    ETypedExpr( e : Expr, t : Null<T> );
    EDelete( e : Expr );
    ECondComp( v : String, e : Expr, e2 : Expr );
    ENL( e : Expr);
    EImport(v : Array<String>);
}

enum T {
    TStar;
    TVector( t : T );
    TPath( p : Array<String> );
    TComplex( e : Expr );
    TDictionary( k : T, v :T );
    TFunction(p:Array<T>);
}

enum FieldKind {
    FVar( t : Null<T>, val : Null<Expr> );
    FFun( f : Function );
    FComment;
}

typedef Function = {
    var args : Array<{ name : String, t : Null<T>, val : Null<Expr>, exprs:Array<Expr> }>;
    var varArgs : Null<String>;
    var ret : FunctionRet;
    var expr : Null<Expr>;
}

typedef ClassField = {
    var meta : Array<Expr>;
    var kwds : Array<String>;
    var name : String;
    var kind : FieldKind;
    var condVars : Array<String>;
}

typedef ClassDef = {
    var meta : Array<Expr>;
    var kwds : Array<String>;
    var imports : Array<Array<String>>;
    var isInterface : Bool;
    var name : String;
    var fields : Array<ClassField>;
    var implement : Array<T>;
    var extend : Null<T>;
    var inits : Array<Expr>;
}

typedef FunctionDef = {
    var meta : Array<Expr>;
    var kwds : Array<String>;
    var name : String;
    var f : Function;
}

typedef FunctionRet = {
    var t : Null<T>;
    var exprs : Array<Expr>;
}

typedef NamespaceDef = {
    var meta : Array<Expr>;
    var kwds : Array<String>;
    var name : String;
    var value : String;
}

typedef SwitchCase = {
    var val : Expr;
    var el : Array<Expr>;
    var meta : Array<Expr>;
}

typedef SwitchDefault = {
    var el : Array<Expr>;
    var meta : Array<Expr>;
    @:optional var vals : Array<Expr>;
    @:optional var before : SwitchCase;
}

enum Definition {
    CDef( c : ClassDef );
    FDef( f : FunctionDef );
    NDef( n : NamespaceDef );
}

typedef Program = {
    var header : Array<Expr>; // will hold only comments
    var pack : Array<String>;
    var imports : Array<Array<String>>;
    var typesSeen : Array<T>;
    var typesDefd : Array<Dynamic>;
    var genTypes : Array<GenType>; // will hods types generated for some class vars
    var defs : Array<Definition>;
    var footer : Array<Expr>; // will hold trailing comments
}

typedef GenType = {
    var name : String;
    var fieldName : String;
    var fields : Array<{ name : String, t : String }>;
}
