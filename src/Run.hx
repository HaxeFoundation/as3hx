using StringTools;

import as3hx.As3.Program;
import as3hx.Config;
import as3hx.Error;
import as3hx.Writer;
import sys.FileSystem;
import sys.io.File;
using haxe.io.Path;

class Run {

    static var errors:Array<String> = [];
    static var warnings:Map<String, Map<String, Bool>> = new Map();
    static var cfg:as3hx.Config;
    static var writer:Writer;
    static var currentDstPath:String;
    static var files:Array<FileEntry> = [];

    public static function main():Void {
        Sys.setCwd(Sys.args().pop());
        cfg = new as3hx.Config();
        if (cfg.useFullTyping) {
            writer = new Writer(cfg);
        }
        var fileParser:FileParser = new FileParser(cfg, ".as");
        var libExcludes:List<String> = new List<String>();
        for (libPath in cfg.libPaths) {
            if (libPath == null) {
                Sys.println("lib path cannot be null");
            }
            fileParser.parseDirectory(libPath, libExcludes, parseLibFile);
        }
        for (i in 0...cfg.src.length) {
            var src:String = cfg.src[i];
            var dst:String = cfg.dst[i];
            if (src == null) {
                Sys.println("source path cannot be null");
            }
            if (dst == null) {
                Sys.println("destination path cannot be null");
            }
            currentDstPath = Path.removeTrailingSlashes(Path.normalize(dst));
            fileParser.parseDirectory(src, cfg.excludePaths, parseSrcFile);
        }
        //loop(cfg.src, cfg.dst, cfg.excludePaths);
        if (cfg.useFullTyping) {
            writer.prepareTyping();
            if (cfg.useOpenFlTypes) {
                for (f in files) {
                    writer.refineTypes(f.program);
                }
                for (f in files) {
                    writer.applyRefinedTypes(f.program);
                }
            }
            writer.finishTyping();
            for (f in files) {
                writeFile(f.name, f.program, cfg, f.f, f.src);
            }
        }
        Sys.println("");
        Writer.showWarnings(warnings);
        Sys.println("");
        if(errors.length > 0) {
            Sys.println("ERRORS: These files were not written due to source parsing errors:");
            for(i in errors)
                Sys.println(i);
        }
    }

    static function parseLibFile(fileLocation:String, fileName:String, file:String, relativeDestination:String):Void {
        Sys.println("import AS3 file: " + file);
        var program = parseFile(fileLocation, fileName, file);
        if (program == null) return;
        writer.register(program);
    }

    static function parseSrcFile(fileLocation:String, fileName:String, file:String, relativeDestination:String):Void {
        Sys.println("source AS3 file: " + file);
        var program = parseFile(fileLocation, fileName, file);
        if (program == null) return;
        var dst:String = currentDstPath + relativeDestination;
        FileParser.ensureDirectoryExists(dst);
        var resultPath = Path.addTrailingSlash(dst) + Writer.properCase(fileName.substr(0, -3), true) + ".hx";

        if (cfg.useFullTyping) {
            writer.register(program);
            files.push(new FileEntry(program, resultPath, fileName, fileLocation));
        } else {
            if (!cfg.useFullTyping) {
                writer = new Writer(cfg);
            }
            writeFile(resultPath, program, cfg, fileName, fileLocation);
        }
    }

    static function parseFile(fileLocation:String, fileName:String, file:String):Program {
        var p = new as3hx.Parser(cfg);
        var content = File.getContent(file);
        return try {
            p.parseString(content, fileLocation, fileName);
        } catch (e : Error) {
            #if macro
            File.stderr().writeString(file + ":" + p.tokenizer.line + ": " + errorString(e) + "\n");
            #end
            if (cfg.errorContinue) {
                errors.push("In " + file + "(" + p.tokenizer.line + ") : " + errorString(e));
                null;
            } else {
                #if neko
                    neko.Lib.rethrow("In " + file + "(" + p.tokenizer.line + ") : " + errorString(e));
                #elseif cpp
                    cpp.Lib.rethrow("In " + file + "(" + p.tokenizer.line + ") : " + errorString(e));
                    null;
                #end
            }
        }
    }

    static function errorString(e : Error):String {
        return switch(e) {
            case EInvalidChar(c): "Invalid char '" + String.fromCharCode(c) + "' 0x" + StringTools.hex(c, 2);
            case EUnexpected(src): "Unexpected " + src;
            case EUnterminatedString: "Unterminated string";
            case EUnterminatedComment: "Unterminated comment";
            case EUnterminatedXML: "Unterminated XML";
        }
    }

    static function writeFile(name:String, program:Program, cfg:Config, f:String, src:String):Void {
        Sys.println("target HX file: " + name);
        var fw = File.write(name, false);
        warnings.set(name, writer.process(program, fw));
        fw.close();
        if(cfg.postProcessor != "") {
            postProcessor(cfg.postProcessor, name);
        }
        if(cfg.verifyGeneratedFiles) {
            verifyGeneratedFile(f, src, name);
        }
    }

    static function postProcessor(?postProcessor:String = "", ?outFile:String = ""):Void {
        if(postProcessor != "" && outFile != "") {
            Sys.println("Running post-processor " + postProcessor + " on file: " + outFile);
            Sys.command(postProcessor, [outFile]);
        }
    }

    //if a .hx file with the same name as the .as file is found in the .as
    //file directory, then it is considered the expected output of the conversion
    //and is diffed against the actual output
    static function verifyGeneratedFile(file:String, src:String, outFile:String):Void {
        var test = src.addTrailingSlash() + Writer.properCase(file.substr(0, -3), true) + ".hx";
        if (FileSystem.exists(test) && FileSystem.exists(outFile)) {
            Sys.println("expected HX file: " + test);
            var expectedFile = File.getContent(test);
            var generatedFile = File.getContent(outFile);
            if (generatedFile != expectedFile) {
                Sys.println("Don't match generated file:" + outFile);
                Sys.command("diff", [test, outFile]);
            }
        }
    }
}

class FileEntry {
    public var program(default, null):Program;
    public var name(default, null):String;
    public var f(default, null):String;
    public var src(default, null):String;
    public function new(program:Program, name:String, f:String, src:String):Void {
        this.program = program;
        this.name = name;
        this.f = f;
        this.src = src;
    }
}