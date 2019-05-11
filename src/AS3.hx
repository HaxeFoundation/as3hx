package;
import haxe.macro.Context;
import haxe.macro.Expr.ExprOf;
import haxe.macro.Expr;

/**
 * ...
 * @author
 */
class AS3 {

    public static function str(e:Dynamic):String {
        var t:Class<Dynamic> = Type.getClass(e);
        return t == null ? Std.string(e) : "[object " + Type.getClassName(t) + "]";
    }

    public static inline function asDynamic(e:Dynamic):Dynamic {
        return Std.is(e, haxe.Constraints.IMap) ? e : null;
    }

    public static inline function asDictionary(e:Dynamic):Dynamic {
        return Std.is(e, haxe.Constraints.IMap) ? untyped e : null;
    }

    #if openfl
    public static inline function asObject(e:Dynamic):openfl.utils.Object {
        return untyped e;
    }
    #end

    public static inline function asClass<T>(e:Dynamic, t:Class<T>):T {
        return Std.is(e, t) ? untyped e : null;
    }

    public static inline function asFloat(e:Dynamic):Float {
        return as3hx.Compat.parseFloat(e);
    }

    public static inline function asBool(e:Dynamic):Bool {
        #if (js || flash)
        return untyped Boolean(e);
        #else
        return e != false && e != null && e != 0 && !(Std.is(e, String) && e.length == 0);
        #end
    }


    public static inline function asArray(e:Dynamic):Array<Dynamic> {
        return Std.is(e, Array) ? untyped e : null;
    }

    public static function AS(e:Dynamic, type:Dynamic):Dynamic {
        return Std.is(e, type) ? e : null;
    }

    public static macro function as(e:Expr, type:Expr):Expr {
        return switch(type.expr) {
            case EConst(CIdent("Dictionary")): macro AS3.asDictionary($e);
            #if openfl
            case EConst(CIdent("Object")): macro AS3.asObject($e);
            #end
            case EConst(CIdent("Float")): macro AS3.asFloat($e);
            case EConst(CIdent("Bool")): macro AS3.asBool($e);
            default: macro AS3.asClass($e, $type);
        }
    }

    public static inline function hasOwnProperty(o:Dynamic, field:String):Bool {
        #if js
        var tmp;
        if(o == null) {
            return false;
        } else {
            var tmp1;
            if(untyped o.__properties__ && o.__properties__["get_" + field]) {
                return true;
            } else if (Reflect.hasField(o, field)) {
                return true;
            } else if (untyped o.prototype && untyped o.prototype.hasOwnProperty(field)) {
                return true;
            } else if (untyped o.__proto__ && untyped o.__proto__.hasOwnProperty(field)) {
                return true;
            } else {
                return false;
            }
        }
        #elseif flash
        if (o == null) {
            return null;
        } else {
            return untyped o.hasOwnProperty(field);
        }
        #else
        if (o == null) {
            return false;
        } else {
            return Type.getInstanceFields(Type.getClass(o)).indexOf(field) != -1;
        }
        #end
    }

    /* AS3.string(null) == null but Std.string(null) == "null" */
    public static function string(o:Dynamic):String {
        #if js
		untyped {
			if( o == null )
			    return null;//not "null"! this is for another purposes
			var t = __js__("typeof(o)");
			if( t == "function" && (js.Boot.isClass(o) || js.Boot.isEnum(o)) )
				t = "object";
			switch( t ) {
			case "object":
				if( __js__("o instanceof Array") ) {
					if( o.__enum__ ) {
						if( o.length == 2 )
							return o[0];
						var str = o[0]+"(";
						for( i in 2...o.length ) {
							if( i != 2 )
								str += "," + js.Boot.__string_rec(o[i],"\t");
							else
								str += js.Boot.__string_rec(o[i],"\t");
						}
						return str + ")";
					}
					var l = o.length;
					var i;
					var str = "[";
					for( i in 0...l )
						str += (if (i > 0) "," else "") + js.Boot.__string_rec(o[i],"\t");
					str += "]";
					return str;
				}
				var tostr;
				try {
					tostr = untyped o.toString;
				} catch( e : Dynamic ) {
					// strange error on IE
					return "???";
				}
				if( tostr != null && tostr != __js__("Object.toString") && __typeof__(tostr) == "function" ) {
					var s2 = o.toString();
					//if( s2 != "[object Object]")
					return s2;
				}
                var t:Class<Dynamic> = Type.getClass(o);
                return t == null ? Std.string(o) : "[object " + Type.getClassName(t) + "]";
			case "function":
				return "<function>";
			default:
				return String(o);
			}
		}
        #else
        return o == null ? null : Std.string(o);
        #end
    }

    /**
     * Converts a typed expression into an Int.
     */
    macro public static function int<T>(e:ExprOf<T>, ?base:ExprOf<Int>):ExprOf<T> {
        return macro untyped ~~${e};
    }

    public static function defaultSort(a:Dynamic, b:Dynamic):Int {
        return if (Std.is(a, String))
            defaultStringSort(a, b);
        else if (Std.is(a, Int))
            defaultIntSort(a, b);
        else
            throw 'Unsupported';
    }

    public static function defaultStringSort(a:String, b:String):Int {
        var min:Int = Std.int(Math.min(a.length, b.length));
        a = a.toLowerCase();
        b = b.toLowerCase();
        for (i in 0...min) {
            var r:Int = a.charCodeAt(i) - a.charCodeAt(i);
            if (r != 0) return r;
        }
        return 0;
    }

    public static function defaultIntSort(a:Int, b:Int):Int {
        return a - b;
    }

}