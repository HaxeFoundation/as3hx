##2016-08-24(1.0.4)
 - Fixed conversion of unary operator after declaration of block
 - Fixed convesion ```of if(number)```
 - Fixed conversion of ```array.join("\n")```
 - Fixed conversion of ```var cls : Class = Object(this).constructor as Class```
 - Fixed conversion of ```var some : Some = new someType() as Class```
 - Fixed parsing when semicolumn is missing
 - Fixed conversion of ```some || = new Some()```
 - Fixed crash when using setting -dictionary2hash
 - Fixed ```@:allow``` position in the order of access modifiers
 - Fixed int() and Number() casts when applied to Numbers
 - Only first character of package will be transformed to lower case
 - Loops will be converted to ```while``` instead of ```for``` for proper iteration variable modification
 - Inline alert message in generated code when trying to `delete` Dictionary keys
 - Call ```Reflect.deleteField(dynamic, fieldName)``` instead of ```delete object[fieldname]```
 - Call ```as3hx.Compat.Regex::exec``` instead of ```RegExp::exec```
 - Call ```as3hx.Compat.FLOAT_MAX``` instead of ```Number.MAX_VALUE```
 - Call ```as3hx.Compat.FLOAT_MIN``` instead of ```Number.MIN_VALUE```
 - Call ```as3hx.Compat.INT_MAX``` instead of ```int.MAX_VALUE```
 - Call ```as3hx.Compat.INT_MIN``` instead of ```int.MIN_VALUE```
 - Call ```as3hx.Compat.parseFloat``` instead ```parseFloat```
 - Call ```as3hx.Compat.parseInt``` instead ```parseInt```
 - Call ```as3hx.Compat.arraySplice(array, position, length, args)``` instead of ```array.splice(position, length, args)```
 - Call ```Reflect.callMethod(null, function, args)``` instead of ```function.apply(null, args)```
 - Call ```Reflect.callMethod(null, function, [arg0, arg1])``` instead of ```function.call(null, arg0, args1)```
 
##2016-08-05(1.0.3)
 - Fixed conversion of regular expressions with '[' character (closes issue #14)
 - Fixed ternary operator conversion (closes issue #28)
 - Fixed conversion of compound loop conditions (closes issue #29)
 - Replace array.concat() with array.copy() (closes issue #32)
 - Fixed conversion of [String.]charCodeAt() with zero args (closes issue #36)
 - Call FastXML.parse() for casting string to xml in AS3 code. (closes issue #37)
 - Remove breaks from switch statement (closes issue #38)
 - Fixed crash on class member level variable with no type (closes issue #52)
 - Fixed crash on new object literal with new line in declaration just after "{" (closes issue #56)
 - Added conversion of "for" loop without break condition (to "while(true)") (closes issue #58)
 - Implemented setting length to arrays (closes issue #68)
 - Fixed loop conversion with more than one counters defined (closes issue #64)
 - Fixed extra increment call in "for" loop conversion (closes issue #65)
 - Replace array.slice() with array.copy() (closes issue #68)
 - Fixed conversion of [String.]charAt() with zero args (closes issue #69)
 - Escape DOLLAR sign in the function arg name (closes issue #71)
 - Fixed exception on code "Security.allowDomain("*");" (closes issue #81)
 - Fixed call for haxe.Json.parse instead of JSON.parse (closes issue #83)
 - Fixed casting of "uint(1)" (closes issue #85)
 - Escape "cast" keyword (closes issue #87)
 - Replace NaN with Math.NaN (closes issue #89)
 - Fixed conversion of var a:Bool = !i where type of i is numeric (closes issue #91)
 - Replace "array.join();" with "array.join(",");" (closes issue #93)
 - Fixed conversion of array.push() with several args (closes issue #94)
 - Added generation of typedefs for anonymous object declaration (closes issue #95)
 - Fixed conversion of the ternary statement where condition is "some is T" (closes issue #96)
 - Fixed conversion of "var string : String = "";" (closes issue #103)
 - Call  as3hx.Compat.setTimeout instead of setTimeout (closes issue #112)
 - added many improvements to generated code style

##2013-10-28 - Scott Lee
 - Move to Haxe 3 and neko 2

##2013-08-01 - Yanhick, Richard, Todd
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

##2011-10-19 - Russell
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

##2011-10-14 - Russell
 - cleaned formatting on comments
 - added === support (missed)
 - added -no-cast-guess 

##2011-10-12 - Russell
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
