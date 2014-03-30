/*
 * Copyright (c) 2011, Russell Weir
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

package as3hx;

import haxe.xml.Fast;
import sys.FileSystem;
import sys.io.File;
import haxe.ds.StringMap;

using StringTools;

/**
 * Configuration object for as3hx
 * @author Russell Weir
 **/
class Config {
    /** Indent character(s) **/
    public var indentChars : String;
    /** newline character **/
    public var newlineChars : String;
    /** put open braces on new line **/
    public var bracesOnNewline : Bool;

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
    /** getter function template **/
    public var getterMethods : String;
    /** setter function template **/
    public var setterMethods : String;
    /** getter/setter output style **/
    public var getterSetterStyle : String;
    /** list of paths to exclude from parsing **/
    public var excludePaths : List<String>;
    /** Used only for test cases for compiler to ignore Sprite imports and extends **/
    public var testCase : Bool;
    /** conditional compilation variables **/
    public var conditionalVars: List<String>;
    /** Transform Dictionary.<Key, Value> to Map **/
    public var dictionaryToHash : Bool;
    /** write inferred type information into output **/
    public var debugInferredType : Bool;
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

    /** 
     * a list of absolute or relative directory paths.
     * Haxe files are found in this path and added to a map
     * of imported types used for implicit imports used
     * in converted code 
     */
    public var importPaths : Array<String>;

    /**
     * A map where the key is the name fo a Haxe type
     * and the value is its' fully qualified name, 
     * as found in one of the provided importPaths
     */
    public var importTypes : StringMap<String>;


    /** source directory **/
    public var src : String;
    /** output directory **/
    public var dst : String;

    var cfgFile : String;

    public function new() {

        init();

        processDefaultConfig();
        processEnvConfig();
        processLocalConfig();
        processCommandLine();
        processImportPaths();

    }

    public function init() {
        var env = Sys.environment();
        if (env.exists("AS3HX_CONFIG")) {
            cfgFile = env.get("AS3HX_CONFIG");
            return;
        }

                if (env.exists("TOOLROOT")) {
                        var toolroot = env.get("TOOLROOT");
                        cfgFile = toPath(toolroot + "/lib/as3tohx/as3hx_config.xml");
                        return;
                }

        var home = "";
        if (env.exists("HOME"))
            home = env.get("HOME");
        else if (env.exists("USERPROFILE"))
            home = env.get("USERPROFILE");
        else return;

        cfgFile = toPath(home+"/.as3hx_config.xml");
    }

    /**
     * Creates a getter function name based on a property
     * using the getterMethods template
     **/
    public function makeGetterName(id:String) :String {
        var s = getterMethods.replace("%I", ucfirst(id));
        s = s.replace("%i", id);
        return s;
    }

    /**
     * Creates a setter function name based on a property
     * using the setterMethods template
     **/
    public function makeSetterName(id:String) :String {
        var s = setterMethods.replace("%I", ucfirst(id));
        s = s.replace("%i", id);
        return s;
    }

    static function ucfirst(s : String)
    {
        return s.substr(0, 1).toUpperCase() + s.substr(1);
    }

    function processDefaultConfig() {
        fromXmlString(defaultConfig());
    }

