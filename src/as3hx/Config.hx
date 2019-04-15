
package as3hx;

import haxe.xml.Access;
import sys.FileSystem;
import sys.io.File;
import haxe.ds.StringMap;
import haxe.io.Path;

using StringTools;

/**
 * Configuration object for as3hx
 * @author Russell Weir
 */
class Config {
    public var verbouseConditionalCompilationEnd:Bool = false;

    /** Indent character(s) **/
    public var indentChars : String;
    /** newline character **/
    public var newlineChars : String;
    /** put open braces on new line **/
    public var bracesOnNewline : Bool;
    /** add spaces before and after colon when typing **/
    public var spacesOnTypeColon : Bool;

    /** Transform uint to Int? */
    public var uintToInt : Bool;
    /** Transform Vector to Array? */
    public var vectorToArray : Bool;
    /** Do cast guessing MyType(obj) -> cast(obj, MyType) */
    public var guessCasts : Bool;
    /** write commented Expr into output **/
    public var debugExpr : Bool;
    /** Continue parsing despite errors? **/
    public var errorContinue : Bool;
    /** Write Dynamic for Function **/
    public var functionToDynamic : Bool;
    /** Allow full typing of available classes. App will firstly parse all classes into memory and then try to apply type info while writing all classes in second phase **/
    public var useFullTyping : Bool;
    /** getter function template **/
    public var getterMethods : String;
    /** setter function template **/
    public var setterMethods : String;
    /** getter/setter output style **/
    public var getterSetterStyle : String;
    /** top level package for classes defined in flash.* package in as3. 'flash' is default, but `openfl` or `nme` can be used for example **/
    public var flashTopLevelPackage : String;
    /** list of paths to exclude from parsing **/
    public var excludePaths : List<String>;
    /** Used only for test cases for compiler to ignore Sprite imports and extends **/
    public var testCase : Bool;
    /** Try to use openfl.Vector openfl.utils.Dictionary and openfl.utils.Object types **/
    public var useOpenFlTypes : Bool;
    /** Replace varArgs with set of optional arguments converted to an Array<Dynamic> **/
    public var replaceVarArgsWithOptionalArguments : Bool;
    /** conditional compilation variables **/
    public var conditionalVars: List<String>;
    /** Compile time constants implementation class package path for CONFIG::VAR -> `compile.Time.Constants`.CONFIG_VAR**/
    public var conditionalCompilationConstantsClass : String;
    /** Try fix local variable declarations. In haxe variable should be declared only once and before first usage. **/
    public var fixLocalVariableDeclarations : Bool;
    /** Transform Dictionary.<Key, Value> to Map **/
    public var dictionaryToHash : Bool;
    /** if set to false `Dictionary\/*KeyType,ValueType*\/` notation will be used. By default Dictionary.<KeyType,ValueType> notation is used **/
    public var useAngleBracketsNotationForDictionaryTyping : Bool;
    /** write inferred type information into output **/
    public var debugInferredType : Bool;
    /** replace local function declarations with variable definitions **/
    public var rebuildLocalFunctions : Bool;
    /** convert flexunit metadata and calls to munit form */
    public var convertFlexunit : Bool;
    /** make all generated setter private */
    public var forcePrivateSetter : Bool;
    /** make all generated getter private */
    public var forcePrivateGetter : Bool;
    /** use Haxe compatiblity classes for XML */
    public var useFastXML : Bool;
    /** use Haxe general compatibility class */
    public var useCompat : Bool;
    /** diff the generated .hx files against expected .hx files if they exists **/
    public var verifyGeneratedFiles : Bool;
    /**
     * run a postProcessor script on the generated .hx fiels after generation
     * specify full path + script name and make sure it's executable, e.g. "/usr/bin/postprocessor.sh"
     * the first passed on argument will be the full path + filename of the .hx file, e.g. "/usr/bin/postprocessor.sh /my/folder/out/generated.hx"
     */
    public var postProcessor : String = "";

    public var arrayTypePath : String = "Vector";

    /**
     * a list of absolute or relative directory paths.
     * as3 files from this paths are parsed as a source for type info
     */
    public var libPaths : Array<String>;

    /**
     * a list of absolute or relative directory paths.
     * Haxe files are found in this path and added to a map
     * of imported types used for implicit imports used
     * in converted code
     */
    public var importPaths : Array<String>;

    /**
     * list of as3 import paths that should not be included in haxe files but should be looked up through existing codebase
     */
    public var importExclude : Array<String>;

