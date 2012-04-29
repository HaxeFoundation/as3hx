/*
 * Copyright (c) 2008-2011, Nicolas Cannasse, Russell Weir, Niel Drummond
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package as3hx;
import as3hx.As3;

enum Error {
	EInvalidChar( c : Int );
	EUnexpected( s : String );
	EUnterminatedString;
	EUnterminatedComment;
	EUnterminatedXML;
}

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
	TNL;
	TCommented( s : String, isBlock:Bool, t : Token );
}

/**
 * ...
 * @author Nicolas Cannasse
 * @author Russell Weir
 */
class Parser {

	// config / variables
	public var line : Int;
	public var pc : Int;
	public var identChars : String;
	public var opPriority : Hash<Int>;
	public var unopsPrefix : Array<String>;
	public var unopsSuffix : Array<String>;

	// implementation
	var input : haxe.io.Input;
	var char : Int;
	var ops : Array<Bool>;
	var idents : Array<Bool>;
	var tokens : haxe.FastList<Token>;
	var path : String;
	var filename : String;
	var cfg : Config;

	public function new(config:Config) {
		line = 1;
		pc = 1;
		identChars = "$ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";
		var p = [
			["%", "*", "/"],
			["+", "-"],
			["<<", ">>", ">>>"],
			[">", "<", ">=", "<="],
			["==", "!="],
			["&"],
			["^"],
			["|"],
			["&&"],
			["||"],
			["?:"],
			["=", "+=", "-=", "*=", "%=", "/=", "<<=", ">>=", ">>>=", "&=", "^=", "|=", "&&=", "||="]
		];
		opPriority = new Hash();
		for( i in 0...p.length )
			for( op in p[i] )
				opPriority.set(op, i);
		unopsPrefix = ["!", "++", "--", "-", "+", "~"];
		for( op in unopsPrefix )
			if( !opPriority.exists(op) )
				opPriority.set(op, -1);
		unopsSuffix = ["++", "--"];
		this.cfg = config;
	}

	public function parseString( s : String, path : String, filename : String ) {
		line = 1;
		this.path = path;
		this.filename = filename;
		return parse( new haxe.io.StringInput(s) );
	}

	public function parse( s : haxe.io.Input ) {
		char = 0;
		input = s;
		ops = new Array();
		idents = new Array();
		tokens = new haxe.FastList<Token>();
		for( op in opPriority.keys() )
			for( i in 0...op.length )
				ops[op.charCodeAt(i)] = true;
		for( i in 0...identChars.length )
			idents[identChars.charCodeAt(i)] = true;
		return parseProgram();
	}

	public function parseInclude(p:String, call:Void->Void) {
		var oldInput = input;
		var oldLine = line;
		var oldPath = path;
		var oldFilename = filename;
		var file = path + "/" + p;
		var parts = file.split("/");
		filename = parts.pop();
		path = parts.join("/");
		openDebug("Parsing included file " + file + "\n");
		if (!neko.FileSystem.exists(file)) throw "Error: file '" + file + "' does not exist, at " + oldLine;
		var content = neko.io.File.getContent(file);
		line = 1;
		input = new haxe.io.StringInput(content);
		try {
			call();
		} catch(e:Dynamic) {
			throw "Error " + e + " while parsing included file " + file + " at " + oldLine;
		}
		input = oldInput;
		line = oldLine;
		path = oldPath;
		filename = oldFilename;
		closeDebug("Finished parsing file " + file);
	}
	
	inline function add(tk) {
		tokens.add(tk);
	}

	function uncomment(tk) {
		if(tk == null)
			return null;
		return switch(tk) {
		case TCommented(s,b,e):
			uncomment(e);
		default:
			tk;
		}
	}

	function uncommentExpr(e) {
		if(e == null)
			return null;
		return switch(e) {
		case ECommented(s,b,t,e2):
			uncommentExpr(e2);
		default:
			e;
		}
	}	

	/**
	 * Takes a token that may be a comment and returns
	 * an array of tokens that will have the comments
	 * at the beginning
	 **/
	function explodeComment(tk) : Array<Token> {
		var a = [];
		var f : Token->Void = null;
		f = function(t) {
			if(t == null)
				return;
			switch(t) {
			case TCommented(s,b,t2):
				a.push(TCommented(s,b,null));
				f(t2);
			default:
				a.push(t);
			}
		}
		f(tk);
		return a;
	}