    function processEnvConfig() {
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

    function processLocalConfig() {
        if(FileSystem.exists("./.as3hx_config.xml")) {
            fromXmlString(File.getContent("./.as3hx_config.xml"));
        }
    }

    /**
     * Store fuly qualified names of Haxe files found
     * at provided directories */
    function processImportPaths() {
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

    public static function usage() {
        var println = Sys.println;
        println("Usage: as3tohx [options] sourceDir [outdir]");
        println("\tOptions:");
        println("\t-no-cast-guess\tas3tohx will not try to handle MyClass(obj) casts");
        println("\t-no-func2dyn\twill not change Function types to Dynamic");
        println("\t-uint2int\ttransforms all uint to Int");
        println("\t-vector2array\twill convert Vectors to haxe Arrays");
        println("\t-debug-expr\twill output debug information");
        println("\t-debug-inferred-type\twill output inferred type debug information");
        println("\t-convert-flexunit\twill convert FlexUnit metadata and calls to munit form");
        println("\toutdir\t\tdefaults to './out'");
    }

    function processCommandLine() {
        var args = Sys.args().slice(0);
        var arg = "";
        while(true) {
            arg = args.shift();
            switch(arg) {
            case "-help", "--help":
                usage();
                Sys.exit(0);
            case "-uint2int", "--uint2int":
                uintToInt = true;
            case "-no-cast-guess", "--no-cast-guess":
                guessCasts = false;
            case "-vector2array", "--vector2array":
                vectorToArray = true;
            case "-debug-expr", "--debug-expr":
                debugExpr = true;
            case "-no-func2dyn", "--no-func2dyn":
                functionToDynamic = false;
            case "-error-continue","--error-continue":
                errorContinue = true;
            case "-test-case":
                testCase = true;
            case "-debug-inferred-type", "--debug-inferred-type":
                debugInferredType = true;
            case "-convert-flexunit", "--convert-flexunit":
                convertFlexunit = true;
            default:
                break;
            }
        }
        if(arg == null) {
            usage();
            Sys.exit(1);
        }
        src = Run.directory(arg);
        dst = Run.directory(args.shift(), "./out");
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

    public function fromXmlString(s:String) {
        var x = Xml.parse(s);
        fromXml(new Fast(x.firstElement()));
    }

    public function fromXml(f:Fast) {
        for(el in f.elements) {
            switch(el.name) {
            case "indentChars":         setCharField(el, "    ");
            case "newlineChars":        setCharField(el, "\n");
            case "bracesOnNewline":     setBoolField(el, true);
            case "uintToInt":           setBoolField(el, true);
            case "vectorToArray":       setBoolField(el, true);
            case "guessCasts":          setBoolField(el, true);
            case "functionToDynamic":   setBoolField(el, false);
            case "getterMethods":       setCharField(el, "get_%I");
            case "setterMethods":       setCharField(el, "set_%I");
            case "getterSetterStyle":   setCharField(el, "haxe", ["haxe","flash","combined"]);
            case "forcePrivateGetter":  setBoolField(el, true);
            case "forcePrivateSetter":  setBoolField(el, true);
            case "errorContinue":       setBoolField(el, true);
            case "testCase":            setBoolField(el, false);
            case "excludeList":         setExcludeField(el, new List());
            case "conditionalCompilationList": setConditionalVars(el, new List());
            case "dictionaryToHash":    setBoolField(el, false);
            case "useFastXML":          setBoolField(el, true);
            case "useCompat":          setBoolField(el, true);
            case "importPaths":          setImportPaths(el, []);
            default:
                Sys.println("Unrecognized config var " + el.name);
            }
        }
    }

    function setBoolField(f:Fast, defaultVal:Bool) {
        var val = defaultVal;
        if(f.has.value) {
            var c = f.att.value.toLowerCase().charAt(0);
            val = switch(c) {case "1","t","y":true; default:false;};
        }
        Reflect.setField(this, f.name, val);
    }

    function setCharField(f:Fast, defaultVal:String, constrain:Array<String> = null) {
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

    function setExcludeField(f:Fast, defaultExcludes:List<String>) {
        excludePaths = defaultExcludes;
        for (file in f.nodes.path) {
            if (file.has.value) {
                excludePaths.add(file.att.value);
            }
        }
    }

    function setConditionalVars(f:Fast, defaultVars:List<String>) {
        conditionalVars = defaultVars;
        for (conditionalVar in f.nodes.variable) {
            if (conditionalVar.has.value) {
                conditionalVars.add(conditionalVar.att.value);
            }
        }
    }

    function setImportPaths(f:Fast, defaultVars:Array<String>) {
        importPaths = defaultVars;
        for (importPath in f.nodes.variable) {
            if (importPath.has.value) {
                importPaths.push(importPath.att.value);
            }
        }
    }

    public static function toPath(inPath:String) {
        if (!isWindows())
            return inPath;
        var bits = inPath.split("/");
        return bits.join("\\");
    }

    public static function isWindows() : Bool {
        var os = Sys.systemName();
        return (new EReg("window","i")).match(os);
    }

    static function escape(s:String) {
        s = s.replace("\n", "\\n");
        s = s.replace("\r", "\\r");
        s = s.replace("\t", "\\t");
        return s;
    }

    static function unescape(s:String) {
        s = s.replace("\\n", "\n");
        s = s.replace("\\r", "\r");
        s = s.replace("\\t", "\t");
        return s;
    }

    public static function defaultConfig() {
        return
'<as3hx>
    <errorContinue value="true" />
    <indentChars value="    " />
    <newlineChars value="\\n" />
    <bracesOnNewline value="true" />
    <uintToInt value="true" />
    <vectorToArray value="true" />
    <guessCasts value="true" />
    <functionToDynamic value="false" />
    <getterMethods value="get_%I" />
    <setterMethods value="set_%I" />
	<forcePrivateSetter value="true" />
	<forcePrivateGetter value="true" />
    <!-- Style of getter and setter output. haxe, flash or combined -->
    <getterSetterStyle value="haxe" />
    <testCase value="false" />
    <excludeList />
    <conditionalCompilationList />
    <dictionaryToHash value="false" />
    <useFastXML value="true" />
    <useCompat value="true" />
    <importPaths></importPaths>
</as3hx>';
    }
}