    /**
     * A map where the key is the name fo a Haxe type
     * and the value is its' fully qualified name,
     * as found in one of the provided importPaths
     */
    public var importTypes : StringMap<String>;

    /** source directory **/
    public var src : Array<String>;
    /** output directory **/
    public var dst : Array<String>;

    var cfgFile : String;

    public function new() {
        init();
        processDefaultConfig();
        processEnvConfig();
        processLocalConfig();
        processCommandLine();
        processImportPaths();
    }

    public function init():Void {
        var env = Sys.environment();
        if (env.exists("AS3HX_CONFIG")) {
            cfgFile = env.get("AS3HX_CONFIG");
            return;
        }

        if (env.exists("TOOLROOT")) {
            var toolroot = env.get("TOOLROOT");
            cfgFile = toPath(toolroot + "/lib/as3hx/as3hx_config.xml");
            return;
        }

        var home = "";
        if (env.exists("HOME"))
            home = env.get("HOME");
        else if (env.exists("USERPROFILE"))
            home = env.get("USERPROFILE");
        else return;

        cfgFile = toPath(home+"/.as3hx_config.xml");

        src = [];
        dst = [];
    }

    /**
     * Creates a getter function name based on a property
     * using the getterMethods template
     */
    public function makeGetterName(id:String):String {
        var s = getterMethods.replace("%I", id);
        s = s.replace("%i", id);
        return s;
    }

    /**
     * Creates a setter function name based on a property
     * using the setterMethods template
     */
    public function makeSetterName(id:String) :String {
        var s = setterMethods.replace("%I", id);
        s = s.replace("%i", id);
        return s;
    }

    static function ucfirst(s : String):String {
        return s.substr(0, 1).toUpperCase() + s.substr(1);
    }

    public function processDefaultConfig():Void {
        fromXmlString(defaultConfig());
    }

    function processEnvConfig():Void {
        // $HOME/.as3hx_config.xml or env
        if(cfgFile != null) {
            if(!FileSystem.exists(cfgFile)) {
                Sys.println("Creating " + cfgFile);
                var fo = File.write(cfgFile, false);
                fo.writeString(defaultConfig());
                fo.close();
            }
            if(FileSystem.exists(cfgFile)) {
                fromXmlString(File.getContent(cfgFile));
            }
        }
    }

    function processLocalConfig():Void {
        if(FileSystem.exists("./.as3hx_config.xml")) {
            fromXmlString(File.getContent("./.as3hx_config.xml"));
        }
    }

    /**
     * Store fuly qualified names of Haxe files found
     * at provided directories
     */
    function processImportPaths():Void {
        importTypes = new StringMap<String>();
        for(path in importPaths) {
            processImportPath(path, "", importTypes);
        }
    }

    /**
     * Traverse an import path directory recursively.
     * For each found Haxe file, store its fully qualified
     * name, using its path starting from the import path
     */
    function processImportPath(base : String, path : String, importTypes : StringMap<String>) : Void {
        /** check if valid base path was provided */
        if (FileSystem.exists(base)) {

            /** get all files from the path */
            var fullPath = FileSystem.fullPath(base + path);
            var fileNames = FileSystem.readDirectory(fullPath);
            for (fileName in fileNames) {

                /* recurse down the directories */
                if (FileSystem.isDirectory(fullPath + "/" + fileName)) {
                    processImportPath(base, path + "/" + fileName, importTypes);
                }
                else {
                    /* store the Haxe files names + path */
                    if (fileName.substr(-3) == ".hx") {
                        var typeFullyQualifiedName = path.split("/");
                        var typeName = fileName.substr(0, fileName.length - 3);
                        typeFullyQualifiedName.push(typeName);
                        importTypes.set(typeName, typeFullyQualifiedName.join(".").substr(1));
                    }
                }
            }
        }
    }

    public static function usage():Void {
        var println = Sys.println;
        println("Usage: as3hx [options] sourceDir [outdir]");
        println("  Options:");
        println("    -no-cast-guess       : will not try to handle MyClass(obj) casts");
        println("    -func2dyn            : will change Function types to Dynamic");
        println("    -no-uint2int         : will not convert uint to Int");
        println("    -no-vector2array     : will not convert Vectors to haxe Arrays");
        println("    -dict2hash           : will convert Dictionary to haxe ObjectMap");
        println("    -debug-expr          : will output debug information");
        println("    -debug-inferred-type : will output inferred type debug information");
        println("    -convert-flexunit    : will convert FlexUnit metadata and calls to munit form");
        println("    -error-continue      : will continue parsing despite errors");
        println("");
        println("  outdir\t\t : defaults to './out'");
    }

