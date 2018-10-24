package as3hx;

import Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;

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

    public static inline function setArrayLength<T>(a:Array<Null<T>>, length:Int) {
        #if js
        untyped a.length = length;
        #else
        if (a.length > length) a.splice(length, a.length - length);
        else {
            for (i in a.length...length) {
                a.push(null);
            }
        }
        #end
    }

    /**
     * Adds elements to and removes elements from an array. This method modifies the array without making a copy.
     * @param startIndex An integer that specifies the index of the element in the array where the insertion or
     *   deletion begins. You can use a negative integer to specify a position relative to the end of the array
     *   (for example, -1 is the last element of the array).
     * @param deleteCount An integer that specifies the number of elements to be deleted. This number includes the
     *   element specified in the startIndex parameter. If you do not specify a value for the
     *   deleteCount parameter, the method deletes all of the values from the startIndex
     *   element to the last element in the array. If the value is 0, no elements are deleted.
     * @param values An optional list of one or more comma-separated values
     *   to insert into the array at the position specified in the startIndex parameter.
     *   If an inserted value is of type Array, the array is kept intact and inserted as a single element.
     *   For example, if you splice an existing array of length three with another array of length three,
     *   the resulting array will have only four elements. One of the elements, however, will be an array of length three.
     * @return An array containing the elements that were removed from the original array.
     */
    public static inline function arraySplice<T>(a:Array<T>, startIndex:Int, deleteCount:Int, ?values:Array<T>):Array<T> {
        var result = a.splice(startIndex, deleteCount);
        if(values != null) {
            for (i in 0...values.length) {
                a.insert(startIndex + i, values[i]);
            }
        }
        return result;
    }

    public static function search(s:String, ereg:FlashRegExpAdapter):Int {
        if (ereg.match(s)) {
            return ereg.matchedPos().pos;
        } else {
            return -1;
        }
    }

    public static function searchEReg(s:String, ereg:EReg):Int {
        if (ereg.match(s)) {
            return ereg.matchedPos().pos;
        } else {
            return -1;
        }
    }

    public static function match(s:String, ereg:FlashRegExpAdapter, parenthesesBlockIndex:Int = 0):Array<String> {
        var matches:Array<String> = [];
        while (ereg.match(s)) {
            matches.push(ereg.matched(parenthesesBlockIndex));
            s = ereg.matchedRight();
        }
        return matches;
    }

    public static function matchEReg(s:String, ereg:EReg, parenthesesBlockIndex:Int = 0):Array<String> {
        var matches:Array<String> = [];
        while (ereg.match(s)) {
            matches.push(ereg.matched(parenthesesBlockIndex));
            s = ereg.matchedRight();
        }
        return matches;
    }

    public static function makeArgs(a1:Dynamic, a2:Dynamic, a3:Dynamic, a4:Dynamic, a5:Dynamic = null, a6:Dynamic = null, a7:Dynamic = null):Array<Dynamic> {
        if (a7 == null) {
            if (a6 == null) {
                if (a5 == null) {
                    if (a4 == null) {
                        if (a3 == null) {
                            if (a2 == null) {
                                if (a1 == null) {
                                    return [];
                                } else {
                                    return [a1];
                                }
                            } else {
                                return [a1, a2];
                            }
                        } else {
                            return [a1, a2, a3];
                        }
                    } else {
                        return [a1, a2, a3, a4];
                    }
                } else {
                    return [a1, a2, a3, a4, a5];
                }
            } else {
                return [a1, a2, a3, a4, a5, a6];
            }
        } else {
            return [a1, a2, a3, a4, a5, a6, a7];
        }
    }

    private static var _weights:Array<Float>;
    public static function sortIndexedArray(weights:Array<Float>):Array<Int> {
        var indices:Array<Int> = new Array<Int>();
        for (i in 0...weights.length) {
            indices[i] = i;
        }
        _weights = weights;
        indices.sort(sortWeights);
        _weights = null;
        return indices;
    }

    private static function sortWeights(a:Int, b:Int):Int {
        var d:Float = _weights[b] - _weights[a];
        return d > 0 ? 1 : (d < 0 ? -1 : 0);
    }

    macro public static function getFunctionLength(f) {
        switch(Context.follow(Context.typeof(f))) {
            case TFun(args, _): return @:pos(Context.currentPos()) macro $v{args.length};
            default: return macro 0;// throw new Error("not a function", f.pos);
        }
    }

    public static function castVector<T>(p:Dynamic):Vector<T> {
        if (p == null || !Std.is(p, Array)) {
            return null;
        }
        return cast p;
    }

    public static function filter<T>(v:Vector<T>, filterMethod:T->Int->Vector<T>->Bool):Vector<T> {
        var r:Vector<T> = new Vector<T>();
        for (i in 0...v.length) {
            if (filterMethod(v[i], i, v)) {
                r.push(v[i]);
            }
        }
        return r;
    }


    #if (openfl && !macro)
    public static inline function newByteArray():openfl.utils.ByteArray {
        var ba:openfl.utils.ByteArray = new openfl.utils.ByteArray();
        ba.endian = openfl.utils.Endian.BIG_ENDIAN;
        return ba;
    }

    /*public static function castVector<T>(p:Dynamic):openfl.Vector<T> {
        if (p == null) return null;
        var c:Class<Dynamic> = Type.getClass(p);
        if (c == null) return null;
        if (Type.getClassName(c).indexOf("openfl._Vector.") != 0) return null;
        //var type:String = Type.getClassName(Type.getClass(p.data)); //oldopenfl
        //} else if (TType == Function && type == "openfl._Vector.FunctionVector") {
        return cast p;
    }*/

    /** T==null is Vector.<*>, otherwise T could be Abstract of Class<Dynamic> */
    public static function isVector(p:Dynamic, T:Dynamic = null):Bool {
        if (p == null) return null;
        var c:Class<Dynamic> = Type.getClass(p);
        if (c == null) return false;
        //if (Type.getClassName(c) != "openfl._Vector.AbstractVector") return false;
        if (Type.getClassName(c).indexOf("openfl._Vector.") != 0) return null;
        var v:openfl.Vector<Dynamic> = cast p;
        if (v.length > 0 && T != null && v[0] != null && !Std.is(v[0], T)) {
            return false;
        }
        return true;
    }

    public static inline function each(obj:openfl.utils.Object):Iterator<Dynamic> {
        return new ObjectIterator(obj);
    }
    //public static function filter<T>(v:openfl.Vector<T>, filterMethod:T->Int->openfl.Vector<T>->Bool):openfl.Vector<T> {
        //var r:openfl.Vector<T> = new openfl.Vector<T>();
        //for (i in 0...v.length) {
            //if (filterMethod(v[i], i, v)) {
                //r.push(v[i]);
            //}
        //}
        //return r;
    //}

    public static inline function vectorSplice<T>(a:openfl.Vector<T>, startIndex:Int, deleteCount:Int, ?values:Array<T>):openfl.Vector<T> {
        var result = a.splice(startIndex, deleteCount);
        if(values != null) {
            for (i in 0...values.length) {
                a.insertAt(startIndex + i, values[i]);
            }
        }
        return result;
    }
    #end

    public static inline function isClass(c:Dynamic):Bool {
        return c != null && c.__name__ != null;
    }

    public static inline function castClass(c:Dynamic):Class<Dynamic> {
        return isClass(c) ? untyped c : null;
    }

    public static inline function getQualifiedClassName(o:Dynamic):String {
        if (o == null) {
            return null;
        } else if (untyped o.__name__) {
            return o.__name__;
        } else {
            var c:Class<Dynamic> = Type.getClass(o);
            if (c != null) {
                return Type.getClassName(c);
            } else {
                return null;
            }
        }
        //var c:Class<Dynamic> = Type.getClass(o);
        //if (c == null) {
            //c = castClass(o);
        //}
        //if (c != null) {
            //return Type.getClassName(c);
        //} else {
            //return null;
        //}
    }

    public static inline function getQualifiedSuperclassName(o:Dynamic):String {
        var c:Class<Dynamic> = Type.getClass(o);
        if (c == null) {
            c = castClass(o);
        }
        if (c != null) {
            return Type.getClassName(Type.getSuperClass(c));
        } else {
            return null;
        }
    }

    public static function parseInt(s:String, ?base:Int):Null<Int> {
        #if js
        if(base == null) base = s.indexOf("0x") == 0 ? 16 : 10;
        var v:Int = untyped __js__("parseInt")(s, base);
        return Math.isNaN(v) ? null : v;
        #elseif flash
        if(base == null) base = 0;
        var v:Int = untyped __global__["parseInt"](s, base);
        return Math.isNaN(v) ? null : v;
        #else
        var BASE = "0123456789abcdefghijklmnopqrstuvwxyz";
        if(base != null && (base < 2 || base > BASE.length))
            return throw 'invalid base ${base}, it must be between 2 and ${BASE.length}';
        s = StringTools.trim(s).toLowerCase();
        var sign = if(StringTools.startsWith(s, "+")) {
            s = s.substring(1);
            1;
        } else if(StringTools.startsWith(s, "-")) {
            s = s.substring(1);
            -1;
        } else {
            1;
        };
        if(s.length == 0) return null;
        if(StringTools.startsWith(s, '0x')) {
            if(base != null && base != 16) return null; // attempting at converting a hex using a different base
            base = 16;
            s = s.substring(2);
        } else if(base == null) {
            base = 10;
        }
        var acc = 0;
        try s.split('').map(function(c) {
            var i = BASE.indexOf(c);
            if(i < 0 || i >= base) throw 'invalid';
            acc = (acc * base) + i;
        }) catch(e:Dynamic) {};
        return acc * sign;
        #end
    }

    /**
     * Converts a typed expression into a Float.
     */
    macro public static function parseFloat<T>(e:ExprOf<T>):ExprOf<T> {
        var type = switch(Context.typeof(e)) {
            case TAbstract(t, _) if(t.get().pack.length == 0): t.get().name;
            case TInst(t, _) if(t.get().pack.length == 0): t.get().name;
            case _: null;
        }
        return switch(type) {
            case "Float" | "Int": macro ${e};
            case "String": macro Std.parseFloat(${e});
            case _: macro Std.parseFloat(Std.string(${e}));
        }
    }

    /**
     * Runs a function at a specified interval (in milliseconds).
     *
     *   Instead of using the setInterval() method, consider
     * creating a Timer object, with the specified interval, using 0 as the repeatCount
     * parameter (which sets the timer to repeat indefinitely).If you intend to use the clearInterval() method to cancel the
     * setInterval() call, be sure to assign the setInterval() call to a
     * variable (which the clearInterval() function will later reference).
     * If you do not call the clearInterval() function to cancel the
     * setInterval() call, the object containing the set timeout closure
     * function will not be garbage collected.
     * @param closure The name of the function to execute. Do not include quotation marks or
     *   parentheses, and do not specify parameters of the function to call. For example, use
     *   functionName, not functionName() or functionName(param).
     * @param delay The interval, in milliseconds.
     * @param arguments An optional list of arguments that are passed to the closure function.
     * @return Unique numeric identifier for the timed process. Use this identifier to cancel
     *   the process, by calling the clearInterval() method.
     */
    public static inline function setInterval(closure:Dynamic, delay:Int, ?values:Array<Dynamic>):Int {
        #if flash
        return untyped __global__['flash.utils.setInterval'](closure, delay, values);
        #elseif js
        return untyped __js__('setInterval')(closure, delay, values);
        #elseif (haxe_ver >= "3.3")
        if (values == null) values = [];
        return FlashTimerAdapter.setInterval(closure, delay, values);
        #else
        throw "Supported by version 3.3 or higher";
        return -1;
        #end
    }

    /**
     * Cancels a specified setInterval() call.
     * @param id The ID of the setInterval() call, which you set to a variable, as in the following:
     * @see setInterval()
     */
    public static inline function clearInterval(id:Int) {
        #if flash
        untyped __global__['flash.utils.clearInterval'](id);
        #elseif js
        untyped __js__('clearInterval')(id);
        #elseif (haxe_ver >= "3.3")
        FlashTimerAdapter.clearInterval(id);
        #else
        throw "Supported by version 3.3 or higher";
        #end
    }

    /**
     * Runs a specified function after a specified delay (in milliseconds).
     *
     *   Instead of using this method, consider
     * creating a Timer object, with the specified interval, using 1 as the repeatCount
     * parameter (which sets the timer to run only once).If you intend to use the clearTimeout() method to cancel the
     * setTimeout() call, be sure to assign the setTimeout() call to a
     * variable (which the clearTimeout() function will later reference).
     * If you do not call the clearTimeout() function to cancel the
     * setTimeout() call, the object containing the set timeout closure
     * function will not be garbage collected.
     * @param closure The name of the function to execute. Do not include quotation marks or
     *   parentheses, and do not specify parameters of the function to call. For example, use
     *   functionName, not functionName() or functionName(param).
     * @param delay The delay, in milliseconds, until the function is executed.
     * @param arguments An optional list of arguments that are passed to the closure function.
     * @return Unique numeric identifier for the timed process. Use this identifier to cancel
     *   the process, by calling the clearTimeout() method.
     */
    public static inline function setTimeout(closure:Dynamic, delay:Int, ?values:Array<Dynamic>):Int {
        #if flash
        return untyped __global__['flash.utils.setTimeout'](closure, delay, values);
        #elseif js
        return untyped __js__('setTimeout')(closure, delay, values);
        #elseif (haxe_ver >= "3.3")
        if (values == null) values = [];
        return FlashTimerAdapter.setTimeout(closure, delay, values);
        #else
        throw "Supported by version 3.3 or higher";
        return -1;
        #end
    }

    /**
     * Cancels a specified setTimeout() call.
     * @param id The ID of the setTimeout() call, which you set to a variable, as in the following:
     * @see setTimeout()
     */
    public static inline function clearTimeout(id:Int) {
        #if flash
        untyped __global__['flash.utils.clearTimeout'](id);
        #elseif js
        untyped __js__('clearTimeout')(id);
        #elseif (haxe_ver >= "3.3")
        FlashTimerAdapter.clearInterval(id);
        #else
        throw "Supported by version 3.3 or higher";
        #end
    }

    /**
     * Runtime value of FLOAT_MAX depends on target platform
     */
    public static var FLOAT_MAX(get, never):Float;
    static inline function get_FLOAT_MAX():Float {
        #if flash
        return untyped __global__['Number'].MAX_VALUE;
        #elseif js
        return untyped __js__('Number.MAX_VALUE');
        #elseif cs
        return untyped __cs__('double.MaxValue');
        #elseif java
        return untyped __java__('Double.MAX_VALUE');
        #elseif cpp
        return 1.79769313486232e+308;
        #elseif python
        return PythonSysAdapter.float_info.max;
        #else
        return 1.79e+308;
        #end
    }

    /**
     * Runtime value of FLOAT_MIN depends on target platform
     */
    public static var FLOAT_MIN(get, never):Float;
    static inline function get_FLOAT_MIN():Float {
        #if flash
        return untyped __global__['Number'].MIN_VALUE;
        #elseif js
        return untyped __js__('Number.MIN_VALUE');
        #elseif cs
        return untyped __cs__('double.MinValue');
        #elseif java
        return untyped __java__('Double.MIN_VALUE');
        #elseif cpp
        return 2.2250738585072e-308;
        #elseif python
        return PythonSysAdapter.float_info.min;
        #else
        return -1.79E+308;
        #end
    }

    /**
     * Runtime value of INT_MAX depends on target platform
     */
    public static var INT_MAX(get, never):Int;
    static inline function get_INT_MAX():Int {
        #if flash
        return untyped __global__['int'].MAX_VALUE;
        #elseif js
        //return untyped __js__('Number.MAX_SAFE_INTEGER');
        return 2147483647;
        #elseif cs
        return untyped __cs__('int.MaxValue');
        #elseif java
        return untyped __java__('Integer.MAX_VALUE');
        #elseif cpp
        return 2147483647;
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
        //return untyped __js__('Number.MIN_SAFE_INTEGER');
        return -2147483648;
        #elseif cs
        return untyped __cs__('int.MinValue');
        #elseif java
        return untyped __java__('Integer.MIN_VALUE');
        #elseif cpp
        return -2147483648;
        #elseif python
        return -PythonSysAdapter.maxint - 1;
        #elseif php
        return untyped __php__('PHP_INT_MIN');
        #else
        return -2^31;
        #end
    }

    /**
     * Returns a string representation of the number in fixed-point notation.
     * Fixed-point notation means that the string will contain a specific number of digits
     * after the decimal point, as specified in the fractionDigits parameter.
     * The valid range for the fractionDigits parameter is from 0 to 20.
     * Specifying a value outside this range throws an exception.
     * @param fractionDigits An integer between 0 and 20, inclusive, that represents the desired number of decimal places.
     * @throws Throws an exception if the fractionDigits argument is outside the range 0 to 20.
     */
    public static inline function toFixed(v:Float, fractionDigits:Int):String {
        #if (js || flash)
            return untyped v.toFixed(fractionDigits);
        #else
            if(fractionDigits < 0 || fractionDigits > 20) throw 'toFixed have a range of 0 to 20. Specified value is not within expected range.';
            var b = Math.pow(10, fractionDigits);
            var s = Std.string(v);
            var dotIndex = s.indexOf('.');
            if(dotIndex >= 0) {
                var diff = fractionDigits - (s.length - (dotIndex + 1));
                if(diff > 0) {
                    s = StringTools.rpad(s, "0", s.length + diff);
                } else {
                    s = Std.string(Math.round(v * b) / b);
                }
            } else {
                s += ".";
                s = StringTools.rpad(s, "0", s.length + fractionDigits);
            }
            return s;
        #end
    }

    public static function toPrecision(n:Float, prec:Int):String {
        n = Math.round(n * Math.pow(10, prec));
        var str = '' + n;
        var len = str.length;
        if(len <= prec){
            while(len < prec){
                str = '0' + str;
                len++;
            }
            return '0.' + str;
        } else{
            return str.substr(0, len - prec) + '.' + str.substr(len - prec);
        }
    }

    public static function toString(value:Int, base:Int = 10):String {
        var BASE:String = "0123456789abcdefghijklmnopqrstuvwxyz";
        if(base < 2 || base > BASE.length)
            throw 'invalid base $base, it must be between 2 and ${BASE.length}';
        if(base == 10 || value == 0)
            return Std.string(value);
        var buf:String = "";
        var abs:Int = value > 0 ? value : -value;
        while(abs > 0) {
            buf = BASE.charAt(abs % base) + buf;
            abs = Std.int(abs / base);
        }
        return buf;
    }

    /** returns timezone offset in minutes */
    public static function getTimezoneOffset():Int {
        #if flash
        return untyped new flash.Date().getTimezoneOffset();
        #elseif js
        return untyped __js__("new Date().getTimezoneOffset()");
        #else
        var now = Date.now();
        now = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
        return 24 * 60 * Math.round(now.getTime() / 24 / 3600 / 1000) - Std.int(now.getTime() / 1000 / 60);
        /*
        //https://github.com/HaxeFoundation/haxe/issues/3268
        var a = DateTools.format(Date.fromTime(0), '%H:%M').split(':');
        var offset = -Std.parseInt(a[0]) * 60 + Std.parseInt(a[1]); // will care about DST (daylight saving time), but can fail with < UTC-1200 and > UTC+1200
        trace(offset);

        //https://github.com/waneck/geotools/issues/2
        trace ( (new Date(1970, 0, 1, 0, 0, 0).getTime() / 1000 / 60)) ); // may not work in Neko, do not care about DST (daylight saving time)
        trace ( ((new Date(1970, 1, 1, 0, 0, 0).getTime() - 31 * 24 * 60 * 60 * 1000) / 1000 / 60) ); //should work in Neko too
        */
        #end
    }
}

