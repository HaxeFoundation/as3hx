package as3hx.parsers;

class IncludeParser {

    public static function parse(tokenizer:Tokenizer, path:String, filename:String, p:String, call:Void->Void) {
        var oldInput = tokenizer.input;
        var oldLine = tokenizer.line;
        var oldPath = path;
        var oldFilename = filename;
        var file = path + "/" + p;
        var parts = file.split("/");
        filename = parts.pop();
        path = parts.join("/");
        Debug.openDebug("Parsing included file " + file + "\n", tokenizer.line);
        if (!sys.FileSystem.exists(file)) throw "Error: file '" + file + "' does not exist, at " + oldLine;
        var content = sys.io.File.getContent(file);
        tokenizer.line = 1;
        tokenizer.input = new haxe.io.StringInput(content);
        try {
            call();
        } catch(e:Dynamic) {
            throw "Error " + e + " while parsing included file " + file + " at " + oldLine;
        }
        tokenizer.input = oldInput;
        tokenizer.line = oldLine;
        path = oldPath;
        filename = oldFilename;
        Debug.closeDebug("Finished parsing file " + file, tokenizer.line);
    }

}
