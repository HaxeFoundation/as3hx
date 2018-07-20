package;
import as3hx.Config;
import as3hx.ParserUtils;
import haxe.io.Path;
import sys.FileSystem;

/**
 * ...
 * @author
 */
class FileParser {
    private var cfg:Config;
    private var fileExtension:String;
    public function new(cfg:Config, fileExtension:String) {
        this.cfg = cfg;
        this.fileExtension = fileExtension;
        if (this.fileExtension.indexOf(".") != 0) this.fileExtension = "." + fileExtension;
    }


    public function parseDirectory(src:String, excludes:List<String>, handler:String->String->String->String->Void, relativeDestination:String = "/"):Void {
        src = Path.normalize(src);
        relativeDestination = Path.normalize(relativeDestination);
        var subDirList = new Array<String>();
        for(childName in FileSystem.readDirectory(src)) {
            var childPath = Path.addTrailingSlash(src) + childName;
            if (FileSystem.isDirectory(childPath)) {
                subDirList.push(childName);
            } else if(StringTools.endsWith(childName, fileExtension) && !isExcludeFile(excludes, childPath)) {
                handler(src, childName, childPath, relativeDestination);
            }
        }
        for (name in subDirList) {
            parseDirectory((Path.addTrailingSlash(src) + name), excludes, handler, (Path.addTrailingSlash(relativeDestination) + ParserUtils.escapeName(name)));
        }
    }


    static function isExcludeFile(excludes: List<String>, file: String) {
        return Lambda.filter(excludes, function (path) {
            return as3hx.Config.toPath(file).indexOf(StringTools.replace(path, ".", "\\")) > -1;
        }).length > 0;
    }

    public static function ensureDirectoryExists(dir:String):Void {
        var pathToCreate = [];
        while (!FileSystem.exists(dir) && dir != '') {
            var parts = dir.split("/");
            pathToCreate.unshift(parts.pop());
            dir = parts.join("/");
        }
        for (part in pathToCreate) {
            if (part == '')
                continue;
            dir += "/" + part;
            try {
                FileSystem.createDirectory(dir);
            } catch (e : Dynamic) {
                throw "unable to create dir: " + dir;
            }
        }
    }

}