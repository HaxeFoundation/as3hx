package as3hx;
import as3hx.As3.ClassDef;

/**
 * ...
 * @author d.skvortsov
 */
class InheritanceTypeParser
{
    public static function getParent(typer:Typer, child:ClassDef):ClassDef {
        switch (child.extend) {
            case null:
            case TPath(p):
                var parentClassString:String = typer.getImportString(p, true);
                var path:String = typer.resolveClassIdent(parentClassString);
                if (path == null) {
                    path = WriterImports.getImport(parentClassString, cfg, classes, child, null, parentPath.substring(0, parentPath.lastIndexOf(".")));
                }
                if (path != null) {
                    parentPath = path;
                    return classDefs.get(path);
                }
            default:
        }
        return null;
    }
}