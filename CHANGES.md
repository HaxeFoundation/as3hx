## dev
 - Fixed conversion of `typeof 3`. fixes #300
 - Fixed conversion of `function(i:int = 1e5)`. fixes #303
 - Fixed conversion of `function(i:int = 1.5)`. fixes #302
 - Fixed conversion of `1.79E+308`. fixes #298
 - Fixed conversion of `array[index]['key']`. fixes #261
 - Fixed conversion of `setTimeout(callback, (a + b) * 1000)`. fixes #293
 - Fixed conversion of `parseInt('0xFFFFFF', 16)`. fixes #265
 - Loops will be converted to `while` insted of `for` if the condition should be checked continuously, e.g. `for(var i = 5; i < a.length; a.pop())`. fixes #296
 - Loops will be converted to `while` insted of `for` if the condition should be checked continuously, e.g. `for(var i = 0; some(i); i++)`. fixes #296

## 2017-10-24(1.0.6)
 - Fixed conversion of `default` keyword within `switch` statements. fixes #273
 - Fixed conversion of `for(i; i < max; i++)`. fixes #285
 - Fixed conversion of `v_numeric += condition1 || condition2`. fixes #275
 - Fixed conversion of `v += condition ? 1 : 0`. fixes #274
 - Fixed conversion of `private const FOO : int = 1;`. fixes #255
 - Fixed conversion of `if(true) return\n`. fixes #254
 - Fixed conversion of `SomeClass['staticFieldName']`. fixes #234
 - Fixed conversion of `else if` blocks. fixes #277
 - Fixed conversion of comments before `else` blocks. fixes #264
 - Replace `navigateToURL` with `flash.Lib.getURL`. fixes #257
 - Replace `static var init = {...}` by `static var ClassName_static_initializer = {...}`. fixes #276

## 2017-09-13(1.0.5)
 - Fixed conversion of function's parameter with comment
 - Fixed conversion of `&&=` operator
 - Fixed conversion of `getQualifiedClassName(this)`
 - Fixed conversion of local functions
 - Fixed conversion of `Math.min()` with several args
 - Fixed conversion of `Math.max()` with several args
 - Fixed conversion of bitwise operations in conditions
 - Fixed conversion of `delete dictionary[key]` when using setting `-dict2hash`
 - Fixed conversion of `new Dictionary(true)` when using setting `-dict2hash`
 - Fixed conversion of `d is Dictionary` when using setting `-dict2hash`
 - Fixed conversion of `||=` operator when using with array access
 - Fixed conversion of `function(...args:*)`
 - Call `array.insert(position, element)` instead of `array.insertAt(position, element)`
 - Call `array.splice(index, 1)[0]` insted of `array.removeAt(index)`
 - Call `as3hx.Compat.getFunctionLength(function)` instead of `function.length`
 - Call `as3hx.Compat.toFixed(number, fractionDigits)` instead of `number.toFixed(fractionDigits)`
 - Call `regex.replace(string, by)` instead of `string.replace(regex, by)`
 - Call `StringTools.isSpace(string, 0)` instead of `mx.utils.StringUtil.isWhitespace(string)`
 - Call `StringTools.replace(string, string_sub, by)` instead of `string.replace(string_sub, by)`
 - Call `StringTools.trim(string)` instead of `mx.utils.StringUtil.trim(string)`
 - Import `haxe.Constraints.Function` for modules that use `Function` if not used `-fync2dyn`
 - Import of classes occur only if they have been imported in AS3 code
 - Replace `Number.NaN` with `Math.NaN`
 - Replace `Number.NEGATIVE_INFINITY` with `Math.NEGATIVE_INFINITY`
 - Replace `Number.POSITIVE_INFINITY` with `Math.POSITIVE_INFINITY`

## 2016-08-24(1.0.4)
 - Fixed conversion of unary operator after declaration of block
 - Fixed conversion of `if(number)`
 - Fixed conversion of `array.join("\n")`
 - Fixed conversion of `var cls : Class = Object(this).constructor as Class`
 - Fixed conversion of `var some : Some = new someType() as Class`
 - Fixed parsing when semicolumn is missing
 - Fixed conversion of `some || = new Some()`
 - Fixed crash when using setting `-dictionary2hash`
 - Fixed `@:allow` position in the order of access modifiers
 - Fixed int() and Number() casts when applied to Numbers
 - Call `as3hx.Compat.arraySplice(array, position, length, args)` instead of `array.splice(position, length, args)`
 - Call `as3hx.Compat.FLOAT_MAX` instead of `Number.MAX_VALUE`
 - Call `as3hx.Compat.FLOAT_MIN` instead of `Number.MIN_VALUE`
 - Call `as3hx.Compat.INT_MAX` instead of `int.MAX_VALUE`
 - Call `as3hx.Compat.INT_MIN` instead of `int.MIN_VALUE`
 - Call `as3hx.Compat.parseFloat` instead `parseFloat`
 - Call `as3hx.Compat.parseInt` instead `parseInt`
 - Call `as3hx.Compat.Regex::exec` instead of `RegExp::exec`
 - Call `Reflect.callMethod(null, function, [arg0, arg1])` instead of `function.call(null, arg0, args1)`
 - Call `Reflect.callMethod(null, function, args)` instead of `function.apply(null, args)`
 - Call `Reflect.deleteField(dynamic, fieldName)` instead of `delete object[fieldname]`
 - Inline alert message in generated code when trying to `delete` Dictionary keys
 - Loops will be converted to `while` instead of `for` for proper iteration variable modification
 - Only first character of package will be transformed to lower case