#if (!flash && !js && (haxe_ver >= "3.3"))
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
    #end

#if python
@:pythonImport("sys")
private extern class PythonSysAdapter {
    public static var maxint:Int;
    public static var float_info:{max:Float, min:Float};
}
#end

#if flash
typedef Regex = flash.utils.RegExp;
#else
typedef Regex = FlashRegExpAdapter;

class FlashRegExpAdapter {

    public function new(r:String, opt:String = '') {
        _ereg = new EReg(r, opt);
        _global = opt.indexOf("g") != -1;
    }

    public var lastIndex(get, set):Int;

    var _ereg:EReg;
    var _global:Bool;
    var _lastTestedString : String;
    var _restOfLastTestedString : String;
    var _lastIndex:Int = 0;

    private function get_lastIndex():Int {
        return _lastIndex;
    }

    private function set_lastIndex(value:Int):Int {
        if (_lastIndex != value) {
            if (_lastTestedString != null) {
                _restOfLastTestedString = _lastTestedString.substr(value);
            }
            return _lastIndex = value;
        } else {
            return value;
        }
    }

    /**
     * Performs a search for the regular expression on the given string str.
     *
     *   If the g (global) flag is not set for the regular
     * expression, then the search starts
     * at the beginning of the string (at index position 0); the search ignores
     * the lastIndex property of the regular expression.If the g (global) flag is set for the regular
     * expression, then the search starts
     * at the index position specified by the lastIndex property of the regular expression.
     * If the search matches a substring, the lastIndex property changes to match the position
     * of the end of the match.
     * @param str The string to search.
     * @return If there is no match, null; otherwise, an object with the following properties:
     *
     *     An array, in which element 0 contains the complete matching substring, and
     *   other elements of the array (1 through n) contain substrings that match parenthetical groups
     *   in the regular expression index  The character position of the matched substring within
     *   the stringinput  The string (str)
     */
    public function exec(str:String):Null<Array<String>> {
        var testStr;
        if (_lastTestedString == str) {
            testStr = _restOfLastTestedString;
        } else {
            testStr = str;
        }
        var matched = _ereg.match(testStr);
        var index = 0;
        if (_global) {
            _lastTestedString = str;
            if (matched) {
                var matchedLeftLength = _ereg.matchedLeft().length;
                index = _lastIndex + matchedLeftLength;
                _restOfLastTestedString = _ereg.matchedRight();
                _lastIndex += matchedLeftLength + _ereg.matched(0).length;
            } else {
                _restOfLastTestedString = null;
                _lastIndex = lastIndex;
            }
        }
        return matched ? new FlashRegExpExecResult(str, _ereg, index).matches : null;
    }

