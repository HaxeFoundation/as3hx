package;
import haxe.Constraints.Function;
/**
 * ...
 * @author xmi
 */
@:forward
@:arrayAccess
abstract Vector<T>(Array<T>) from Array<T> to Array<T> {
    public inline function new(_length:Int = 0, fixed_ignored:Bool = false) {
        this = [];
        if (_length != 0) length = _length;
    }

	public var fixed(never, set):Bool;
    public inline function set_fixed(value:Bool):Bool {
        return value;
    }


	public var length(get, set):Int;
    public inline function get_length():Int {
        return this.length;
    }
    public inline function set_length(value:Int):Int {
        #if js
        return untyped this.length = value;
        #else
        var l:Int = this.length;
        if (value > l) {
            while (l < value) {
                this.push(null);
                l++;
            }
        } else if (value < l) {
            while (l < value) {
                this.pop();
            }
        }
        return value;
        #end
    }

    public inline function insertAt(pos:Int, x:T):Void {
        return this.insert(pos, x);
    }

    public inline function removeAt(index:Int):T {
        return this.splice(index, 1)[0];
    }

    public inline function concat(?v:Vector<T>):Vector<T> {
        if (v == null) {
            return this.copy();
        } else {
            return this.concat(v);
        }
    }

    public static inline function ofArray<T>(a:Array<Dynamic>):Vector<T> {
        return untyped a;
    }

    #if openfl
    @:to public function toOpenFlVector<Dynamic>():openfl.Vector<Dynamic> {
        return untyped new openfl.Vector<openfl.utils.Object>(this.length, false, untyped this);
    }
    @:from public static function fromOpenFlVector<T>(v:openfl.Vector<T>):Vector<T> {
        return untyped v.__array;
    }
    @:to public function toOpenFlObject():openfl.utils.Object {
        return untyped this;
    }
    #end
}