package as3hx;
import as3hx.As3.ClassDef;
import as3hx.As3.Program;

/**
 * ...
 * @author xmi
 */
class WriterImports
{
    public static function getImportWithMap(ident:String, allClasses:Map<String,Dynamic>, imports:Map<String,String>, currentPackage:String = null):String {
        if (imports.exists(ident)) return imports.get(ident);
        if (currentPackage != null) {
            var currentPackageIdent:String = currentPackage + "." + ident;
            if (allClasses.exists(currentPackageIdent)) {
                return currentPackageIdent;
            }
        }
        return null;
    }

    public static function getImport(ident:String, cfg:Config, allClasses:Map<String,Dynamic>, c:ClassDef, program:Program, currentPackage:String = null):String {
        for (e in c.meta) {
            switch(e) {
                case EImport(i):
                    var name:String = getImportString(cfg, i);
                    if (cfg.importExclude != null && cfg.importExclude.indexOf(name) != -1) {
                        continue;
                    }
                    if (i[i.length - 1] == ident && allClasses.exists(name)) return name;
                default:
            }
        }
        if (program != null) {
            for (i in program.imports) {
                var name:String = getImportString(cfg, i);
                if (cfg.importExclude != null && cfg.importExclude.indexOf(name) != -1) {
                    continue;
                }
                if (i[i.length - 1] == ident && allClasses.exists(name)) return name;
            }
            for (e in program.header) {
                switch(e) {
                    case EImport(i):
                        var name:String = getImportString(cfg, i);
                        if (cfg.importExclude != null && cfg.importExclude.indexOf(name) != -1) {
                            continue;
                        }
                        if (i[i.length - 1] == ident && allClasses.exists(name)) return name;
                    default:
                }
            }
        }
        var commons:Map<String,String> = CommonImports.getImports(cfg);
        if (commons.exists(ident)) return commons.get(ident);

        if (currentPackage == null && program != null) {
            currentPackage = program.pack.join(".");
        }
        if (currentPackage != null) {
            var currentPackageIdent:String = currentPackage + "." + ident;
            if (allClasses.exists(currentPackageIdent)) {
                return currentPackageIdent;
            }
        }
        return null;
    }

    public static function getImports(p:Program, cfg:Config, c:ClassDef):Map<String,String> {
        var map:Map<String, String> = new Map<String, String>();
        var common:Map<String,String> = CommonImports.getImports(cfg);
        for (key in common.keys()) {
            map.set(key, common.get(key));
        }
        if (p != null) {
            for (i in p.imports) {
                addImport(cfg, map, i);
            }
            for (e in p.header) {
                switch(e) {
                    case EImport(i):
                        addImport(cfg, map, i);
                    default:
                }
            }
        }

        for (e in c.meta) {
            switch(e) {
                case EImport(i):
                    addImport(cfg, map, i);
                default:
            }
        }
        return map;
    }

    static function addImport(cfg:Config, map:Map<String,String>, i:Array<String>):Void {
        var type:String = getImportString(cfg, i);
        if (cfg.importExclude != null && cfg.importExclude.indexOf(type) != -1) {
            return;
        }
        map.set(i[i.length - 1], type);
    }

    static function getImportString(cfg:Config, i : Array<String>) {
        if (i[0] == "flash") {
            i[0] = cfg.flashTopLevelPackage;
            return i.join(".");
        } else {
            return Writer.properCaseA(i, true).join(".");
        }
    }

}