    /**
     * Tests for the match of the regular expression in the given string str.
     *
     *   If the g (global) flag is not set for the regular expression,
     * then the search starts at the beginning of the string (at index position 0); the search ignores
     * the lastIndex property of the regular expression.If the g (global) flag is set for the regular expression, then the search starts
     * at the index position specified by the lastIndex property of the regular expression.
     * If the search matches a substring, the lastIndex property changes to match the
     * position of the end of the match.
     * @param str The string to test.
     * @return If there is a match, true; otherwise, false.
     */
    public function test(str:String):Bool return match(str);

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
        #if js
        matches = untyped ereg.r.m.slice(0);
        #else
        matches = [];
        try {
            var group = 0;
            while (true) {
                matches.push(ereg.matched(group));
                group++;
            }
        } catch (ignored:Dynamic) {
        }
        #end
    }
}
#end

#if openfl
class ObjectIterator {
	private var object:openfl.utils.Object;
	private var fields:Array<String>;
	private var i:Int;
	private var l:Int;
	public inline function new(object:openfl.utils.Object) {
		this.fields = Reflect.fields(object);
		this.object = object;
		this.i = 0;
		this.l = fields.length;
	}
	public inline function next():Dynamic {
		return object[fields[i++]];
	}
	public inline function hasNext():Bool {
		return i < l;
	}
}
#end