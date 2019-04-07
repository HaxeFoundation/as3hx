package as3hx.parsers;

import as3hx.As3.T;
import as3hx.Parser.Types;

/**
 * ...
 * @author
 */
class OverrideTypeComment {
    public static function extractType(baseString:String, s:String, types:Types):T {
        if (s.indexOf("haxe:") == 2) { // /*haxe:
            var arg = s.substring(7, s.length - 2);
            var typeArray:Array<String> = null;
            for (a in Typer.getTypeParams(arg)) {
                types.seen.push(TPath(a));
                if (typeArray == null) {
                    typeArray = a;
                }
            }
            var l:Int = typeArray.join(".").length;
            if (l < arg.length) {
                typeArray = typeArray.copy();
            }
            typeArray[typeArray.length - 1] += arg.substring(typeArray.join(".").length);
            return TPath(typeArray);
        } else if (baseString != null && s.indexOf("<") == 2 && s.lastIndexOf(">") == s.length - 3) {
            var arg = s.substring(2, s.length - 2);
            var typeArray:Array<String> = null;
            for (a in Typer.getTypeParams(arg)) {
                types.seen.push(TPath(a));
                if (typeArray == null) {
                    typeArray = a;
                }
            }
            return TPath([baseString + arg]);
        } else {
            return null;
        }
    }
}