	function explodeCommentExpr(e) : Array<Expr> {
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
	function tailComment(e:Expr, tk:Token) : Expr {
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
	function makeECommented(ctk:Token, e:Expr) : Expr {
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
	 * Checks that the next token is of type 'tk', returning
	 * true if so, and the token is consumed. If keepComments
	 * is set, all the comments will be pushed onto the token
	 * stack along with the next token after 'tk'.
	 **/
	function opt(tk,keepComments:Bool=false) : Bool {
		var t = token();
		var tu = uncomment(t);
		dbgln(Std.string(t) + " to " + Std.string(tu) + " ?= " + Std.string(tk));
		if( Type.enumEq(tu, tk) ) {
			if(keepComments) {
				var ta = explodeComment(t);
				// if only 'tk' exists in ta, we're done
				if(ta.length < 2) return true;
				ta.pop();
				t = token();
				var l = ta.length - 1;
				while(l >= 0) {
					switch(ta[l]) {
					case TCommented(s,b,t2):
						if(t2 != null) throw "Assert error";
						t = TCommented(s,b,t);
					default: throw "Assert error";
					}
					l--;
				}
				add(t);
			}
			return true;
		}
		add(t);
		return false;
	}

	/**
	 * Version of opt that will search for tk, and if it is the next token,
	 * all the comments before it will be pushed to array 'cmntOut'
	 **/
	function opt2(tk, cmntOut : Array<Expr>) : Bool {
		var t = token();
		var tu = uncomment(t);
		dbgln(Std.string(t) + " to " + Std.string(tu) + " ?= " + Std.string(tk));
		if( ! Type.enumEq(tu, tk) ) {
			add(t);
			return false;
		}
		switch(t) {
			case TCommented(_,_,_):
				cmntOut.push(makeECommented(t, null));
			default:
		}
		return true;
	}

	/**
	 * Ensures the next token (ignoring comments) is 'tk'.
	 * @return array of comments before 'tk'
	 **/
	function ensure(tk) : Array<Token> {
		var t = token();
		var tu = uncomment(t);
		if( !Type.enumEq(tu, tk) )
			unexpected(tu);
		var ta = explodeComment(t);
		ta.pop();
		return ta;
	}
	
	function parseProgram() : Program {
		dbgln("parseProgram()");
		var pack = [];
		var header:Array<Expr> = [];
		// look for first 'package'
		var tk = token();
		var a = explodeComment(tk);
		for(t in a) {
			switch(t) {
			case TId(s):
				if( s != "package" )
					unexpected(t);
				if( opt(TBrOpen) )
					pack = []
				else {
					pack = parsePackageName();
					ensure(TBrOpen);
				}
			case TCommented(s,b,t):
				if(t != null) throw "Assert error " + tokenString(t);
				header.push(ECommented(s,b,false,null));
			default:
				unexpected(t);
			}
		}

		// parse package
		var imports = [];
		var inits : Array<Expr> = [];
		var defs = [];
		var meta : Array<Expr> = [];
		var closed = false;
		var inNamespace = false;

		var pf : Bool->Void = null;
		pf = function(included:Bool) {
		while( true ) {
			var tk = token();
			switch( tk ) {
			case TBrClose: // }
				if( inNamespace ) {
					inNamespace = false;
					continue;
				}
				else if( !closed ) {
					closed = true;
					continue;
				}
			case TBrOpen: // {
				if(inNamespace)
					continue;
				// private classes outside of first package {}
				if( !closed ) {
					unexpected(tk);
				}
				closed = false;
				continue;
			case TEof:
				if( included )
					return;
				if( closed )
					break;
			case TBkOpen: // [
				add(tk);
				meta.push(parseMetadata());
				continue;
			case TId(id):
				switch( id ) {
				case "import":
					var impt = parseImport();
					if (impt.length > 0) imports.push(impt);
					end();
					continue;
				case "use":
					parseUse();
					continue;
				case "public", "class", "internal", "interface", "dynamic", "function":
					inNamespace = false;
					add(tk);
					var d = parseDefinition(meta);
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
					tk = token();
					switch(tk) {
						case TConst(c):
							switch(c) {
								case CString(path):
									var oldClosed = closed;
									closed = false;
									parseInclude(path,callback(pf, true));
									end();
									closed = oldClosed;
								default:
									unexpected(tk);
							}
						default:
							unexpected(tk);
					}
					continue;
				default:
					if(opt(TNs)) {
						var ns : String = id + "::";
						var t = uncomment(token());
						switch(t) {
							case TId(id2):
								ns += id2;
							default:
								unexpected(t);
						}
						inNamespace = true;
						meta.push(ECommented("/* AS3HX WARNING : Discarded namespace "+ns+"*/",true,false,null));
						continue;
					} else if(opt(TSemicolon)) {
						// class names without an import statement used
						// for forcing compilation and linking.
						inits.push(EIdent(id));
						continue;
					} else {
						unexpected(tk);
					}
				}
			case TSemicolon:
				continue;
			case TCommented(s,b,t):
				var t = uncomment(tk);
				switch(t) {
				case TBkOpen:
					add(t);
					meta.push(makeECommented(tk, parseMetadata()));
					continue;
				default:
					add(t);
					meta.push(makeECommented(tk, null));
				}
				continue;
			default:
			}
			unexpected(tk);
		}
		};
		pf(false);
		if( !closed )
			unexpected(TEof);

		return {
			header : header,
			pack : pack,
			imports : imports,
			defs : defs,
			footer : meta,
		};
	}
	
	function parseUse() {
		ensure(TId("namespace"));
		var ns = this.id();
		end();
	}

	function parseImport() {
		dbg("parseImport()");
		var a = [id()];
		while( true ) {
			var tk = token();
			switch( tk ) {
			case TDot:
				tk = token();
				switch(tk) {
				case TId(id): 
					if (id == "getQualifiedClassName") return [];
					if (id == "getQualifiedSuperclassName") return [];
					if (id == "getTimer") return [];
					if (id == "getDefinitionByName") return [];
					// TODO: this is flash.utils.Proxy need to create a compat class
					// http://blog.int3ractive.com/2010/05/using-flash-proxy-class.html
					// Will put this into the nme namespace for now, and merge it
					// to nme if it works
					if (id == "flash_proxy") return ["nme","utils","Proxy"];
					// import __AS3__.vec.Vector;
					if (id == "Vector" && a[0] == "__AS3__") return [];
					a.push(id);
				case TOp(op):
					if( op == "*" ) {
						a.push(op);
						break;
					}
					unexpected(tk);
				default: unexpected(tk);
				}
			case TCommented(s,b,t):
				add(t);
			default:
				add(tk);
				break;
			}
		}
		dbgln(" -> " + a);
		return a;
	}

	function parseMetadata() : Expr {
		dbg("parseMetadata()");
		ensure(TBkOpen);
		var name = id();
		var args = [];
		if( opt(TPOpen) )
			while( !opt(TPClose) ) {
				var n = null;
				switch(peek()) {
				case TId(i):
					n = id();
					if(!opt(TOp("="))) {
						args.push( { name : null, val : EIdent(n) } );
						continue;
					}
				case TConst(_):
				default:
					unexpected(peek());
				}
				var e = parseExpr();
				args.push( { name : n, val :e } );
				opt(TComma);
			}
		ensure(TBkClose);
		dbgln(" -> " + { name : name, args : args });
		return EMeta({ name : name, args : args });
	}
	
	function parseDefinition(meta:Array<Expr>) : Definition {
		dbgln("parseDefinition()" + meta);
		var kwds = [];
		while( true ) {
			var id = id();
			switch( id ) {
			case "public", "internal", "final", "dynamic": kwds.push(id);
			case "use":
				parseUse();
				continue;
			case "class":
				return CDef(parseClass(kwds,meta,false));
			case "interface":
				var c = parseClass(kwds,meta,true);
				return CDef(c);
			case "function":
				// Writer does not have this implemented
				trace("ERROR: Not implemented");
				unexpected(TId(id));
				return FDef(parseFunDef(kwds, meta));
			case "namespace":
				return NDef(parseNsDef(kwds, meta));
			default: unexpected(TId(id));
			}
		}
		return null;
	}
	
	function parseFunDef(kwds, meta) : FunctionDef {
		dbgln("parseFunDef()");
		var fname = id();
		var f = parseFun();
		return {
			kwds : kwds,
			meta : meta,
			name : fname,
			f : f,
		};
	}
	
	function parseNsDef(kwds, meta) : NamespaceDef {
		dbgln("parseNsDef()");
		var name = id();
		var value = null;
		if( opt(TOp("=")) ) {
			var t = token();
			value = switch( t ) {
			case TConst(c):
				switch( c ) {
				case CString(str): str;
				default: unexpected(t);
				}
			default:
				unexpected(t);
			};
		}
		return {
			kwds : kwds,
			meta : meta,
			name : name,
			value : value,
		};
	}
	
	function parseClass(kwds,meta:Array<Expr>,isInterface:Bool) : ClassDef {
		var cname = id();
		var classMeta = meta;
		var imports = [];
		meta = [];
		openDebug("parseClass("+cname+")", true);
		var fields = new Array();
		var impl = [], extend = null, inits = [];
		while( true ) {
			if( opt(TId("implements")) ) {
				impl.push(parseType());
				while( opt(TComma) )
					impl.push(parseType());
				continue;
			}
			if( opt(TId("extends")) ) {
				if(!isInterface) {
					extend = parseType();
				}
				else {
					impl.push(parseType());
					while( opt(TComma) )
						impl.push(parseType());
				}
				continue;
			}
			break;
		}
		ensure(TBrOpen);

		var pf : Bool->Void = null;

		pf = function(included:Bool) {
		while( true ) {
			// check for end of class
			if( opt2(TBrClose, meta) ) break;
			var kwds = [];
			// parse all comments and metadata before next field
			while( true ) {
				var tk = token();
				switch( tk ) {
				case TSemicolon:
					continue;
				case TBkOpen:
					add(tk);
					meta.push(parseMetadata());
					continue;
				case TCommented(s,b,t):
					var t = uncomment(tk);
					switch(t) {
					case TBkOpen:
						add(t);
						meta.push(makeECommented(tk, parseMetadata()));
						continue;
					default:
						add(tk);
						//meta.push(ECommented(s,b,false,null));
						break;
					}
					continue;
				case TEof:
					if(included)
						return;
					add(tk);
					break;
				default:
					add(tk);
					break;
				}
			}

			while( true )  {
				var t = token();
				switch( t ) {
				case TId(id):
					switch( id ) {
					case "public", "static", "private", "protected", "override", "internal", "final": kwds.push(id);
					case "const":
						kwds.push(id);
						do {
							fields.push(parseClassVar(kwds, meta));
							meta = [];
						} while( opt(TComma) );
						end();
						break;
					case "var":
						do {
							fields.push(parseClassVar(kwds, meta));
							meta = [];
						} while( opt(TComma) );
						end();
						break;
					case "function":
						fields.push(parseClassFun(kwds, meta));
						meta = [];
						break;
					case "import":
						var impt = parseImport();
						if (impt.length > 0) imports.push(impt);
						end();
						break;
					case "use":
						parseUse();
						break;
					case "include":
						t = token();
						switch(t) {
							case TConst(c):
								switch(c) {
									case CString(path):
										parseInclude(path,callback(pf, true));
										end();
									default:
										unexpected(t);
								}
							default:
								unexpected(t);
						}
					default:
						kwds.push(id);
					}
				case TCommented(s,b,t):
					add(t);
					meta.push(ECommented(s,b,false,null));
				case TEof:
					if(included)
						return;
					add(t);
					while( kwds.length > 0 )
						add(TId(kwds.pop()));
					inits.push(parseExpr());
					end();
				default:
					add(t);
					while( kwds.length > 0 )
						add(TId(kwds.pop()));
					inits.push(parseExpr());
					end();
					break;
				}
			}
		}
		};
		pf(false);
			
		//trace("*** " + meta);
		for(m in meta) {
			switch(m) {
			case ECommented(s,b,t,e):
				if(uncommentExpr(m) != null)
					throw "Assert error: " + m;
				var a = explodeCommentExpr(m);
				for(i in a) {
					switch(i) {
						case ECommented(s,b,t,e):
							fields.push({name:null, meta:[ECommented(s,b,false,null)], kwds:[], kind:FComment});
						default:
							throw "Assert error: " + i;
					}
				}
			default:
				throw "Assert error: " + m;
			}
		}
		closeDebug("parseClass("+cname+") finished");
		return {
			meta : classMeta,
			kwds : kwds,
			imports : imports,
			isInterface : isInterface,
			name : cname,
			fields : fields,
			implement : impl,
			extend : extend,
			inits : inits,
		};
	}
	
	function parseType() {
		dbgln("parseType()");
		// this is a ugly hack in order to fix lexer issue with "var x:*=0"
		var tmp = opPriority.get("*=");
		opPriority.remove("*=");
		if( opt(TOp("*")) ) {
			opPriority.set("*=",tmp);
			return TStar;
		}
		opPriority.set("*=",tmp);

		// for _i = new (obj as Class)() as DisplayObject;
		switch(peek()) {
		case TPOpen: return TComplex(parseExpr());
		default:
		}

		var t = id();
		if( t == "Vector" ) {
			ensure(TDot);
			ensure(TOp("<"));
			var t = parseType();
			switch( peek() ) {
			case TOp(s):
				token();
				var tl = [];
				while( s.charAt(0) == ">" ) {
					tl.unshift(">");
					s = s.substr(1);
				}
				if( s.length > 0 )
					tl.unshift(s);
				for( op in tl )
					add(TOp(op));
			default:
			}
			ensure(TOp(">"));
			return TVector(t);
		} 

		var a = [t];
		var tk = token();
		while( true ) {
			//trace(Std.string(tk));
			switch( tk ) {
			case TDot:
				tk = token();
				switch(uncomment(tk)) {
				case TId(id): a.push(id);
				default: unexpected(uncomment(tk));
				}
			case TCommented(s,b,t):
				tk = t;
				continue;
			default:
				add(tk);
				break;
			}
			tk = token();
		}
		return TPath(a);
	}

	function parseClassVar(kwds,meta) : ClassField {
		openDebug("parseClassVar(");
		var name = id();
		dbgln(name + ")",false);
		var t = null, val = null;
		if( opt(TColon) )
			t = parseType();
		if( opt(TOp("=")) )
			val = parseExpr();
		var rv = {
			meta : meta,
			kwds : kwds,
			name : StringTools.replace(name, "$", "__DOLLAR__"),
			kind : FVar(t, val),
		};
		closeDebug("parseClassVar -> " + rv);
		return rv;
	}
	
	function parseClassFun(kwds:Array<String>,meta) : ClassField {
		openDebug("parseClassFun(");
		var name = id();
		if( name == "get" || name == "set" ) {
			kwds.push(name);
			name = id();
		}
		dbgln(Std.string(kwds) + " " + name + ")", false);
		var f = parseFun();
		end();
		closeDebug("end parseClassFun()");
		return {
			meta : meta,
			kwds : kwds,
			name : StringTools.replace(name, "$", "__DOLLAR__"),
			kind : FFun(f),
		};
	}
	
	function parseFun() : Function {
		openDebug("parseFun()",true);
		var f = {
			args : [],
			varArgs : null,
			ret : null,
			expr : null,
		};
		ensure(TPOpen);
		if( !opt(TPClose) )
			while( true ) {
				if( opt(TDot) ) {
					ensure(TDot);
					ensure(TDot);
					f.varArgs = id();
					if( opt(TColon) )
						ensure(TId("Array"));
					ensure(TPClose);
					break;
				}
				var name = id(), t = null, val = null;
				if( opt(TColon) )
					t = parseType();
				if( opt(TOp("=")) )
					val = parseExpr();
				f.args.push( { name : name, t : t, val : val } );
				//dbgln(Std.string({ name : name, t : t, val : val }));
				if( opt(TPClose) )
					break;
				ensure(TComma);
			}
		if( opt(TColon) )
			f.ret = parseType();
		if( peek() == TBrOpen ) {
			f.expr = parseExpr(true);
			switch(f.expr) {
			case EObject(fl):
				if(fl.length == 0) {
					f.expr = EBlock([]);
				} else {
					throw "unexpected " + Std.string(f.expr);
				}
			case EBlock(_):
			default:
				throw "unexpected " + Std.string(f.expr);
			}
		}
		closeDebug("end parseFun()");
		return f;
	}
	
	function parsePackageName() {
		dbg("parsePackageName()");
		var a = [id()];
		while( true ) {
			var tk = token();
			switch( tk ) {
			case TDot:
				tk = token();
				switch(tk) {
				case TId(id): a.push(id);
				default: unexpected(tk);
				}
			default:
				add(tk);
				break;
			}
		}
		dbgln(" -> " + a);
		return a;
	}

	function unexpected( tk ) : Dynamic {
		throw EUnexpected(tokenString(tk));
		return null;
	}

	function end() {
		openDebug("function end()", true);
		while( opt(TSemicolon) ) {
		}
		closeDebug("function end()");
	}
	
	function parseFullExpr() {
		dbgln("parseFullExpr()");
		var e = parseExpr();
		if( opt(TColon) ) {
			switch( e ) {
			case EIdent(l): e = ELabel(l);
			default: add(TColon);
			}
		}
		if( !opt(TComma) )
			end();
		return e;
	}

	function parseObject() {
		openDebug("parseObject()", true);
		var fl = new Array();

		while( true ) {
			var tk = token();
			var id = null;
			switch( uncomment(tk) ) {
			case TId(i): id = i;
			case TConst(c):
				switch( c ) {
				case CInt(v): if( v.charCodeAt(1) == "x".code ) id = Std.string(Std.parseInt(v)) else id = v;
				case CFloat(f): id = f;
				case CString(s): id = s;
				}
			case TBrClose:
				break;
			default:
				unexpected(tk);
			}
			ensure(TColon);
			fl.push({ name : id, e : parseExpr() });
			tk = token();
			switch(tk) {
			case TCommented(s,b,e):
				var o = fl[fl.length-1];
				o.e = tailComment(o.e, tk);
			default:
			}
			switch( uncomment(tk) ) {
			case TBrClose:
				break;
			case TComma:
			default:
				unexpected(tk);
			}
		}
		var rv = parseExprNext(EObject(fl));
		closeDebug("parseObject() -> " + rv);
		return rv;
	}

	function parseExpr(funcStart:Bool=false) : Expr {
		var tk = token();
		dbgln("parseExpr("+tk+")");
		switch( tk ) {
		case TId(id):
			var e = parseStructure(id);
			if( e == null )
				e = EIdent(id);
			return parseExprNext(e);
		case TConst(c):
			return parseExprNext(EConst(c));
		case TPOpen:
			var e = parseExpr();
			ensure(TPClose);
			return parseExprNext(EParent(e));
		case TBrOpen:
			tk = token();
			dbgln("parseExpr: "+tk);
			switch( tk ) {
			case TBrClose:
				if(funcStart) return EBlock([]);
				return parseExprNext(EObject([]));
			case TId(_),TConst(_):
				var tk2 = token();
				add(tk2);
				add(tk);
				switch( tk2 ) {
				case TColon:
					return parseExprNext(parseObject());
				default:
				}
			default:
				add(tk);
			}
			var a = new Array();
			while( !opt(TBrClose) ) {
				var e = parseFullExpr();
				a.push(e);
			}
			return EBlock(a);
		case TOp(op):
			if( op.charAt(0) == "/" ) {
				var str = op.substr(1);
				var c = nextChar();
				while( c != "/".code ) {
					str += String.fromCharCode(c);
					c = nextChar();
				}
				c = nextChar();
				var opts = "";
				while( c >= "a".code && c <= "z".code ) {
					opts += String.fromCharCode(c);
					c = nextChar();
				}
				pushBackChar(c);
				return parseExprNext(ERegexp(str, opts));
			}
			var found;
			for( x in unopsPrefix )
				if( x == op )
					return makeUnop(op, parseExpr());
			if( op == "<" )
				return EXML(readXML());
			return unexpected(tk);
		case TBkOpen:
			var a = new Array();
			tk = token();
			while( tk != TBkClose ) {
				add(tk);
				a.push(parseExpr());
				tk = token();
				if( tk == TComma )
					tk = token();
			}
			return parseExprNext(EArrayDecl(a));
		case TCommented(s,b,t):
			add(t);
			return ECommented(s,b,false,parseExpr());
		default:
			return unexpected(tk);
		}
	}

	function makeUnop( op, e ) {
		return switch( e ) {
		case EBinop(bop,e1,e2): EBinop(bop,makeUnop(op,e1),e2);
		default: EUnop(op,true,e);
		}
	}

	function makeBinop( op, e1, e ) {
		return switch( e ) {
		case EBinop(op2, e2, e3):
			var p1 = opPriority.get(op);
			var p2 = opPriority.get(op2);
			if( p1 < p2 || (p1 == p2 && op.charCodeAt(op.length-1) != "=".code) )
				EBinop(op2,makeBinop(op,e1,e2),e3);
			else
				EBinop(op,e1,e);
		default: EBinop(op,e1,e);
		}
	}

	function parseStructure(kwd) : Expr {
		dbgln("parseStructure("+kwd+")");
		return switch( kwd ) {
		case "if":
			ensure(TPOpen);
			var cond = parseExpr();
			ensure(TPClose);
			var e1 = parseExpr();
			end();
			var e2 = if( opt(TId("else"), true) ) parseExpr() else null;
			EIf(cond,e1,e2);
		case "var", "const":
			var vars = [];
			while( true ) {
				var name = id(), t = null, val = null;
				if( opt(TColon) )
					t = parseType();
				if( opt(TOp("=")) )
					val = ETypedExpr(parseExpr(), t);
				vars.push( { name : name, t : t, val : val } );
				if( !opt(TComma) )
					break;
			}
			EVars(vars);
		case "while":
			ensure(TPOpen);
			var econd = parseExpr();
			ensure(TPClose);
			var e = parseExpr();
			EWhile(econd,e, false);
		case "for":
			if( opt(TId("each")) ) {
				ensure(TPOpen);
				var ev = parseExpr();
				switch(ev) {
					case EBinop(op, e1, e2):
						if(op == "in") {
							ensure(TPClose);
							return EForEach(e1, e2, parseExpr());
						}
						unexpected(TId(op));
					default:
						unexpected(TId(Std.string(ev)));
				}
			} else {
				ensure(TPOpen);
				var inits = [];
				if( !opt(TSemicolon) ) {
					var e = parseExpr();
					switch(e) {
						case EBinop(op, e1, e2):
							if(op == "in") {
								ensure(TPClose);
								return EForIn(e1, e2, parseExpr());
							}
						default:
					}
					if( opt(TComma) ) {
						inits = parseExprList(TSemicolon);
						inits.unshift(e);
					} else {
						ensure(TSemicolon);
						inits = [e];
					}
				}
				var conds = parseExprList(TSemicolon);
				var incrs = parseExprList(TPClose);
				EFor(inits, conds, incrs, parseExpr());
			}
		case "break":
			var label = switch( peek() ) {
			case TId(n): token(); n;
			default: null;
			};
			EBreak(label);
		case "continue": EContinue;
		case "else": unexpected(TId(kwd));
		case "function":
			var name = switch( peek() ) {
			case TId(n): token(); n;
			default: null;
			};
			EFunction(parseFun(),name);
		case "return":
			EReturn(if( peek() == TSemicolon ) null else parseExpr());
		case "new":
			if(opt(TOp("<"))) {
				// o = new <VectorType>[a,b,c..]
				var t = parseType();
				ensure(TOp(">"));
				if(peek() != TBkOpen)
					unexpected(peek());
				ECall(EVector(t), [parseExpr()]);
			} else {
				var t = parseType();
				// o = new (iconOrLabel as Class)() as DisplayObject
				var cc = switch (t) {
					case TComplex(e1) : 
						switch (e1) {
							case EBinop(op, e2, e3): 
								if (op == "as") {
									switch (e2) {
										case ECall(e4, a): 
											EBinop(op, ECall(EField(EIdent("Type"), "createInstance"), [e4, EArrayDecl(a)]), e3);
										default: 
									}
								} 
							default: 
						}
					default: 
				}
				if (cc != null) cc; else ENew(t,if( opt(TPOpen) ) parseExprList(TPClose) else []);
			}
		case "throw":
			EThrow( parseExpr() );
		case "try":
			var e = parseExpr();
			var catches = new Array();
			while( opt(TId("catch")) ) {
				ensure(TPOpen);
				var name = id();
				ensure(TColon);
				var t = parseType();
				ensure(TPClose);
				var e = parseExpr();
				catches.push( { name : name, t : t, e : e } );
			}
			ETry(e, catches);
		case "switch":
			ensure(TPOpen);
			var e = EParent(parseExpr());
			ensure(TPClose);
			var def = null, cl = [];
			ensure(TBrOpen);
			while( !opt(TBrClose) ) {
				if( opt(TId("default")) ) {
					ensure(TColon);
					def = parseCaseBlock();
				} else {
					ensure(TId("case"));
					var val = parseExpr();
					ensure(TColon);
					var el = parseCaseBlock();
					cl.push( { val : val, el : el } );
				}
			}
			ESwitch(e, cl, def);
		case "do":
			var e = parseExpr();
			ensure(TId("while"));
			var cond = parseExpr();
			EWhile(cond, e, true);
		case "typeof":
			var e = parseExpr();
			switch(e) {
			case EBinop(op, e1, e2):
				//if(op != "==" && op != "!=")
				//	unexpected(TOp(op));
			case EParent(e1):
			case EIdent(id):
			default:
				unexpected(TId(Std.string(e)));
			}
			ETypeof(e);
		case "getQualifiedClassName":
			ensure(TPOpen);
			var e = parseExpr();
			ensure(TPClose);
			ECall(EField(EIdent("Type"), "getClassName"), [e]);
		case "getQualifiedSuperclassName":
			ensure(TPOpen);
			var e = parseExpr();
			ensure(TPClose);
			ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getSuperClass"), [e])]);
		case "getDefinitionByName":
			ensure(TPOpen);
			var e = parseExpr();
			ensure(TPClose);
			ECall(EField(EIdent("Type"), "resolveClass"), [e]);
		case "getTimer":
			// TODO: this isn't quite right...
			ECall(EField(EIdent("Math"), "round"), [EBinop("/", ECall(EField(EIdent("haxe.Timer"), "getStamp"), []), EConst(CInt("1000")))]);
		default:
			null;
		}
	}

	function parseCaseBlock() {
		dbgln("parseCaseBlock()");
		var el = [];
		while( true ) {
			var tk = peek();
			switch( tk ) {
			case TId(id): if( id == "case" || id == "default" ) break;
			case TBrClose: break;
			default:
			}
			el.push(parseExpr());
			end();
		}
		return el;
	}
	
	function parseExprNext( e1 : Expr ) {
		var tk = token();
		dbgln("parseExprNext("+e1+") ("+tk+")");
		switch( tk ) {
		case TOp(op):
			for( x in unopsSuffix )
				if( x == op ) {
					if( switch(e1) { case EParent(_): true; default: false; } ) {
						add(tk);
						return e1;
					}
					return parseExprNext(EUnop(op,false,e1));
				}
			return makeBinop(op,e1,parseExpr());
		case TNs:
			switch(e1) {
			case EIdent(i):
				switch(i) {
					case "public":
						return parseExprNext(ECommented("/* AS3HX WARNING namespace modifier " + i + ":: */", true, false, null));
					default: 
				}
				tk = token();
				switch(tk) {
					case TId(id):
						switch(peek()) {
							case TBrOpen: // functions inside a namespace
								return parseExprNext(ECommented("/* AS3HX WARNING namespace modifier " + i + "::"+id+" */", true, false, null));
							default:
						}
					default:
				}
			default:
			}
			dbgln("WARNING parseExprNext unable to create namespace for " + Std.string(e1));
			add(tk);
			return e1;
		case TDot:
			tk = token();
			dbgln(Std.string(uncomment(tk)));
			var field = null;
			switch(uncomment(tk)) {
			case TId(id):
				field = StringTools.replace(id, "$", "__DOLLAR__");
				if( opt(TNs) )
					field = field + "::" + this.id();
			case TOp(op):
				if( op != "<" || switch(e1) { case EIdent(v): v != "Vector"; default: true; } ) unexpected(tk);
				var t = parseType();
				ensure(TOp(">"));
				return parseExprNext(EVector(t));
			case TPOpen:
				var e2 = parseE4XFilter();
				ensure(TPClose);
				return EE4XFilter(e1, e2);
			case TAt:
				var i : String = null;
				if(opt(TBkOpen)) {
					tk = token();
					switch(uncomment(tk)) {
						case TConst(c):
							switch(c) {
								case CString(s):
									i = s;
								default:
									unexpected(tk);
							}
						default:
							unexpected(tk);
					}
					ensure(TBkClose);
				}
				else
					i = id();
				return parseExprNext(EE4XAttr(e1, EIdent(i)));
			case TDot:
				var id = id();
				return parseExprNext(EE4XDescend(e1, EIdent(id)));
			default: unexpected(tk);
			}
			return parseExprNext(EField(e1,field));
		case TPOpen:
			return parseExprNext(ECall(e1,parseExprList(TPClose)));
		case TBkOpen:
			var e2 = parseExpr();
			tk = token();
			if( tk != TBkClose ) unexpected(tk);
			return parseExprNext(EArray(e1,e2));
		case TQuestion:
			var e2 = parseExpr();
			tk = token();
			if( tk != TColon ) unexpected(tk);
			var e3 = parseExpr();
			return ETernary(e1, e2, e3);
		case TId(s):
			switch( s ) {
			case "is": return makeBinop("is", e1, parseExpr());
			case "as": return makeBinop("as",e1,parseExpr());
			case "in": return makeBinop("in",e1,parseExpr());
			default:
				add(tk);
				return e1;
			}
		default:
			dbgln("parseExprNext stopped at " + tk);
			add(tk);
			return e1;
		}
	}

	function parseExprList( etk ) : Array<Expr> {
		dbgln("parseExprList()");

		var args = new Array();
		var f = function(t) {
			if(args.length == 0) return;
			args[args.length-1] = tailComment(args[args.length-1], t);
		}
		if( opt(etk) )
			return args;
		while( true ) {
			args.push(parseExpr());
			var tk = token();
			switch( tk ) {
			case TComma:
			case TCommented(_,_,_):
				var t = uncomment(tk);
				if(t == etk) {
					f(tk);
					break;
				}
				switch(t) {
				case TComma:
					f(tk);
				default:
					if( tk == etk ) break;
					unexpected(tk);
				}
			default:
				if( tk == etk ) break;
				unexpected(tk);
			}
		}
		return args;
	}

	function parseE4XFilter() : Expr {
		var tk = token();
		dbgln("parseE4XFilter("+tk+")");
		switch(tk) {
			case TAt:
				return parseE4XFilterNext(EIdent("@" + id()));
			case TId(id):
				var e = parseStructure(id);
				if( e != null )
					return unexpected(tk);
				return parseE4XFilterNext(EIdent(id));
			case TConst(c):
				return parseE4XFilterNext(EConst(c));
			case TCommented(s,b,t):
				add(t);
				return ECommented(s,b,false,parseE4XFilter());
			default:
				return unexpected(tk);
		}
	}

	function parseE4XFilterNext( e1 : Expr ) : Expr {
		var tk = token();
		dbgln("parseE4XFilterNext("+e1+") ("+tk+")");
		//parseE4XFilterNext(EIdent(groups)) (TBkOpen) [Parser 1506]
		switch( tk ) {
			case TOp(op):
				for( x in unopsSuffix )
					if( x == op )
						unexpected(tk);
				return makeBinop(op,e1,parseE4XFilter());
			case TPClose:
				dbgln("parseE4XFilterNext stopped at " + tk);
				add(tk);
				return e1;
			case TDot:
				tk = token();
				var field = null;
				switch(uncomment(tk)) {
					case TId(id):
						field = StringTools.replace(id, "$", "__DOLLAR__");
						if( opt(TNs) )
							field = field + "::" + this.id();
					case TAt:
						var i : String = null;
						if(opt(TBkOpen)) {
							tk = token();
							switch(uncomment(tk)) {
								case TConst(c):
									switch(c) {
										case CString(s):
											i = s;
										default:
											unexpected(tk);
									}
								default:
									unexpected(tk);
							}
							ensure(TBkClose);
						}
						else
							i = id();
						return parseE4XFilterNext(EE4XAttr(e1, EIdent(i)));
					default:
						unexpected(tk);
				}
				return parseE4XFilterNext(EField(e1,field));
			case TPOpen:
				return parseE4XFilterNext(ECall(e1,parseExprList(TPClose)));
			case TBkOpen:
				var e2 = parseExpr();
				tk = token();
				if( tk != TBkClose ) unexpected(tk);
				return parseE4XFilterNext(EArray(e1, e2));
			default:
				return unexpected( tk );
		}
	}
	
	function readXML() {
		dbgln("readXML()");
		var buf = new StringBuf();
		var input = input;
		buf.addChar("<".code);
		buf.addChar(this.char);
		this.char = 0;
		try {
			var prev = 0;
			while(true) {
				var c = input.readByte();
				if(c == "\n".code) line++;
				buf.addChar(c);
				if( c == ">".code ) break;
				prev = c;
			}
			if( prev == "/".code )
				return buf.toString();
			while(true) {
				var c = input.readByte();
				if(c == "\n".code) line++;
				if( c == "<".code ) {
					c = input.readByte();
					if(c == "\n".code) line++;
					if( c == "/".code ) {
						buf.add("</");
						break;
					}
					this.char = c;
					buf.add(readXML());
					continue;
				}
				buf.addChar(c);
			}
			while(true) {
				var c = input.readByte();
				if(c == "\n".code) line++;
				buf.addChar(c);
				if( c == ">".code ) break;
			}
			return buf.toString();
		} catch( e : haxe.io.Eof ) {
			throw EUnterminatedXML;
		}
	}
	
	function readString( until ) {
		dbgln("readString()");
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
//				if( c == '\n'.code ) line++;
				b.writeByte(c);
			}
		}
		return b.getBytes().toString();
	}

	function peek() : Token {
		if( tokens.isEmpty() )
			add(token());
		return uncomment(tokens.first());
	}
	
	function id() {
		var t = token();
		return switch( uncomment(t) ) {
		case TId(i): i;
		default: unexpected(t);
		}
	}
	
	function nextChar() {
		var c = 0;
		if( this.char == 0 ) {
			pc++;
			return try input.readByte() catch( e : Dynamic ) 0;
		}
		c = this.char;
		this.char = 0;
		return c;
	}

	function pushBackChar(c:Int) {
		if(this.char != 0)
			throw "Unexpected character pushed back";
		this.char = c;
	}

	function token() : Token {
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

	function constString( c ) {
		return switch(c) {
		case CInt(v): v;
		case CFloat(f): f;
		case CString(s): s; // TODO : escape + quote
		}
	}

	function tokenString( t ) {
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
		case TNL: "<newline>";
		case TCommented(s,b,t): s + " " + tokenString(t);
		}
	}

	static var lvl : Int = 0;

	function printDebug(s) {
		Sys.stderr().write(haxe.io.Bytes.ofString(s));
	}
	
	function openDebug(s:String,newline:Bool=false,?p:haxe.PosInfos) {
		#if debug
		var o = indent() + "(" + line + ") " + s  + " [Parser " + p.lineNumber + "]";
		if(newline)
			o = o + "\r\n";
		printDebug(o);
		lvl++;
		#end
	}

	function closeDebug(s,?p:haxe.PosInfos) {
		#if debug
		lvl--;
		printDebug(indent() + "(" + line + ") " + s + " [Parser " + p.lineNumber + "]\r\n");
		#end
	}

	function dbg(s,ind:Bool=true,?p:haxe.PosInfos) {
		#if debug
		var o = ind ? indent() : "";
		o += "(" + line + ") " + s + " [Parser " + p.lineNumber + "]";
		printDebug(o);
		#end
	}

	function dbgln(s,ind:Bool=true,?p:haxe.PosInfos) {
		#if debug
		var o = ind ? indent() : "";
		o += "(" + line + ") " + s + " [Parser " + p.lineNumber + "]\r\n";
		printDebug(o);
		#end
	}

	function indent()
	{
		var b = [];
		for (i in 0...lvl)
			b.push("\t");
		return b.join("");
	}
}
