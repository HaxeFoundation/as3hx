package as3hx;

/**
 * ...
 * @author xmi
 */
class CommonImports
{
    private static var imports:Map<Config,Map<String,String>> = new Map<Config,Map<String,String>>();
    public static function getImports(cfg:Config):Map<String,String> {
        if (imports.exists(cfg)) {
            return imports.get(cfg);
        } else {
            var newImports:Map<String,String> = createImports(cfg);
            imports.set(cfg, newImports);
            return newImports;
        }
    }

    private static function createImports(cfg:Config):Map<String,String> {
        var map:Map<String, String> = new Map<String,String>();
        var doNotImportClasses = [
            "Array", "Bool", "Boolean", "Class", "Date",
            "Dynamic", "EReg", "Enum", "EnumValue",
            "Float", "Map", "Int", "UInt", "IntIter",
            "Lambda", "List", "Math", "Number", "Reflect",
            "RegExp", "Std", "String", "StringBuf",
            "StringTools", "Sys", "Type", "Void",
            "Function", "XML", "XMLList"
        ];

        if (!cfg.useOpenFlTypes) {
            doNotImportClasses.push("Object");
        }

        for(c in doNotImportClasses) {
            //map.set(c, null);
            map.set(c, c);
        }

        if (!cfg.functionToDynamic) {
            map.set("Function", "haxe.Constraints.Function");
        }

        if (cfg.useOpenFlTypes) {
            map.set("Vector", "openfl.Vector");
            map.set("Object", "openfl.utils.Object");
        }

        var topLevelErrorClasses = [
            "ArgumentError", "DefinitionError", "Error",
            "EvalError", "RangeError", "ReferenceError",
            "SecurityError", "SyntaxError", "TypeError",
            "URIError", "VerifyError"
        ];

        for(c in topLevelErrorClasses) {
            if (cfg.useOpenFlTypes) {
                map.set(c, "openfl.errors." + c);
            } else {
                map.set(c, "flash.errors." + c);
            }
        }

        for(c in cfg.importTypes.keys()) {
            map.set(c, cfg.importTypes.get(c));
        }
        map.set("MD5", "MD5");
        map.set("Signal", "signals.Signal");
        map.set("ISignal", "signals.Signal");
        map.set("NativeSignal", "signals.NativeSignal");
        map.set("AGALMiniAssembler", "openfl.utils.AGALMiniAssembler");
        map.set("Base64", "haxe.crypto.Base64");

		//import avm2.intrinsics.memory.Sf32;
		//import avm2.intrinsics.memory.Si32;
        return map;
    }
}