    function processCommandLine():Void {
        var args = Sys.args().copy();
        #if !munit
        if (args.length == 0) {
            usage();
            Sys.exit(0);
        }
        #else
        if (args.length == 0) return;
        #end
        var arg:String = null;
        while (true) {
            arg = args.shift();
            switch (arg) {
                case "-help", "--help":
                    usage();
                    Sys.exit(0);
                case "-no-uint2int", "--no-uint2int":
                    uintToInt = false;
                case "-no-cast-guess", "--no-cast-guess":
                    guessCasts = false;
                case "-no-vector2array", "--no-vector2array":
                    vectorToArray = false;
                case "-verifyGeneratedFiles", "--verifyGeneratedFiles":
                    verifyGeneratedFiles = true;
                case "-debug-expr", "--debug-expr":
                    debugExpr = true;
                case "-func2dyn", "--func2dyn":
                    functionToDynamic = true;
                case "-error-continue","--error-continue":
                    errorContinue = true;
                case "-test-case":
                    testCase = true;
                case "-debug-inferred-type", "--debug-inferred-type":
                    debugInferredType = true;
                case "-convert-flexunit", "--convert-flexunit":
                    convertFlexunit = true;
                case "-dict2hash":
                    dictionaryToHash = true;
                case "-libPath", "--libPath":
                    libPaths.push(args.shift());
                case null:
                    break;
                case _ if (arg.charAt(0) == "-"):
                    Sys.println("Unknown argument: " + arg);
                    usage();
                    Sys.exit(1);
                case _ if (src.length == 0):
                    src.push(directory(arg));
                case _ if (dst.length == 0):
                    dst.push(directory(arg, Sys.getCwd() + "out"));
            }
        }
        if (dst.length == 0) {
            dst.push(directory(arg, Sys.getCwd() + "out"));
        }
        if (src == null) {
            usage();
            Sys.exit(1);
        }
    }

    static var reabs:EReg = ~/^([a-z]:|\\\\|\/)/i;
    
    static function directory(dir : String, alt = "."):String {
        if (dir == null)
            dir = alt;
        if(dir.endsWith("/") || dir.endsWith("\\"))
            dir = dir.substr(0, -1);
        if(!reabs.match(dir))
            dir = Sys.getCwd() + dir;
        dir = StringTools.replace(dir, "\\", "/");
        return dir;
    }

    /*
    public function toXmlString() : String {
        var s : String = "<as3hx>\r\n";
        //s += "\t<config>\r\n";
        //s += "\t\t<writeIndent value='" + escape(writeIndent)+ "' />\r\n";
        s += '</as3hx>';
        return s;
    }
    */

    public function fromXmlString(s:String):Void {
        var x = Xml.parse(s);
        fromXml(new Access(x.firstElement()));
    }

    public function fromXml(f:Access):Void {
        for(el in f.elements) {
            switch(el.name) {
            case "indentChars":         setCharField(el, "    ");
            case "newlineChars":        setCharField(el, "\n");
            case "bracesOnNewline":     setBoolField(el, true);
            case "spacesOnTypeColon":   setBoolField(el, true);
            case "uintToInt":           setBoolField(el, true);
            case "vectorToArray":       setBoolField(el, true);
            case "guessCasts":          setBoolField(el, true);
            case "functionToDynamic":   setBoolField(el, false);
            case "useFullTyping":       setBoolField(el, false);
            case "getterMethods":       setCharField(el, "get_%I");
            case "setterMethods":       setCharField(el, "set_%I");
            case "getterSetterStyle":   setCharField(el, "haxe", ["haxe","flash","combined"]);
            case "postProcessor":       setCharField(el, "%I");
            case "forcePrivateGetter":  setBoolField(el, true);
            case "forcePrivateSetter":  setBoolField(el, true);
            case "errorContinue":       setBoolField(el, true);
            case "testCase":            setBoolField(el, false);
            case "useOpenFlTypes":      setBoolField(el, false);
            case "replaceVarArgsWithOptionalArguments": setBoolField(el, false);
            case "verifyGeneratedFiles":setBoolField(el, false);
            case "flashTopLevelPackage":setCharField(el, "flash");
            case "excludeList":         setExcludeField(el, new List());
            case "libPaths":            setLibPaths(el, new Array<String>());
            case "conditionalCompilationList": setConditionalVars(el, new List());
            case "conditionalCompilationConstantsClass":setCharField(el, "");
            case "fixLocalVariableDeclarations":setBoolField(el, true);
            case "dictionaryToHash":    setBoolField(el, false);
            case "rebuildLocalFunctions": setBoolField(el, true);
            case "useAngleBracketsNotationForDictionaryTyping": setBoolField(el, true);
            case "useFastXML":          setBoolField(el, true);
            case "useCompat":           setBoolField(el, true);
            case "importPaths":         setImportPaths(el, []);
            case "importExclude":       setImportExclude(el, []);
            default:
                Sys.println("Unrecognized config var " + el.name);
            }
        }
    }

