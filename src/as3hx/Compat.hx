package as3hx;

import Type;
import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * Collection of functions that just have no real way to be compatible in Haxe 
 */
class Compat {

    /**
     * According to Adobe:
     * The result is limited to six possible string values:
     *      boolean, function, number, object, string, and xml.
     * If you apply this operator to an instance of a user-defined class,
     * the result is the string object.
     *
     * TODO: TUnknown returns "undefined" on top of this. Not positive on this
     */
    public static function typeof(v:Dynamic) : String {
        return switch(Type.typeof(v)) {
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
    macro public static function parseFloat(e:Expr) : Expr {
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
    macro public static function parseInt(e:Expr) : Expr {
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
    
    public static inline function setInterval(callback:Dynamic, milliseconds:Int, ?rest:Array<Dynamic>):Int {
        if (rest == null) rest = [];
        return FlashTimerAdapter.setInterval(callback, milliseconds, rest);
    }
    
    public static inline function clearInterval(id:Int) FlashTimerAdapter.clearInterval(id);
    
    public static inline function setTimeout(callback:Dynamic, milliseconds:Int, ?rest:Array<Dynamic>):Int {
        if (rest == null) rest = [];
        return FlashTimerAdapter.setTimeout(callback, milliseconds, rest);
    }
    
    public static inline function clearTimeout(id:Int) FlashTimerAdapter.clearTimeout(id);
    
    /**
     * Runtime value of INT_MAX depends on target platform
     */
    public static var INT_MAX(get, never):Int;
    static inline function get_INT_MAX():Int {
        #if flash
        return untyped __global__['int'].MAX_VALUE;
        #elseif js
        return untyped __js__('Number.MAX_SAFE_INTEGER');
        #elseif cs
        return untyped __cs__('int.MaxValue');
        #elseif java
        return untyped __java__('Integer.MAX_VALUE');
        #elseif cpp
        return untyped __cpp__('std::numeric_limits<int>::max()');
        #elseif python
        return PythonSysAdapter.maxint;
        #elseif php
        return untyped __php__('PHP_INT_MAX');
        #else
        return 2^31-1;
        #end
    }
    
    /**
     * Runtime value of INT_MIN depends on target platform
     */
    public static var INT_MIN(get, never):Int;
    static inline function get_INT_MIN():Int {
        #if flash
        return untyped __global__['int'].MIN_VALUE;
        #elseif js
        return untyped __js__('Number.MIN_SAFE_INTEGER');
        #elseif cs
        return untyped __cs__('int.MinValue');
        #elseif java
        return untyped __java__('Integer.MIN_VALUE');
        #elseif cpp
        return untyped __cpp__('std::numeric_limits<int>::min()');
        #elseif python
        return -PythonSysAdapter.maxint - 1;
        #elseif php
        return untyped __php__('PHP_INT_MIN');
        #else
        return -2^31;
        #end
    }
}

private class FlashTimerAdapter {
    
    public static var timers:Array<haxe.Timer> = [];
    
    public static function setInterval(callback:Dynamic, milliseconds:Int, rest:Array<Dynamic>):Int {
        var timer = new haxe.Timer(milliseconds);
        timers.push(timer);
        var id = timers.length - 1;
        timer.run = function() Reflect.callMethod(null, callback, rest);
        return id;
    }
    
    public static function clearInterval(id:Int) stopTimer(id);
    
    public static function setTimeout(callback:Dynamic, milliseconds:Int, rest:Array<Dynamic>):Int {
        var timer = new haxe.Timer(milliseconds);
        timers.push(timer);
        var id = timers.length - 1;
        timer.run = function() {
            Reflect.callMethod(null, callback, rest);
            clearTimeout(id);
        }
        return id;
    }
    
    public static function clearTimeout(id:Int) stopTimer(id);
    
    static function stopTimer(id:Int) {
        timers[id].stop();
        timers[id] = null;
    }
}

#if python
@:pythonImport("sys")
private extern class PythonSysAdapter {
    public static var maxint:Int;
}
#end

#if flash
typedef Regex = flash.utils.RegExp;
#else
typedef Regex = FlashRegExpAdapter;

class FlashRegExpAdapter {
    
    public function new(r:String, opt:String) {
        _ereg = new EReg(r, opt);
        _global = opt.indexOf("g") != -1;
    }
    
    var _ereg:EReg;
    var _global:Bool;
    var _lastTestedString : String;
    var _restOfLastTestedString : String;
    var _lastTestedStringProcessedSize = 0;
    
    public function exec(s:String):Null<Array<String>> {
        var testStr = _lastTestedString == s ? _restOfLastTestedString : s;
        var matched = _ereg.match(testStr);
        var index = 0;
        if (_global) {
            _lastTestedString = s;
            if (matched) {
                var matchedLeftLength = _ereg.matchedLeft().length;
                index = _lastTestedStringProcessedSize + matchedLeftLength;
                _restOfLastTestedString = _ereg.matchedRight();
                _lastTestedStringProcessedSize += matchedLeftLength + _ereg.matched(0).length;
            } else {
                _restOfLastTestedString = null;
                _lastTestedStringProcessedSize = 0;
            }
        }
        return matched ? new FlashRegExpExecResult(s, _ereg, index).matches : null;
    }
    
    public function test(s:String):Bool return match(s);
    
    public function map(s:String, f:EReg-> String):String return _ereg.map(s, f);
    
    public function match(s:String):Bool return _ereg.match(s);
    
    public function matched(n:Int):String return _ereg.matched(n);
    
    public function matchedLeft():String return _ereg.matchedLeft();
    
    public function matchedPos():{pos:Int, len:Int} return _ereg.matchedPos();
    
    public function matchedRight():String return _ereg.matchedRight();
    
    public function matchSub(s:String, pos:Int, len:Int = -1):Bool return _ereg.matchSub(s, pos, len);
    
    public function replace(s:String, by:String):String return _ereg.replace(s, by);
    
    public function split(s:String):Array<String> return _ereg.split(s);
}

private class FlashRegExpExecResult {
    public function new(str:String, ereg:EReg, index:Int) {
        this.input = str;
        this.index = index;
        populateMatches(ereg);
    }
    
    public var index(default,null) : Int = 0;
    public var input(default,null) : String;
    public var matches(default,null) : Array<String>;
    
    function populateMatches(ereg:EReg) {
        matches = [];
        try {
            var group = 0;
            while (true) {
                matches.push(ereg.matched(group));
                group++;
            }
        } catch (ignored:Dynamic) {
        }
    }
}
#end