## 2016-08-05(1.0.3)
 - Fixed call for `haxe.Json.parse` instead of `JSON.parse` (closes issue #83)
 - Fixed casting of `uint(1)` (closes issue #85)
 - Fixed conversion of [String.]charAt() with zero args (closes issue #69)
 - Fixed conversion of [String.]charCodeAt() with zero args (closes issue #36)
 - Fixed conversion of `var string : String = "";` (closes issue #103)
 - Fixed conversion of `array.push()` with several args (closes issue #94)
 - Fixed conversion of compound loop conditions (closes issue #29)
 - Fixed conversion of regular expressions with '[' character (closes issue #14)
 - Fixed conversion of the ternary statement where condition is `some is T` (closes issue #96)
 - Fixed conversion of var `a:Bool = !i` where type of `i` is numeric (closes issue #91)
 - Fixed crash on class member level variable with no type (closes issue #52)
 - Fixed crash on new object literal with new line in declaration just after "{" (closes issue #56)
 - Fixed exception on code `Security.allowDomain("*");` (closes issue #81)
 - Fixed extra increment call in `for` loop conversion (closes issue #65)
 - Fixed loop conversion with more than one counters defined (closes issue #64)
 - Fixed ternary operator conversion (closes issue #28)
 - Added conversion of `for` loop without break condition (to `while(true)`) (closes issue #58)
 - Added generation of typedefs for anonymous object declaration (closes issue #95)
 - Added many improvements to generated code style
 - Call `as3hx.Compat.setTimeout` instead of `setTimeout` (closes issue #112)
 - Call `FastXML.parse()` for casting string to xml in AS3 code (closes issue #37)
 - Escape `cast` keyword (closes issue #87)
 - Escape DOLLAR sign in the function arg name (closes issue #71)
 - Implemented setting length to arrays (closes issue #68)
 - Remove breaks from switch statement (closes issue #38)
 - Replace `array.join();` with `array.join(",");` (closes issue #93)
 - Replace `array.concat()` with `array.copy()` (closes issue #32)
 - Replace `array.slice()` with `array.copy()` (closes issue #68)
 - Replace `NaN` with `Math.NaN` (closes issue #89)

## 2013-10-28 - Scott Lee
 - Move to Haxe 3 and neko 2

## 2013-08-01 - Yanhick, Richard, Todd
 - added many improvements to generated code style
 - replaced as3 "toString" by Haxe "Std.string"
 - replaced as3 "Date" by Haxe "Date.now" for current time
 - "callback" ident in as3 source replaced by "callbackfunc" because of Haxe reserved keyword
 - implemented support for as3 package level function, wrapped in Haxe class
 - replaced Haxe 2 "Hash" generation by Haxe 3 "Map"
 - removed comma before haxe "implements" keyword (haxe 3 syntax)
 - as3 "hasOwnProperty" replaced by haxe "exists"
 - replaced all tabs by spaces
 - Most newlines are now preserved from as3 source
 - Most comment are now preserved from as3 source
 - Added support for "final" as3 keyword
 - Added ENL type, representing source code new line chars
 - New line chars from as3 files are tokenised instead of ignored
 - Fixed bug where comment made semicolon appear on new lines
 - Class attribute can now be initialised inline
 - Implemented Haxe 3 getter/setter syntax
 - Removed writing var type in for(var x : String in y)
 - Created "in" as Binop : for(i in x)
 - Handle of if(x in y) as Lambda.has
 - Added handling for classes outside of package {} in as3 (private tail classes)
 - Removed conversion of escape sequences in Parser.readString
 - Added odd as3 vector constructor style: mStringVec = new <String>["a","b"];

## 2011-10-19 - Russell
 - Added writing out class inits
 - Fixed empty functions returning f.expr = Object (messed up metadata parsing)
 - Improved metadata support for [Bindable("move")]
 - Added native flash getter and setter methods
 - Refactored configuration, reads xml config files
 - Fixed default values in function args
 - Fixed setters not returning values
 - Output Dynamic for Object
 - Added -no-func2dyn. Prevents Function type being changed to Dynamic
 - Total rewrite of Writer:ESwitch. Corrects switch..break behaviour of flash. See tests/Switch.as
 - Fixed isNaN -> Math.isNaN
 - Fixed continue statements in EFor blocks not incrementing counters. See tests/Loops.as
 - Type.getClass() for "as Class"
 - A little spaghetti, more copy pasta, and some casts to Stringozzi
 - Added compiler warnings
 - Fixed missed chars in token()
 - Parse typeof, added as3hx.Compat class to handle untranslatable flash
 - Skip comments in object create or fuction calls
 - Support for Vector added to Writer

## 2011-10-14 - Russell
 - cleaned formatting on comments
 - added === support (missed)
 - added -no-cast-guess

## 2011-10-12 - Russell
 - added comments
 - fixed static var initializations were not output
 - added output for the "as" keyword
 - fixed "interface extends" to "interface implements"
 - fixed interface functions were outputting empty bodies
 - added ETernary
 - fixed formatting on if...else
 - added parsing for !==
 - added -uint2int command line switch
 - fixed field access (none to never)