    function setBoolField(f:Access, defaultVal:Bool):Void {
        var val = defaultVal;
        if(f.has.value) {
            var c = f.att.value.toLowerCase().charAt(0);
            val = switch(c) {case "1","t","y":true; default:false;};
        }
        Reflect.setField(this, f.name, val);
    }

    function setCharField(f:Access, defaultVal:String, constrain:Array<String> = null):Void {
        if(constrain == null) constrain = [];
        var val = (f.has.value) ? f.att.value : defaultVal;
        if(constrain.length > 0) {
            var ok = false;
            for(s in constrain)
                if(s == val) { ok = true; break; }
            if(!ok) val = defaultVal;
        }
        Reflect.setField(this, f.name, unescape(val));
    }

    function setExcludeField(f:Access, defaultExcludes:List<String>):Void {
        excludePaths = defaultExcludes;
        for (file in f.nodes.path) {
            if (file.has.value) {
                excludePaths.add(file.att.value);
            }
        }
    }

    function setLibPaths(f:Access, defaultLibPaths:Array<String>):Void {
        libPaths = defaultLibPaths;
        for (dir in f.nodes.path) {
            if (dir.has.value) {
                libPaths.push(dir.att.value);
            }
        }
    }

    function setConditionalVars(f:Access, defaultVars:List<String>):Void {
        conditionalVars = defaultVars;
        for (conditionalVar in f.nodes.variable) {
            if (conditionalVar.has.value) {
                conditionalVars.add(conditionalVar.att.value);
            }
        }
    }

    function setImportPaths(f:Access, defaultVars:Array<String>):Void {
        importPaths = defaultVars;
        for (importPath in f.nodes.variable) {
            if (importPath.has.value) {
                importPaths.push(importPath.att.value);
            }
        }
    }

    function setImportExclude(f:Access, defaultVars:Array<String>):Void {
        importExclude = defaultVars;
        for (importPath in f.nodes.variable) {
            if (importPath.has.value) {
                importExclude.push(importPath.att.value);
            }
        }
    }

    public static function toPath(inPath:String):String {
        if (!isWindows())
            return inPath;
        var bits = inPath.split("/");
        return bits.join("\\");
    }

    public static function isWindows() : Bool {
        var os = Sys.systemName();
        return new EReg("window", "i").match(os);
    }

    static function escape(s:String):String {
        s = s.replace("\n", "\\n");
        s = s.replace("\r", "\\r");
        s = s.replace("\t", "\\t");
        return s;
    }

    static function unescape(s:String):String {
        s = s.replace("\\n", "\n");
        s = s.replace("\\r", "\r");
        s = s.replace("\\t", "\t");
        return s;
    }

    public static function defaultConfig():String {
        return
'<as3hx>
    <errorContinue value="true" />
    <indentChars value="\\t" />
    <newlineChars value="\\n" />
    <bracesOnNewline value="false" />
    <spacesOnTypeColon value="false" />
    <uintToInt value="true" />
    <vectorToArray value="true" />
    <guessCasts value="true" />
    <functionToDynamic value="false" />
    <useFullTyping value="true" />
    <getterMethods value="get_%I" />
    <setterMethods value="set_%I" />
    <forcePrivateSetter value="true" />
    <forcePrivateGetter value="true" />
    <!-- Style of getter and setter output. haxe, flash or combined -->
    <getterSetterStyle value="haxe" />
    <testCase value="false" />
    <useOpenFlTypes value="false" />
    <replaceVarArgsWithOptionalArguments value="false" />
    <flashTopLevelPackage value="flash"/>
    <excludeList />
    <conditionalCompilationList />
    <conditionalCompilationConstantsClass value="" />
    <fixLocalVariableDeclarations value="false" />
    <dictionaryToHash value="false" />
    <rebuildLocalFunctions value="true" />
    <useAngleBracketsNotationForDictionaryTyping value="true" />
    <verifyGeneratedFiles value="false" />
    <useFastXML value="true" />
    <useCompat value="true" />
    <postProcessor value="" />
    <libPaths></libPaths>
    <importPaths></importPaths>
    <importExclude></importExclude>
</as3hx>';
    }
}
