/*
 * Copyright (c) 2011, Russell Weir
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

import Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

/**
 * Collection of functions that just have no real way to be compatible in Haxe 
 **/
class Compat {

	/* According to Adobe:
	 * The result is limited to six possible string values: 
	 *		boolean, function, number, object, string, and xml.
	 * If you apply this operator to an instance of a user-defined class,
	 * the result is the string object.
	 *
	 * TODO: TUnknown returns "undefined" on top of this. Not positive on this
	 */
	public static function typeof(v:Dynamic) : String {
		return
		switch(Type.typeof(v)) {
		case TUnknown: "undefined";
		case TObject: "object";
		case TNull: "object";
		case TInt: "number";
		case TFunction: "function";
		case TFloat: "number";
		case TEnum(e): "object";
		case TClass(c):
			switch(Type.getClassName(c)) {
			case "String": "string";
			case "Xml": "xml";
			case "haxe.xml.Fast": "xml";
			default: "object";
			}
		case TBool: "boolean";
		};
	}

	/**
	 * Converts a typed expression into a Float.
	 */
	@:macro public static function parseFloat(e:Expr) : Expr {
		var _ = function (e:ExprDef) return { expr: e, pos: Context.currentPos() };
		switch (Context.typeof(e)) {
			case TInst(t,params): 
				var castToFloat = _(ECast(e, TPath({name:"Float", pack:[], params:[], sub:null})));
				if (t.get().pack.length == 0)
					switch (t.get().name) {
						case "Int": return castToFloat;
						case "Float": return castToFloat;
						default:
					}
			default:
		}
		return _(ECall( _(EField( _(EConst(CType("Std"))), "parseFloat")), [_(ECall( _(EField( _(EConst(CType("Std"))), "string")), [e]))]));
	}

	/**
	 * Converts a typed expression into an Int.
	 */
	@:macro public static function parseInt(e:Expr) : Expr {
		var _ = function (e:ExprDef) return { expr: e, pos: Context.currentPos() };
		switch (Context.typeof(e)) {
			case TInst(t,params): 
				if (t.get().pack.length == 0)
					switch (t.get().name) {
						case "Int": return _(ECast(e, TPath({name:"Int", pack:[], params:[], sub:null})));
						case "Float": return _(ECall( _(EField( _(EConst(CType("Std"))), "int")), [_(ECast(e, TPath({name:"Float", pack:[], params:[], sub:null})))]));
						default:
					}
			default:
		}
		return _(ECall( _(EField( _(EConst(CType("Std"))), "parseInt")), [_(ECall( _(EField( _(EConst(CType("Std"))), "string")), [e]))]));
	}
}
