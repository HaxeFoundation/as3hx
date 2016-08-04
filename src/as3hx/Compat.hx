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
     *      boolean, function, number, object, string, and xml.
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

    public static inline function setArrayLegth<T>(a:Array<T>, length:Int) {
        if (a.length > length) a.splice(length, a.length - length);
        else a[length - 1] = null;
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
