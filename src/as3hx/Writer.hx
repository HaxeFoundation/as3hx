package as3hx;

import as3hx.As3;
import as3hx.RebuildUtils.RebuildResult;
import haxe.io.Output;

using Lambda;
using StringTools;

enum BlockEnd {
    None;
    Semi;
    Ret;
}

typedef CaseDef = {
    var vals : Array<Expr>;
    var el : Array<Expr>;
    var meta : Array<Expr>;
}

/**
 * @author Franco Ponticelli
 * @author Russell Weir
 */
class Writer
{
    var lvl : Int;
    var o : Output;
    var cfg : Config;
    var warnings : Map<String,Bool>; // warning->isError
    var loopIncrements : Array<Expr>;
    var varCount : Int; // vars added for ESwitch or EFor initialization
    var isInterface : Bool; // set if current class is an interface
    var inArrayAccess : Bool;
    var inEField : Bool;
    var inE4XFilter : Bool;
    var inLvalAssign : Bool; // current expr is lvalue in assignment (expr = valOfSomeSort)
    var rvalue : Expr;
    var functionReturnType : T;
    var typeImportMap : Map<String,String>;
    var lineIsDirty : Bool; // current line contains some non-whitespace/indent characters
    var pendingTailComment : String; // one line comment that needs to be written at the end of line
    var genTypes : Array<GenType>; //typedef generated while parsing
    var imported : Array<String>; // store written imports to prevent duplicated
    var pack : Array<String>; // stores the haxe file package
    var generatedTypesWritten:Bool;
    var validVariableNameEReg:EReg;
    var typer:Typer;
    var dictionaries:DictionaryRebuild;

    public function new(config:Config)
    {
        this.lvl = 0;
        this.cfg = config;
        this.varCount = 0;
        this.inArrayAccess = false;
        this.inEField = false;
        this.inE4XFilter = false;
        this.inLvalAssign = false;
        this.lineIsDirty = false;
        this.pendingTailComment = null;

        this.genTypes = [];
        this.imported = [];
        this.typer = new Typer(config);
        this.dictionaries = new DictionaryRebuild(typer, config);

        this.validVariableNameEReg = new EReg("^[a-zA-Z_$][0-9a-zA-Z_$]*$", "");
    }

    public function prepareTyping():Void {
        typer.parseParentClasses();
    }

    public function refineTypes(p:Program):Void {
        dictionaries.refineTypes(p);
        new SignalRebuild(cfg, typer).apply(p);
        new RebuildParentStaticFieldAccess(cfg, typer).apply(p);
    }

    public function applyRefinedTypes(p:Program):Void {
        dictionaries.applyRefinedTypes(p);
        new SignalRebuild(cfg, typer).apply(p);
        new CallbackRebuild(cfg, typer).apply(p);
    }

    public function finishTyping():Void {
        SignalRebuild.cleanup(cfg, typer);
    }

    public function register(p:Program):Void {
        typer.addProgram(p);
    }

    function formatComment(s:String, isBlock:Bool):String {
        if(!isBlock) {
            return s;
        }
        var a:Array<String> = s.split("\n");
        var spacesInTab:Int = 4;
        a[0] = StringTools.ltrim(a[0]);
        var n:Int = 999;
        var indent:String = this.indent();
        for (i in 1...a.length) {
            var p:Int = countWhitespaces(a[i]);
            if (p < n) n = p;
        }
        for (i in 1...a.length) {
            a[i] = indent + consumeWhitespaces(a[i], n);
        }
        return a.join("\n");
    }

    private function countWhitespaces(s:String):Int {
        var n:Int = 0;
        var i:Int = 0;
        do {
            if (s.indexOf("\t", i) == i) {
                n++;
                i++;
            } else if (s.indexOf("    ", i) == i) {
                n++;
                i += 4;
            } else {
                break;
            }
        } while (true);
        return n;
    }

    private function consumeWhitespaces(s:String, n:Int):String {
        var i:Int = 0;
        while (n > 0) {
            if (s.indexOf("\t", i) == i) {
                n--;
                i++;
            } else if (s.indexOf("    ", i) == i) {
                n--;
                i += 4;
            } else {
                break;
            }
        }
        return s.substr(i);
    }

    function formatBlockBodyRecursive(e:Expr, result:Array<Expr>):Void {
        switch(e) {
            case null:
            case EBlock(ex):
                for(i in 0...ex.length) {
                    if (i == 0) formatBlockBodyRecursive(ex[0], result);
                    else result.push(ex[i]);
                }
            case ENL(ex):
                if (ex != null) {
                    formatBlockBodyRecursive(ex, result);
                } else {
                    result.push(e);
                }
            case EObject(fl) if(fl.empty()):
            default: result.push(ENL(e));
        }
    }

    function formatBlockBody(expr:Expr):Array<Expr> {
        var result = [];
        formatBlockBodyRecursive(expr, result);
        return result;
    }

    inline function getColon():String return cfg.spacesOnTypeColon ? " : " : ":";

    function writeComments(comments : Array<Expr>) {
        for(c in comments) {
            switch(c) {
            case null:
            case ECommented(s, b, t, e):
                writeExpr(c);
                //writeComment(formatComment(s,b), b);
                //if (e != null) {
                    //switch (e) {
                        //case ECommented(_):
                            //writeComments([e]);
                        //case ENL(_):
                            //writeComments([e]);
                        //default:
                            //throw "Unexpected " + e + " in comments";
                    //}
                //}
            case EImport(i):
                writeImport(i);
            case ENL(e):
                writeExpr(c);
                //writeNL();
                //writeComments([e]);
            default:
                throw "Unexpected " + c + " in header";
            }
        }
    }

    function writePackage(pack : Array<String>)
    {
        if (pack.length > 0)
        {
            writeLine("package " + properCaseA(pack,false).join(".") + ";");
            writeNL();
        }
    }

    function writeImports(imports : Array<Array<String>>)
    {
        if (imports.length > 0)
        {
            for (i in imports) {
                writeImport(i);
                writeNL();
            }
            writeNL();
        }
    }

    function writeImport(i : Array<String>)
    {
        var type = typer.getImportString(i, true);
        if (cfg.importExclude != null && cfg.importExclude.indexOf(type) != -1) {
            var short:String = type.substr(type.lastIndexOf(".") + 1);
            var full:String = typeImportMap[short];
            if (full != null) {
                type = full;
            } else {
                return;
            }
        }
        if (!Lambda.has(this.imported, type)) { //prevent duplicate import
            write("import " + type + ";");
            imported.push(type);
            // do not add an implicit import for
            // this type since it has an explicit one.
            typeImportMap.set(i[i.length - 1], null);
        }
    }

    function writeAdditionalImports(defPackage : Array<String>, allTypes : Array<T>, definedTypes : Array<String>)
    {
        // We don't want to import any type that is defined within
        // this file, so add each of those to the type import map
        // first.
        for (d in definedTypes) {
            typeImportMap.set(d, null);
        }

        // Now convert each seen type enum into the corresponding
        // type import string.
        var uniqueTypes = new Map<String,Bool>();
        for (t in allTypes) {
            var importType = istring(t);
            if(importType != null) {
                if(!typeImportMap.exists(importType)) {
                    typeImportMap.set(importType, null);
                } else {
                    //var type = typer.getImportString(i, true);
                    //if (cfg.importExclude != null && cfg.importExclude.indexOf(type) != -1) {

                    uniqueTypes.set(importType, true);
                }
            } else {
                var full:String = tstring(t);
                var short:String = typer.shortenStringType(full);
                if (!typeImportMap.exists(short)) {
                    if (short != full) {
                        typeImportMap.set(short, full);
                        uniqueTypes.set(short, true);
                    }
                }
            }
        }

        // Now look up each type import string in the type import
        // map.
        var addnImports = new Array<String>();
        for(u in uniqueTypes.keys()) {
            if (typeImportMap.exists(u)) {
                var nu:String = typeImportMap.get(u);
                u = u == nu ? null : nu;
            } else {
                u = properCaseA(defPackage, false).concat([u]).join(".");
            }
            if (u != null)
                addnImports.push(u);
        }

        // Finally, if any additional implicit imports were found
        // to be needed, output them.
        if (addnImports.length > 0) {
            addnImports.sort(Reflect.compare);
            for(a in addnImports) {
                writeLine("import " + a + ";");
            }
        }
    }

    function writeDefinitions(defs : Array<Definition>)
    {
        for(d in defs)
            writeDefinition(d);
    }

    function writeDefinition(def : Definition)
    {
        switch(def)
        {
            case CDef(c): writeClassDef(c);
            case FDef(f): writeFunctionDef(f);
            case NDef(n): writeNamespaceDef(n);
        }
    }

    function writeMetaData(data:Array<Expr>) {
        if(data == null)
            return;

        var isFirstCondComp = true;

        for(d in data) {
            switch(d) {
            case EMeta(_):
                writeExpr(d);
            case ECommented(s, b, t, e):
                if (!t) {
                    writeExpr(d);
                }
            case ENL(e):
                writeNL();
                writeIndent();
            case ECondComp(v,e, e2):
                if (isFirstCondComp) {
                    write("#if ");
                    isFirstCondComp = false;
                }
                else {
                    write(" && ");
                }
                write(v);
            case EImport(i):
                writeImport(i);
            default:
                throw "Unexpected " + d;
            }
        }
    }

    function writeClassDef(c : ClassDef)
    {
        writeMetaData(c.meta);

        if (!generatedTypesWritten) {
            writeGeneratedTypes(genTypes);
            generatedTypesWritten = true;
        }

        var buf = new StringBuf();
        this.isInterface = c.isInterface;

        if (!c.isInterface && isFinal(c.kwds)) {
            buf.add("@:final ");
        }

        buf.add(c.isInterface ? "interface " : "class ");

        buf.add(properCase(c.name, true));
        if (c.typeParams != null) {
            buf.add(c.typeParams);
        }

        var parents = [];
        if (null != c.extend) {
            parents.push((isInterface ? "implements " : "extends ") + tstring(c.extend));
        }
        for (i in c.implement)
            parents.push((c.isInterface ? "extends " : "implements ") + tstring(i));
        if(parents.length > 0)
            buf.add(" " + parents.join(" "));
        buf.add(openb());
        write(buf.toString());
        lvl++;

        var path:String = (pack.length > 0 ? pack.join(".") + "." : "") + c.name;
        typer.setPackage(path.substr(0, path.lastIndexOf(".")));
        typer.setImports(typeImportMap, imported);
        typer.enterClass(path, c);

        // process properties
        writeProperties(c);

        // process fields
        writeFields(c);

        // a list of TId(ClassName),TSemicolon pairs that is used to force
        // compiling/linking classes
        writeInits(c);

        lvl--;
        write(closeb());

        //close conditional compilation block if needed
        writeECondCompEnd(getCondComp(c.meta));
    }

    function writeProperties(c : ClassDef)
    {
        var p = [];
        var h = new Map();
        var getOrCreateProperty = function(name, t, stat, internal)
        {
            var property = h.get(name);
            if (property == null)
            {
                property = {
                    name : name,
                    get : "never",
                    set : "never",
                    ret : t,
                    sta : stat,
                    internal : internal,
                    pub : false,
                    getMeta : null,
                    setMeta : null
                };
                p.push(property);
                h.set(name, property);
            }
            return property;
        }


        for (field in c.fields)
        {
            switch(field.kind)
            {
                case FFun( f ):
                    if (isOverride(field.kwds))
                        continue;
                    if (isGetter(field.kwds))
                    {
                        var getterDirective : String = "get"; // haxe 3
                                                              // haxe 2: cfg.makeGetterName(field.name);

                        var property = getOrCreateProperty(field.name, f.ret.t, isStatic(field.kwds), isInternal(field.kwds));
                        property.getMeta = field.meta;
                        if (isPublic(field.kwds))
                        {
                            property.get = getterDirective;
                            property.pub = true;
                        } else {
                            property.get = getterDirective;
                        }
                    }
                    else if (isSetter(field.kwds))
                    {
                        var setterDirective : String = "set"; // haxe 3
                                                              // haxe 2: cfg.makeSetterName(field.name);

                        var property = getOrCreateProperty(field.name, f.args[0].t, isStatic(field.kwds), isInternal(field.kwds));
                        property.setMeta = field.meta;
                        if (isPublic(field.kwds))
                        {
                            property.set = setterDirective;
                            property.pub = true;
                        } else {
                            property.set = setterDirective;
                        }
                    }
                default:
                    continue;
            }
        }

        if (p.length > 0) {
            writeNL();
        }

        if(cfg.getterSetterStyle == "haxe" || cfg.getterSetterStyle == "combined") {
            for (property in p)
            {
                writeIndent();
                //for insterface, func prototype will be removed,
                //so write meta on top of properties instead
                if (c.isInterface) {
                    writeMetaData(property.setMeta);
                    writeMetaData(property.getMeta);
                }

                if (property.internal)
                    writeAllow();
                if(cfg.getterSetterStyle == "combined")
                    write("#if !flash ");
                if (property.pub) {
                    write("public ");
                }
                else {
                    if (! isInterface) {
                        write("private ");
                    }
                }
                if (property.sta)
                    write("static ");
                write("var " + property.name + "(" + property.get + ", " + property.set + ")");
                writeVarType(property.ret);
                if(cfg.getterSetterStyle == "combined")
                    writeNL("; #end");
                else {
                    if (c.isInterface) { //if interface, newline handled be metadata
                        write(";");
                    }
                    else {
                        writeNL(";");
                    }
                }
            }
        }
        if (c.isInterface) {
            writeNL();
        }
    }

    function writeFields(c : ClassDef)
    {
        if (c.isInterface) {
            for (field in c.fields) {
                writeField(field, c);
            }
            return;
        }

        var constructor:Function = null;
        var constructorFieldInits:Array<Expr> = new Array<Expr>();
        var hasConstructor:Bool = false;
        var needConstructor:Bool = false;

        for (field in c.fields) {
            switch(field.kind) {
                case FFun ( f ):
                    if (!hasConstructor && field.name == c.name) {
                        constructor = f;
                        hasConstructor = true;
                    }
                case FVar(t, val):
                    if (val != null) {
                        var usingInstanceFields:Bool = false;
                        var rval = RebuildUtils.rebuild(val, function(e) {
                            switch(e) {
                                case EIdent(s):
                                    if (s == "this") {
                                        usingInstanceFields = true;
                                    } else {
                                        for (field in c.fields) {
                                            if (s == field.name && s != c.name) {
                                                if (!field.kwds.has("static")) {
                                                    usingInstanceFields = true;
                                                    return RebuildResult.RReplace(EField(EIdent("this"), s));
                                                }
                                                break;
                                            }
                                        }
                                    }
                                default:
                            }
                            return RebuildResult.RNull;
                        });
                        if (usingInstanceFields) {
                            if (rval == null) rval = val;
                            constructorFieldInits.push(ENL(EBinop("=", EField(EIdent("this"), field.name), rval, false)));
                            field.kind = FVar(t, null);
                        }
                    }
                default:
            }
            if (!needConstructor && !field.kwds.has("static")) {
                needConstructor = true;
            }
        }

        if (hasConstructor && constructorFieldInits.length > 0) {
            switch(constructor.expr) {
                case EBlock(e):
                    constructorFieldInits = constructorFieldInits.concat(e);
                default:
                    constructorFieldInits.push(constructor.expr);
            }
            constructor.expr = EBlock(constructorFieldInits);
        }


        for (field in c.fields) {
            writeField(field, c);
        }

        if (needConstructor && !hasConstructor) {
            writeNL();
            writeNL();
            writeIndent();
            if (isInternal(c.kwds)) {
                writeAllow();
                write("private ");
            }
            else {
                write("public ");
            }
            if (c.extend != null) {
                constructorFieldInits.push(ENL(ECall(EIdent("super"), [])));
            }
            var f:Function = {
                args : [],
                varArgs : null,
                ret : null,
                expr : EBlock(constructorFieldInits)
            }
            typer.enterFunction(f, c.name, c);
            writeConstructor(f, c.extend != null);
            typer.leaveFunction();
        }
    }

    function writeField(field : ClassField, c : ClassDef)
    {
        var isGet : Bool = isGetter(field.kwds);
        var isSet : Bool = isSetter(field.kwds);
        var isFun : Bool = switch(field.kind) {case FFun(_): true; default: false;};

        //if writing an Interface, get/set field will be added
        //as a property instead of func
        if ((isGet || isSet) && c.isInterface)
            return;

        var namespaceMetadata:Array<String> = null;
        if (isFun) {
            switch(field.kind) {
                case FFun(f): typer.enterFunction(f, field.name, c);
                default:
            };
        }
        var lookUpForNamespaces = function(e:Expr):RebuildResult {
            switch(e) {
                case ENamespaceAccess(e, f):
                    var type:String = typer.getExprType(e, true);
                    if (type == null) return null;
                    if (typeImportMap.exists(type)) {
                        var fullType:String = typer.getFullTypeName(type);
                        if (fullType != null) {
                            type = fullType;
                        }
                    }
                    if (namespaceMetadata == null) {
                        namespaceMetadata = [type];
                    } else if (namespaceMetadata.indexOf(type) == -1) {
                        namespaceMetadata.push(type);
                    }
                default:
            }
            return null;
        }

        var start = function(name:String, isFlashNative:Bool=false, isConstructor=false):Bool {
            if((isGet || isSet) && cfg.getterSetterStyle == "combined") {
                writeNL(isFlashNative ? "#if flash" : "#else");
                //writeNL("");
            }

            if(isFlashNative) {
                if(isGet) {
                    write("@:getter(");
                    write(name);
                    write(") ");
                } else if(isSet) {
                    write("@:setter(");
                    write(name);
                    write(") ");
                }
                if((isGet || isSet) && isProtected(field.kwds)) {
                    write("@:protected ");
                }
            }
            if(isFinal(field.kwds))
                write("@:final ");
            if (namespaceMetadata != null)
                for (m in namespaceMetadata)
                    write("@:access(" + m + ") ");
            if((isConstructor && isInternal(c.kwds)) || (!isInterface && isInternal(field.kwds)))
                writeAllow();
            if(isOverride(field.kwds))
                write((isFlashNative && (isGet || isSet)) ? "" : "override ");

            //coner-case, constructor of internal AS3 class is set to private in
            //Haxe with a meta allowing access from same package
            if(isConstructor && isInternal(c.kwds)) {
                write("private ");
            }
            else if(isPublic(field.kwds)) {
                if(!(isGet && cfg.forcePrivateGetter) //check if forced private getter
                    && !(isSet && cfg.forcePrivateSetter)) //check if forced private setter
                    write("public ");
                else if(!isInterface) {
                    write("private ");
                }
            }
            else if(!isInterface) {
                write("private ");
            }
            //check wheter the field is an AS3 constants, which can be inlined in Haxe
            //the field must be either a static constant or a private constant.
            //If it is a non-static public constant it can't be inlined as Haxe can only inline
            //static field. Converting non-static public field to static will likely cause compilation
            //errors, whereas it won't for private field as they will be accessed in the same way
            if(isStatic(field.kwds)) {
                write("static ");
                if(isConst(field.kwds)) {
                    switch(field.kind) {
                        case FVar(t, val) if(val != null):
                            //only constants (bool, string, int/float) field can
                            //be safely inlined for Haxe as we don't havve full typing
                            //available. For instance trying to inline a field referencing another
                            //static non-inlined field would prevent Haxe compilation
                            switch(val) {
                                case EConst(c): write("inline ");
								return true;
                                default:
                            }
                        default:
                    }
                }
            }
			return false;
        }
        switch(field.kind) {
            case FVar(t, val):
                writeMetaData(field.meta);
                var isInlined:Bool = start(field.name, false);
                write("var " + typer.getModifiedIdent(field.name));
                if (!isInlined && isConst(field.kwds)) {
                    if (val != null) {
                        write("(default, never)");
                    } else {
                        write("(default, null)"); // constants that depends on class fields will be initialized in constructor, so they are not actually constants
                    }
                }
                var type = tstring(t); //check wether a specific type was defined for this array
                if(isArrayType(type)) {
                    for (genType in this.genTypes) {
                        if (field.name == genType.fieldName) {
                            t = (TPath(["Array<" + genType.name + ">"]));
                        }
                    }
                }
                writeVarType(t);

                if (val == null) {
                    if (type == "Int") val = EConst(CInt("0"));
                    else if (type == "Bool") val = EIdent("false");
                }

                //initialise class property
                if(val != null) {
                    write(" = ");
                    lvl++; //extra indenting if init is on multiple lines
                    writeETypedExpr(val, t);
                    lvl--;
                }

                write(";");
            case FFun( f ):
                writeMetaData(field.meta);
                RebuildUtils.rebuild(f.expr, lookUpForNamespaces);
                if (field.name == c.name)
                {
                    start("new", false, true);
                    typer.enterFunction(f, c.name, c);
                    writeConstructor(f, c.extend != null);
                    typer.leaveFunction();
                } else {
                    var ret = f.ret;
                    var name = if (isGetter(field.kwds)) {
                        cfg.makeGetterName(field.name); //"get" + ucfirst(field.name);
                    } else if (isSetter(field.kwds)) {
                        ret.t = f.args[0].t;
                        cfg.makeSetterName(field.name); //"set" + ucfirst(field.name);
                    } else {
                        typer.getModifiedIdent(field.name);
                    }
                    if(isGetter(field.kwds) || isSetter(field.kwds)) {
                        // write flash native
                        if( cfg.getterSetterStyle == "flash" || cfg.getterSetterStyle == "combined") {
                            start(field.name, true);
                            writeFunction(f, isGetter(field.kwds), isSetter(field.kwds), true, name, ret);
                        }
                        // write haxe version
                        if( cfg.getterSetterStyle == "haxe" || cfg.getterSetterStyle == "combined") {
                            start(field.name, false);
                            writeFunction(f, isGetter(field.kwds), isSetter(field.kwds), false, name, ret);
                        }
                        if(cfg.getterSetterStyle == "combined") {
                            writeNL("#end");
                            writeNL("");
                        }
                    } else {
                        start(name, false);
                        writeFunction(f, isGetter(field.kwds), isSetter(field.kwds), false, name, ret, field.meta);
                    }
                }

            case FComment:
                writeComments(field.meta);
        }

        if (isFun) {
            typer.leaveFunction();
        }

        //if this field is not wrapped in conditional compilation,
        //do nothing
        if (field.condVars.length == 0)
            return;

        //here we will find wether this field is the last field
        //of some conditional compilation and write the conditional
        //compilation ending statement if it is
        var foundSelf = false;
        var condVars = field.condVars.copy();
        //loop in all the class field
        for (f in c.fields) {
            //once the current field was found
            if (foundSelf) {
                //check for each conditional compilation directive
                //wrapping the current field wheter the current field
                //is the last one for it
                for (condVar in condVars) {
                    //if it is not remove the conditional compilation constant
                    if (Lambda.has(f.condVars, condVar) && !hasCondComp(condVar, getECondComp(f.meta))) {
                        condVars.remove(condVar);
                    }
                }
                break;
            }
            else if (field == f) {
                foundSelf = true;
            }
        }

        //close conditional compilation block
        writeECondCompEnd(condVars);
    }

    /**
     * Return a new array containing all the conditional
     * compilation constants from the provided array
     */
    function getCondComp(exprs : Array<Expr>) : Array<String>
    {
        var condComps = [];
        for (expr in exprs)
        {
            switch (expr) {
                case ECondComp(v,e,e2):
                    condComps.push(v);
                default:
            }
        }
        return condComps;
    }

    /**
     * Return a new array containing all the conditional
     * compilation expressions from the provided array
     */
    function getECondComp(exprs : Array<Expr>) : Array<Expr>
    {
        var condComps = [];
        for (expr in exprs)
        {
            switch (expr) {
                case ECondComp(v,e,e2):
                    condComps.push(expr);
                default:
            }
        }
        return condComps;
    }

    /**
     * Return wether the provided array of expressions
     * contains a conditional compilation expr for the
     * condComp compilation constant
     */
    function hasCondComp(condComp : String, exprs : Array<Expr>) : Bool
    {
        for (expr in exprs)
        {
            switch (expr) {
                case ECondComp(v,e,e2):
                    if (condComp == v) {
                        return true;
                    }
                default:
            }
        }
        return false;
    }

    /**
     * Write closing statement ("#end") for conditional
     * conpilation if any
     */
    function writeECondCompEnd(condComps : Array<String>) : Void
    {
        for (i in 0...condComps.length) {
            writeNL();
            writeIndent("#end");
            if (cfg.verbouseConditionalCompilationEnd) {
                write(" // " + condComps[i]);
            }
        }
    }

    function writeArgs(args : Array<{ name : String, t : Null<T>, val : Null<Expr>, exprs : Array<Expr> }>, varArgs:String = null, functionExpressions:Array<Expr>)
    {
        if(varArgs != null && !cfg.replaceVarArgsWithOptionalArguments) {
            var varArg = {
                name:varArgs,
                t:TPath(["Array"]),
                val:EIdent("null"),
                exprs:[EIdent(varArgs), ETypedExpr(null, TPath(["Array"]))]
            }
            args = args.concat([varArg]);
        }
        //add 2 extra indentation level if arguments
        //spread on multiple lines
        lvl += 2;

        //store first argument
        var fst = null;

        //set to true at the end of the argument,
        //trigger writing a comma for next expression
        var pendingComma = false;

        for (arg in args) //for each method argument
        {
            if (arg.val != null) {
                switch (arg.val) {
                    case EField(_, _), EIdent("NaN"):
                        arg.t = TPath(["Null<" + tstring(arg.t) + ">"]);
                        functionExpressions.unshift(ENL(
                            EIf(EBinop("==", EIdent(arg.name), EIdent("null"), false),
                                EBinop("=", EIdent(arg.name), arg.val, false)
                            )
                        ));
                        arg.val = EIdent("null");
                    default:
                }
            }
            for (expr in arg.exprs) //for each expression within that argument
            {
                switch (expr) {
                    case EIdent(s):
                        if (s == arg.name) { //this is the start of a new argument
                            var isFirst = fst == null;
                            if (isFirst)
                            {
                                fst = arg; // no comma for the first
                            } else if (pendingComma) {
                                pendingComma = false;
                                write(",");
                            }

                            //if arg is not first element on the line, add space
                            //before it, unless first argument which never has space
                            if (lineIsDirty && !isFirst) {
                                write(" ");
                            }

                            write(s);
                        }
                    case ETypedExpr(_, t):
                        writeVarType(arg.t);
                        if(arg.val != null) {
                            write(" = ");
                            switch(tstring(t)) {
                                case "Int" if(needCastToInt(arg.val)):
                                    switch(arg.val) {
                                        case EConst(_ => CFloat(f)):
                                            var index = f.indexOf('.');
                                            if(index != -1) write(f.substring(0, index));
                                            else {
                                                index = f.indexOf('e');
                                                if(index != -1) {
                                                    var parts = f.split('e');
                                                    var lv = parts[0];
                                                    write(StringTools.rpad(lv, '0', lv.length + Std.parseInt(parts[1])));
                                                }
                                            }
                                        case _:
                                    }
                                case _: writeExpr(arg.val);
                            }
                        }
                        pendingComma = true;

                    case ENL(_): //newline
                        if (pendingComma) {
                            pendingComma = false;
                            write(",");
                        }
                        writeNL();
                        writeIndent();

                    case ECommented(s,b,t,e): // comment among arguments
                        writeComment(s, b);
                    default:

                }
            }
        }

        if (cfg.replaceVarArgsWithOptionalArguments) {
            // Adding workaround for (...params:Array)
            if (varArgs != null) {
                var varArgsNum:Int = 7;
                var argNum:Int = args.length;
                for (i in 1...varArgsNum + 1) {
                    if (argNum++ > 0) write(", ");
                        write('$varArgs$i:Dynamic = null');
                }

                if (functionExpressions.length > 0) {
                    functionExpressions[0] = ENL(functionExpressions[0]);
                }

                var callArgs:Array<Expr> = [];
                for (i in 1...varArgsNum + 1) {
                    callArgs.push(EIdent(varArgs + i));
                }
                functionExpressions.unshift(ENL(EVars([{
                    name:varArgs,
                    t:TPath(["Array<Dynamic>"]),
                    val:ECall(EIdent("as3hx.Compat.makeArgs"), callArgs)
                }])));
            }
        }

        lvl -= 2;
        return fst;
    }

    function writeConstructor(f:Function, isSubClass:Bool) {
        //add super if missing, as it is mandatory in Haxe for subclasses
        if (isSubClass && !constructorHasSuper(f.expr)) {
            switch(f.expr) {
                case EBlock(exprs):
                    exprs.unshift(ENL(ECall(EIdent("super"), [])));
                default:
            }
        }
        write("function new(");
        var es = formatBlockBody(f.expr);
        writeArgs(f.args, f.varArgs, es);
        writeCloseStatement();
        es = WriterUtils.moveFunctionDeclarationsToTheTop(es);
        es = WriterUtils.replaceForLoopsWithWhile(es);
        if (cfg.fixLocalVariableDeclarations) {
            es = new VarExprFix(cfg).apply(f, es, typer);
        }
        writeExpr(EBlock(es));
    }

    /**
     * Wether constructor method has a super() call
     */
    function constructorHasSuper(?expr : Expr) : Bool
    {
        if (expr == null) return false;
        var hasSuper:Bool = false;
        function rebuildHasSuper(e:Expr):RebuildResult {
            switch(e) {
                case EIdent("super"):
                    hasSuper = true;
                default:
            }
            return null;
        }
        RebuildUtils.rebuild(expr, rebuildHasSuper);
        return hasSuper;
    }

    inline function writeEContinue():BlockEnd {
        var result = Semi;
        if(loopIncrements != null && loopIncrements.length > 0) {
            var exp = loopIncrements.slice(0);
            exp.push(EIdent("continue"));
            result = writeExpr(EBlock(exp));
        } else {
            write("continue");
        }
        return result;
    }

    function writeFunction(f : Function, isGetter:Bool, isSetter:Bool, isNative:Bool, ?name : Null<String>, ?ret : FunctionRet, ?meta:Array<Expr>) {
        var oldFunctionReturnType:T = functionReturnType;
        functionReturnType = f.ret.t;

        // ensure the function body is in a block
        var es = f.expr != null ? formatBlockBody(f.expr) : [];

        write("function");
        if(name != null)
            write(" " + name);
        if (meta != null) {
            for (e in meta) {
                switch(e) {
                    case ECommented(s, b, t, e):
                        if (t) {
                            writeComment(s, b);
                        }
                    default:
                }
            }
        }
        write("(");
        writeArgs(f.args, f.varArgs, es);
        write(")");
        // return type
        if (ret == null)
            ret = f.ret;
        writeFunctionReturn(ret, isGetter, isSetter, isNative);
        var formatExpr:Expr->(Expr->Expr)->Expr = null;
        var formatBlock:Array<Expr>->(Expr->Expr)->Array<Expr> = function(exprs, getResult) {
            for(i in 0...exprs.length) {
                exprs[i] = formatExpr(exprs[i], getResult);
            }
            return exprs;
        }
        formatExpr = function(?e, getResult) {
            if(e == null) return null;
            return switch(e) {
                case EReturn(e): EReturn(getResult(e));
                case ENL(e): ENL(formatExpr(e, getResult));
                case EIf(cond, e1, e2): EIf(cond, formatExpr(e1, getResult), formatExpr(e2, getResult));
                case EFor(inits, conds, incrs, e): EFor(inits, conds, incrs, formatExpr(e, getResult));
                case EForIn(ev, e, block): EForIn(ev, e, formatExpr(block, getResult));
                case EForEach(ev, e, block): EForEach(ev, e, formatExpr(block, getResult));
                case EWhile(cond, e, doWhile): EWhile(cond, formatExpr(e, getResult), doWhile);
                case ETernary(cond, e1, e2): ETernary(cond, formatExpr(e1, getResult), formatExpr(e2, getResult));
                case ETry(e, catches): ETry(formatExpr(e, getResult), catches);
                case EBlock(e): EBlock(formatBlock(e, getResult));
                case ECommented(s, b, t, e): ECommented(s, b, t, formatExpr(e, getResult));
                default: e;
            }
        }
        if(isIntType(tstring(ret.t))) {
            formatBlock(es, function(?e) return e != null && needCastToInt(e) ? getCastToIntExpr(e) : e);
        }
        // haxe setters must return the provided type
        if(isSetter && !isNative && f.args.length == 1) {
            var result = EIdent(f.args[0].name);
            formatBlock(es, function(e) return result);
            es.push(ENL(EReturn(result)));
        }
        es = WriterUtils.moveFunctionDeclarationsToTheTop(es);
        es = WriterUtils.replaceForLoopsWithWhile(es);
        if (cfg.fixLocalVariableDeclarations) {
            es = new VarExprFix(cfg).apply(f, es, typer);
        }
        writeStartStatement();
        writeExpr(EBlock(es));
        functionReturnType = oldFunctionReturnType;
    }

    /**
     * Write the returned typed of a function and all
     * comments and newline until opening bracket
     */
    function writeFunctionReturn(ret:FunctionRet, isGetter : Bool, isSetter : Bool, isNative : Bool) {
        //write return type
        if(isNative) {
            if(isGetter) writeVarType(ret.t, "{}", true);
            if(isSetter) writeVarType(null, "Void", true);
        }
        else
            writeVarType(ret.t,null,false);

        //write comments after return type
        for (expr in ret.exprs) {
            switch (expr) {
                case ECommented(s, b, t, e):
                    writeComment(s, b);
                default:
            }
        }
    }

    inline function writeInComment(p:Dynamic):Void {
        write("/* " + p + " */");
    }

    inline function writeEReturn(?e:Expr) {
        write("return");
        if(e == null) return;
        write(" ");
        writeETypedExpr(e, functionReturnType);
    }

    function isArrayAccessable(etype:String):Bool {
        return isArrayType(etype) || isVectorType(etype) || isOpenFlDictionaryType(etype) || isMapType(etype) || isByteArrayType(etype);
    }

    function writeEArray(e:Expr, index:Expr) {
        //write("/* EArray ("+Std.string(e)+","+Std.string(index)+") " + Std.string(getExprType(e, true)) + "  */ ");
        var old = inArrayAccess;
        inArrayAccess = true;
        // this test can be generalized to any array[]->get() translation
        var etype = getExprType(e);
        var itype = getExprType(index);
        if(etype == "FastXML" || etype == "FastXMLList") {
            writeExpr(e);
            inArrayAccess = old;
            write(".get(");
            writeExpr(index);
            write(")");
        } else if(isMapType(etype)) {
            writeExpr(e);
            inArrayAccess = old;
            var oldInLVA = inLvalAssign;
            inLvalAssign = false;
            if (oldInLVA) {
                write(".set(");
            } else {
                write(".get(");
            }
            writeExpr(index);
            if (oldInLVA) {
                write(", ");
                writeExpr(rvalue);
                rvalue = null;
            }
            inLvalAssign = oldInLVA;
            write(")");
        } else {
            //write("/*!!!" + e + ":" + etype + "!!!*/");
            var oldInLVA = inLvalAssign;
            inLvalAssign = false;
            //oldInLVA = false;
            if (isArrayType(etype) || isVectorType(etype) || isOpenFlDictionaryType(etype) || isMapType(etype) || isByteArrayType(etype)/* || etype == "PropertyProxy"*/) {
                writeExpr(e);
                inArrayAccess = old;
                write("[");
                if (isOpenFlDictionaryType(etype) || isMapType(etype)) {
                    writeETypedExpr(index, TPath([typer.getMapIndexType(etype)]));
                } else {
                    writeETypedExpr(index, TPath(["Int"]));
                }
                write("]");
            } else {
                var isAnonymouse:Bool = isDynamicType(etype);
                if(cfg.debugInferredType) {
                    write("/* etype: " + etype + " itype: " + itype + " */");
                }
                var isString = (itype == "String");
                if(oldInLVA && !inEField)
                    write(isAnonymouse ? "Reflect.setField(" : "Reflect.setProperty(");
                else
                    write(isAnonymouse ? "Reflect.field(" : "Reflect.getProperty(");
                writeExpr(e);
                inArrayAccess = old;
                write(", ");
                if(!isString) write("Std.string(");
                writeExpr(index);
                if(!isString) write(")");
                //if (isAnonymouse) {
                    //writeInComment(rvalue);
                //}
                if(oldInLVA && !inEField) {
                    write(", ");
                    writeExpr(rvalue);
                    rvalue = null;
                }
                write(")");
            }
            //inLvalAssign = false;
            inLvalAssign = oldInLVA;
        }
    }

    function writeLoop(incrs:Array<Expr>, f:Void->Void) {
        var old = loopIncrements;
        loopIncrements = incrs.slice(0);
        f();
        loopIncrements = old;
    }

    static function ucfirst(s : String) : String
    {
        return s.substr(0, 1).toUpperCase() + s.substr(1);
    }

    function writeVarType(?t : Null<T>, ?alt : String, isNativeGetSet:Bool=false)
    {
        if (t == null)
        {
            if (alt != null)
                write(getColon() + alt);
            return;
        }
        write(getColon() + tstring(t, isNativeGetSet));
    }

    function writeInits(c : ClassDef) {
        if(c.inits == null || c.inits.length == 0)
            return;
        writeNL("");
        writeIndent();
        writeNL('private static var ${c.name}_static_initializer = {');
        lvl++;
        for(e in c.inits) {
            writeIndent();
            writeExpr(e);
            writeNL(";");
        }
        writeIndent("true;");
        writeNL();
        lvl--;
        writeIndent();
        writeNL("}");
    }

    function getConst(c : Const) : String
    {
        return switch(c)
        {
            case CInt(v), CFloat(v): v;
            case CString(s): quote(s);
        }
    }

    function getExprType(e:Expr, isFieldAccess:Bool = false):Null<String> {
        return typer.getExprType(e, isFieldAccess);
    }

    inline function getRegexpType():String return cfg.useCompat ? "as3hx.Compat.Regex" : "flash.utils.RegExp";

    /**
     * Returns the base variable from expressions like xml.user
     * EField(EIdent(xml),user) or EE4XDescend(EIdent(xml), EIdent(user))
     */
    function getBaseVar(e:Expr) : String {
        return switch(e) {
            case EField(e2, f): getExprType(e2);
            case EIdent(s): s;
            case EE4XDescend(e2, e3): getBaseVar(e2);
            default: throw "Unexpected " + e;
        }
    }

    function writeModifiedIdent(s : String) {
        write(typer.getModifiedIdent(s));
    }

    /**
     * Write an expression
     * @return if the block requires a terminating ;
     */
    function writeExpr(?expr : Expr) : BlockEnd {
        if(cfg.debugExpr) write(" /* " + Std.string(expr) + " */ ");
        if(expr == null) return None;
        var rv = Semi;
        switch(expr) {
            case ETypedExpr(e, t): rv = writeETypedExpr(e, t);
            case EConst(c): write(getConst(c));
            case EIdent(v): writeModifiedIdent(v);
            case EVars(vars): rv = writeEVars(vars);
            case EParent(e): writeEParent(e);
            case EBlock(e): rv = writeEBlock(e);
            case EField(e, f): rv = writeEField(expr, e, f);
            case EBinop(op, e1, e2, newLineAfterOp): rv = writeEBinop(op, e1, e2, newLineAfterOp);
            case EUnop(op, prefix, e): rv = writeEUnop(op, prefix, e);
            case ECall(e, params): rv = writeECall(expr, e, params);
            case EIf(cond, e1, e2): rv = writeEIf(cond, e1, e2);
            case ETernary(cond, e1, e2): writeETernarny(cond, e1, e2);
            case EWhile(cond, e, doWhile): rv = writeEWhile(cond, e, doWhile);
            case EFor(inits, conds, incrs, e): rv = writeEFor(inits, conds, incrs, e);
            case EForEach(ev, e, block): rv = writeEForEach(ev, e, block);
            case EForIn(ev, e, block): rv = writeEForIn(ev, e, block);
            case EBreak(label): write("break");
            case EContinue: rv = writeEContinue();
            case EFunction(f, name):
                typer.enterFunction(f, name);
                writeFunction(f, false, false, false, name);
                typer.leaveFunction();
            case EReturn(e): writeEReturn(e);
            case EArray(e, index): writeEArray(e, index);
            case EArrayDecl(e):
                var enl = false;
                write("[");
                for (i in 0...e.length) {
                    if (i > 0)
                        write(", ");
                    var ex = e[i];
                    writeExpr(ex);
                    if(!enl && (ex.match(ECommented(_,false,_,_)) || ex.match(ENL(_)))) enl = true;
                }
                if (enl) {
                    writeNL();
                    var step = Std.int(lvl / 2);
                    lvl -= step;
                    writeIndent();
                    lvl += step;
                }
                write("]");
            case ENew(t, params): writeENew(t, params);
            case EThrow( e ):
                write("throw ");
                function joinToString(params:Array<Expr>):Expr {
                    var r = params[0];
                    for (i in 1...params.length) {
                        r = EBinop("+", r, params[i], false);
                        if (i < params.length - 1) {
                            r = EBinop("+", r, EConst(CString(" ")), false);
                        }
                    }
                    return r;
                }
                switch (e) {
                    case ENew(t, params):
                        //var c = params.copy();
                        //c.unshift(EConst(CString(tstring(t) + ": ")));
                        var args:Array<Expr> = [EConst(CString(tstring(t)))];
                        if (params.length > 0) {
                            args.push(joinToString(params));
                        }
                        writeExpr(ENew(TPath(["XError"]), args));
                    case ECall(e1, params):
                        switch(e1) {
                            case EIdent(s):
                                var args:Array<Expr> = [EConst(CString(s))];
                                if (params.length > 0) {
                                    args.push(joinToString(params));
                                }
                                writeExpr(ENew(TPath(["XError"]), args));
                            default:
                                writeExpr(e);
                        }
                    default:
                        writeExpr(e);
                }
                //switch (e) {
                    //case ENew(t, params):
                        //var c = params.copy();
                        //c.unshift(EConst(CString(tstring(t) + ": ")));
                        //writeExpr(joinToString(c));
                    //case ECall(e1, params):
                        //switch(e1) {
                            //case EIdent(s):
                                //var c = params.copy();
                                //c.unshift(EConst(CString(s + ": ")));
                                //writeExpr(joinToString(c));
                            //default:
                                //writeExpr(e);
                        //}
                    //default:
                        //writeExpr(e);
                //}
            case ETry(e, catches): rv = writeETry(e, catches);
            case EObject(fl):
                if (fl.empty()) {
                    write("{ }");
                } else {
                    writeNL("{");
                    lvl++;
                    var length = fl.length;
                    for (i in 0...length) {
                        var field = fl[i];
                        if (i > 0) writeNL(",");
                        var field = fl[i];
                        writeIndent(prepareObjectFieldName(field.name) + (cfg.spacesOnTypeColon ? " : " : ": "));
                        writeExpr(field.e);
                    }
                    lvl--;
                    writeNL();
                    writeIndent("}");
                }
            case ERegexp(str, opts): write('new ${getExprType(expr)}(' + eregQuote(str) + ', "' + opts + '")');
            case ENamespaceAccess(e, f): writeExpr(e);
            case ESwitch( e, cases, def):
                var newCases : Array<CaseDef> = new Array();
                var writeTestVar = false;
                var testVar = switch(e) {
                case EParent(ex):
                    switch(ex) {
                        case EIdent(i): ex;
                        case ECall(_): ex;
                        default: null;
                    }
                default:
                    null;
                }
                if(testVar == null) {
                    writeTestVar = true;
                    testVar = EIdent("_sw"+(varCount++)+"_");
                }

                if (def != null) {
                    if (def.el.length > 0) {
                        var f:Expr->Array<Expr>->Void = null;
                        f = function(e, els) {
                            switch(e) {
                                case EBreak(lbl):
                                    if(lbl == null)
                                        def.el.pop(); // remove break
                                case EBlock(exprs):
                                    switch (exprs[exprs.length -1]) {
                                        case EBreak(lbl):
                                            def.el.pop();
                                        default:
                                    }
                                case ENL(e): f(e, els);
                                default:
                            }
                        }
                        f(def.el[def.el.length - 1], def.el);
                    }
                }

                if (def != null && def.before == null) {
                    // default is in the end
                    newCases = loopCases(cases.copy(), def.el.copy(), testVar, newCases);
                } else {
                    // default is not in the end, so don't catch fall-through
                    newCases = loopCases(cases.copy(), null, testVar, newCases);
                }

                if(writeTestVar) {
                    write("var ");
                    writeExpr(testVar);
                    write(" = ");
                    writeFinish(writeExpr(e));
                    writeIndent("");
                }

                //start the switch on a new line
                if (lineIsDirty) {
                    writeNL();
                    writeNL();
                    writeIndent();
                }

                write("switch (");
                writeExpr(testVar);
                write(")" + openb());

                lvl++;
                for(c in newCases) {

                    if(def != null &&
                        def.before != null &&
                        def.before.el.toString() == c.el.toString()) {
                            writeSwitchDefault(def);
                            def = null;
                    }

                    writeMetaData(c.meta); //write commnent and newline before "case"
                    write("case ");
                    for(i in 0...c.vals.length) {
                        write(i>0 ? ", " : "");
                        writeExpr(c.vals[i]);
                    }
                    write(":");

                    //prevent switch case indenting if begins
                    //with block expr
                    var didIndent = if (shouldIndentCase(c.el)) {
                        lvl++;
                        true;
                    } else {
                        false;
                    }

                    for (i in 0...c.el.length)
                    {
                        writeFinish(writeExpr(c.el[i]));
                    }
                    if (didIndent)
                        lvl--;
                }
                if(def != null) {
                    writeSwitchDefault(def);
                    def = null;
                }
                lvl--;
                write(closeb());
                rv = Ret;
            case EVector( t ):
                // Vector.<T> call
                // _buffers = Vector.<MyType>([inst1,inst2]);
                // t is TPath([inst1,inst2]), which should have been handled in ECall
                if (cfg.useOpenFlTypes && !cfg.vectorToArray) {
                    write("Vector<");
                    write(tstring(t, false, false));
                    write(">");
                } else {
                    write("Array/*Vector.<T> call?*/");
                    addWarning("Vector.<T>", true);
                }
            case EE4XAttr( e1, e2 ):
                // e1.@e2
                writeExpr(e1);
                if(inLvalAssign) {
                    write(".setAttribute(\"");
                    writeExpr(e2);
                    write("\", ");
                    var v = rvalue;
                    rvalue = null; // so case EBinop will not write rvalue
                    writeExpr(v);
                    write(")");
                }
                else {
                    write(".att.");
                    writeExpr(e2);
                }
                addWarning("EE4X");
            case EE4XFilter( e1, e2 ):
                // e1.(weight > 300) search
                writeE4XFilterExpr(e1, e2);
            case EE4XDescend( e1, e2 ):
                //write("/* " + e2 + " */");
                writeExpr(e1);
                write(".descendants(");
                switch(e2) {
                    case EIdent(id):
                        write(quote(id));
                    default:
                        writeExpr(e2);
                }
                write(")");
            case EXML( s ):
                //write("new flash.xml.XML(" + quote(s) + ")");
                write("FastXML.parse(" + quote(s) + ")");
                addWarning("EXML");
            case ELabel( name ):
                addWarning("Unhandled ELabel("+name+")", true);
            case ECommented(s, b, t, ex): rv = writeECommented(s,b,t,ex);
            case EMeta(m):
                if (!cfg.convertFlexunit || !writeMunitMetadata(m)) {
                    write("@:meta("+m.name+"(");
                    var first = true;
                    for(arg in m.args) {
                        if(!first)
                            write(",");
                        first = false;
                        if(arg.name != null)
                            write(arg.name + "=");
                        else
                            write("name=");
                        writeExpr(arg.val);
                    }
                    writeNL("))");
                }
            case ETypeof(e):
                switch(e) {
                case EBinop(op, e1, e2, n):
                    writeExpr(ETypeof(e1));
                    write(" " + op + " ");
                    writeExpr(e2);
                //case EIdent(id):
                default:
                    if (cfg.useCompat) {
                        write("as3hx.Compat.typeof(");
                        writeExpr(e);
                        write(")");
                    }
                    else {
                        throw "typeof can't be converted without the Compat class";
                    }
                }
                addWarning("ETypeof");
            case EDelete(e): writeEDelete(e);
            case ECondComp( kwd, e , e2):
                var writeECondComp:Expr->Void = null;
                writeECondComp = function(e) {
                    switch(e) {
                        case EBlock(elist):
                            for (ex in elist) {
                                writeBlockLine(ex);
                            }
                        case ENL(e):
                            writeECondComp(e);
                        case ECommented(s,b,t,e): writeECondComp(e);
                        default:
                            writeIndent();
                            writeFinish(writeExpr(e));
                    }
                }

                if (e == null) {
                    // compile time constant
                    if (cfg.conditionalCompilationConstantsClass != null && cfg.conditionalCompilationConstantsClass.length > 0) {
                        writeExpr(EField(EIdent(cfg.conditionalCompilationConstantsClass), kwd));
                    } else {
                        write(kwd);
                    }
                } else {
                    // conditional compilation block
                    write("#if " + kwd);
                    var oneLiner:Bool = isOneLiner(e, true);
                    if (oneLiner) {
                        write(" ");
                    }
                    writeECondComp(e);
                    if (oneLiner) {
                        write(" ");
                    } else {
                        writeNL();
                        writeIndent();
                    }
                    if (e2 != null) {
                        write("#else");
                        oneLiner = isOneLiner(e2, true);
                        if (oneLiner) {
                            write(" ");
                        }
                        writeECondComp(e2);
                        if (oneLiner) {
                            write(" ");
                        } else {
                            writeNL();
                            writeIndent();
                        }
                    }
                    write("#end");
                    if (cfg.verbouseConditionalCompilationEnd) {
                        write(" // " + kwd);
                    }
                }
                rv = Ret;

            case ENL(e):
                //newline starts new indented line before parsing
                //wrapped expression
                writeNL();
                writeIndent();
                rv = writeExpr(e);
            case EImport(s):
        }
        return rv;
    }

    function writeSwitchDefault(def:SwitchDefault) {
        if(def.vals != null && def.vals.length > 0) {
            writeNL();
            writeIndent();
            write("/* covers case ");
            for (i in 0 ... def.vals.length) {
                write(i>0 ? ", " : "");
                writeExpr(def.vals[i]);
            }
            write(":");
            write(" */");
        }

        var newMeta = [];
        var lastNL = false;
        for(d in def.meta) {
            switch(d) {
                case ENL(e):
                    if(!lastNL) newMeta.push(d);
                    lastNL = true;
                default:
                    lastNL = false;
                    newMeta.push(d);
            }
        }
        writeMetaData(newMeta); //write comment and newline before "default"
        write("default:");
        lvl++;
        for (i in 0...def.el.length)
        {
            writeFinish(writeExpr(def.el[i]));
        }
        lvl--;
    }

    function writeEBlock(e:Array<Expr>):BlockEnd {
        var result = Semi;
        if(!isInterface) {
            write("{");
            lvl++;
            for (ex in e) {
                writeBlockLine(ex);
                //writeFinish(writeETypedExpr(ex, TPath([null])));
            }
            lvl--;
            write(closeb());
            result = None;
        } else {
            write(";");
            result = None;
        }
        return result;
    }

    inline function fixBlockLine(e:Expr):Expr {
        switch(e) {
            case null:
                return null;
            case ENL(e):
                var fix = fixBlockLine(e);
                if (fix != null) {
                    return ENL(fix);
                } else {
                    return null;
                }
            case ECommented(s, isBlock, isTail, e):
                var fix = fixBlockLine(e);
                if (fix != null) {
                    return ECommented(s, isBlock, isTail, fix);
                } else {
                    return null;
                }
            case EBinop("&&", e1, e2, _):
                return EIf(e1, e2);
            case EBinop("||", e1, e2, _):
                return EIf(EUnop("!", true, e1), e2);
            default:
                return null;
        }
    }
    function writeBlockLine(e:Expr):Void {
        var fix = fixBlockLine(e);
        writeFinish(writeExpr(fix == null ? e : fix));
    }

    function writeEField(fullExpr:Expr, e:Expr, f:String):BlockEnd {
        var n = checkE4XDescendants(fullExpr);
        if(n != null) return writeExpr(n);
        var t1 = getExprType(fullExpr);
        var t2 = getExprType(e);
        //write("/* EField ("+Std.string(e)+","+Std.string(f)+") " +t1 + ":"+t2+ "  */\n");
        var old = inArrayAccess;
        if (t2 == "FastXMLList" && t1 == "FastXMLList") {
            writeExpr(ECall(EField(e, "descendants"), [EConst(CString(f))]));
        } else if(t1 == "FastXMLList" || (t1 == null && t2 == "FastXML")) {
            //write("/* t1 : " + t1 + " */");
            writeExpr(e);
            if(inArrayAccess)
                write(".nodes." + f);
            else
                //write(".node." + f + ".innerData");
                write(".node." + f);
        } else {
            if (t2 == "Date") {
                switch(f) {
                case "time"    : return writeExpr(ECall(EField(e, "getTime"), []));
                case "fullYear" : return writeExpr(ECall(EField(e, "getFullYear"), []));
                case "month"    : return writeExpr(ECall(EField(e, "getMonth"), []));
                case "day"      : return writeExpr(ECall(EField(e, "getDay"), []));
                case "date"      : return writeExpr(ECall(EField(e, "getDate"), []));
                case "hours"    : return writeExpr(ECall(EField(e, "getHours"), []));
                case "hoursUTC"    : return writeExpr(ECall(EField(e, "getHours/*UTC*/"), []));
                case "minutes"  : return writeExpr(ECall(EField(e, "getMinutes"), []));
                case "seconds"  : return writeExpr(ECall(EField(e, "getSeconds"), []));
                case "milliseconds": return writeExpr(EParent(EBinop("%", ECall(EField(e, "getTime"), []), EConst(CInt("1000")), false)));
                case "timezoneOffset": return writeExpr(getCompatCallExpr("getTimezoneOffset", []));
                case "getTimezoneOffset": return writeExpr(getCompatFieldExpr("getTimezoneOffset"));
                default:
                }
            }
            inEField = true;
            switch(e) {
                case EField(e2, f2):
                    //write("/* -- " +e2+ " " +getExprType(e2)+" */");
                    if(getExprType(e2) == "FastXML")
                        inArrayAccess = true;
                case EIdent(v):
                    switch(typer.getModifiedIdent(v)) {
                        case "Int":
                            if(f == "MAX_VALUE") {
                                writeExpr(getCompatFieldExpr("INT_MAX"));
                                return None;
                            }
                            if(f == "MIN_VALUE") {
                                writeExpr(getCompatFieldExpr("INT_MIN"));
                                return None;
                            }
                        case "Float":
                            if(f == "MAX_VALUE") {
                                writeExpr(getCompatFieldExpr("FLOAT_MAX"));
                                return None;
                            }
                            if(f == "MIN_VALUE") {
                                writeExpr(getCompatFieldExpr("FLOAT_MIN"));
                                return None;
                            }
                            if(f == "NaN" || f == "POSITIVE_INFINITY" || f == "NEGATIVE_INFINITY") {
                                writeExpr(EField(EIdent("Math"), f));
                                return None;
                            }
                        default:
                            if (f == "length") {
                                var type:String = getExprType(e);
                                if (type == "Function" || type == "haxe.Constraints.Function") {
                                    write("1 /*# of arguments of " + v + "*/");
                                    return None;
                                } else if (type != null && type.indexOf("->") != -1) {
                                    writeExpr(getCompatCallExpr("getFunctionLength", [e]));
                                    return None;
                                }
                            }
                    }
                case ECall(e, p):
                    switch(e) {
                        case EIdent(v):
                            if (v == "Object" && f == "constructor") {
                                return writeExpr(p[0]);
                            }
                        default:
                    }
                default:
            }
            writeExpr(e);
            write("." + f);
        }
        inEField = false;
        inArrayAccess = old;
        return Semi;
    }

    inline function writeEVars(vars:Array<{name:String, t:Null<T>, val:Null<Expr>}>):BlockEnd {
        var result = Semi;
        for(i in 0...vars.length) {
            if(i > 0) {
                writeNL(";");
                writeIndent();
            }
            var v = vars[i];
            var rvalue = v.val;
            if(rvalue != null) {
                switch(rvalue) {
                    case ETypedExpr(e,_):
                        switch(e) {
                            case EBinop("||=", e1,_,_):
                                writeExpr(e);
                                writeNL();
                                writeIndent();
                                rvalue = e1;
                            default:
                        }
                    default:
                }
            }
            var type = tstring(v.t);
            write("var " + typer.getModifiedIdent(v.name));
            writeVarType(v.t);
            if(rvalue != null) {
                write(" = ");
                writeExpr(rvalue);
                if(i == vars.length - 1) {
                    switch(rvalue) {
                        case ETypedExpr(e, _) if(e.match(EFunction(_, _))): result = None;
                        default:
                    }
                }
            }
        }
        return result;
    }

    inline function writeEParent(e:Expr) {
        switch(e) {
            case EParent(e): writeExpr(e);
            default:
                write("(");
                writeExpr(e);
                write(")");
        }
    }

    function writeECall(fullExpr:Expr, expr:Expr, params:Array<Expr>):BlockEnd {
        switch(expr) {
            case EField(expr, f):
                if ((f == "push" || f == "unshift") && params.length > 1 && (isArrayExpr(expr) || isVectorExpr(expr))) {
                    if (f == "unshift") {
                        params = params.copy();
                        params.reverse();
                    }
                    for(it in params) {
                        writeExpr(ECall(EField(expr, f), [it]));
                        write(";");
                        writeExpr(ENL(null));
                    }
                    return None;
                }
            default:
        }
        //write("/*ECall " + e + "(" + params + ")*/\n");
        //rebuild call expr if necessary
        var eCall = rebuildCallExpr(fullExpr, expr, params);
        if (eCall != null) {
            switch(eCall) {
                case ECall(e2, params2):
                    expr = e2;
                    params = params2;
                default:
                    return writeExpr(eCall);
            }
        }
        var f:Expr->Expr = null;
        f = function(e) return switch(e) {
            case EParent(e): f(e);
            default: e;
        }
        for(i in 0...params.length) params[i] = f(params[i]);

        //func call use 2 levels of indentation if
        //spread on multiple lines
        lvl += 2;

        var handled = false;
        if(cfg.guessCasts && params.length == 1) {
            switch(expr) {
                case EIdent(n):
                    var c = n.charCodeAt(0);
                    if(n.indexOf(".") == -1 && (c>=65 && c<=90) || c == 103) {
                        handled = true;
                        switch(n) {
                            case "Object": writeExpr(params[0]);
                            case "Number": writeCastToFloat(params[0]);
                            case "String": writeToString(params[0]);
                            case "Boolean":
                                if (getExprType(params[0]) == "Bool") {
                                    writeEParent(params[0]);
                                } else {
                                    write("AS3.as(");
                                    writeExpr(params[0]);
                                    write(", ");
                                    write("Bool)");
                                }
                            case "XML":
                                var type = tstring(TPath(["XML"]));
                                var ts:String = getExprType(params[0]);
                                if (ts != null && ts.indexOf("ByteArray") != -1) {
                                    write('$type.parseByteArray(');
                                } else {
                                    write('$type.parse(');
                                }
                                writeExpr(params[0]);
                                write(")");
                            case "getQualifiedClassName":
                                var t:String = getExprType(params[0]);
                                if (isClassType(t)) {
                                    writeExpr(ECall(EField(EIdent("Type"), "getClassName"), params));
                                } else if (t == "Dynamic" || t == null) {
                                    writeExpr(ECall(EField(EIdent("as3hx.Compat"), "getQualifiedClassName"), params));
                                } else { // regular type
                                    writeExpr(ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getClass"), params)]));
                                }
                                    //ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getSuperClass"), [e])]);

                            case "getQualifiedSuperclassName":
                                var t:String = getExprType(params[0]);
                                if (isClassType(t)) {
                                    writeExpr(ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getSuperClass"), params)]));
                                } else if (t == "Dynamic" || t == null) {
                                    writeExpr(ECall(EField(EIdent("as3hx.Compat"), "getQualifiedSuperclassName"), params));
                                } else { // regular type
                                    writeExpr(ECall(EField(EIdent("Type"), "getClassName"), [ECall(EField(EIdent("Type"), "getSuperClass"), [ECall(EField(EIdent("Type"), "getClass"), params)])]));
                                }
                            //case "": // Classes that needs to be converted to casts
                                //write("cast((");
                                //writeExpr(params[0]);
                                //write("), ");
                                //write(n + ")");
                            default:
                                handled = false;
                        }
                    }
                    // other cases that come up as ECall
                    switch(n) {
                        case "isNaN":
                            write("Math.isNaN(");
                            writeExpr(params[0]);
                            write(")");
                            handled = true;
                        case "isFinite":
                            write("Math.isFinite(");
                            writeExpr(params[0]);
                            write(")");
                            handled = true;
                        case "int" | "uint":
                            var t:String = getExprType(params[0]);
                            if (t == "Int" || t == "UInt") {
                                writeEParent(params[0]);
                            } else {
                                writeExpr(getCastToIntExpr(params[0]));
                            }
                            //writeCastToInt(params[0]);
                            handled = true;
                    }
                case EVector(t):
                    handled = true;
                    if(cfg.vectorToArray) {
                        writeExpr(params[0]);
                    } else if (cfg.useOpenFlTypes) {
                        var needCast:Bool = true;
                        switch(params[0]) {
                            case EArrayDecl(es):
                                if (es.length == 0) {
                                    write("new Vector<" + tstring(t) + ">()");
                                    needCast = false;
                                }
                            default:
                        }
                        if (needCast) {
                            write(cfg.arrayTypePath + ".ofArray(");
                            writeExpr(params[0]);
                            write(")");
                        }
                    }
                default:
            }
        }
        if (!handled) {
            switch(expr) {
                case EIdent(n):
                    var globalFunction:String = typer.isExistingIdent(n) ? null : typer.hasGlobalFunction(n);
                    if (globalFunction != null) {
                        //write(properCase(globalFunction, true) + ".");
                        write(n.charAt(0).toUpperCase() + n.substr(1) + ".");
                    } else {
                        var type:String = typer.getExprType(expr);
                        var className:String = type.substring(type.lastIndexOf(".") + 1);
                        if (type != "Function" && type != "haxe.Constraints.Function" && type.indexOf("->") == -1 && (className.charAt(0) == className.charAt(0).toUpperCase())) {
                            writeEBinop("as", params[0], expr, false);
                            handled = true;
                        }
                    }
                default:
            }
        }
        if (!handled) {
            var isArgument : Expr->Bool = null;
            isArgument = function(fullExpr) {
                return switch(fullExpr) {
                    case ECommented(s,b,t,expr): isArgument(expr);
                    case ENL(expr): isArgument(expr);
                    default: true;
                }
            }

            var tstring:String = typer.getExprType(expr);
            var types:Array<String> = tstring == null ? [] : tstring.split("->");
            writeExpr(expr);
            write("(");
            var enl = false;
            var hadArguments:Bool = false;
            for(i in 0...params.length) {
                var param = params[i];
                    var hasType:Bool = i < types.length - 1;
                    if (isArgument(params[i])) {
                        if (hadArguments) {
                            write(", ");
                        }
                        hadArguments = true;
                    }
                    switch(param) {
                        case EVector(t):
                            param = EIdent("Vector");
                        default:
                    }
                    if (hasType && param != null) {
                        writeETypedExpr(param, TPath([types[i]]));
                    } else {
                        writeExpr(param);
                    }
                if(!enl && (param.match(ECommented(_,false,true,_)) || param.match(ENL(_)))) enl = true;
            }
            if(enl) {
                writeNL();
                var step = Std.int(lvl / 2);
                lvl -= step;
                writeIndent();
                lvl += step;
            }
            write(")");
        }
        lvl -= 2;
        return Semi;
    }

    function writeEIf(cond:Expr, e1:Expr, ?e2:Expr):BlockEnd {
        var result = Semi;
        write("if (");
        lvl++; //extra indenting if condition on multiple lines
        var rb = rebuildIfExpr(cond);
        if(rb != null) {
            var f:Expr->Expr = null;
            f = function(e) return switch(e) {
                case EParent(e): f(e);
                default: e;
            }
            rb = f(rb);
            writeExpr(rb);
        } else writeExpr(cond);
        lvl--;

        //check if if expr is one line
        //with no block bracket
        if (isOneLiner(e1)) {
            switch (e1) {
                //if it is, start a new line
                //if present in formatting
                case ENL(e):
                    write(")");
                    writeNL();
                    e1 = e;
                    //add extra level of indent for
                    //teh one liner
                    lvl += 1;
                    writeIndent();
                    lvl -= 1;
                default:
                    write(") ");
            }
        } else writeCloseStatement();
        e1 = EBlock(formatBlockBody(e1));
        writeExpr(e1);
        if (e2 != null) {
            e2 = EBlock(formatBlockBody(e2));
            var elseif:Expr = null;
            // if we find an EBlock([ENL(EIf(...))])
            // after an `else` then we have an
            // `else if` statement
            switch(e2) {
                case EBlock(e3):
                    if (e3 != null && e3.length == 1) {
                        var e4 = ParserUtils.removeNewLineExpr(e3[0]);
                        var extraExpr:Expr = extractComments(e3[0]);
                        writeExpr(extraExpr);
                        switch(e4) {
                            case EIf(_, _, _):
                                // found single if statement after an else
                                // replace parent `block` + `new line` with
                                // the `if` statement instead so we stay on
                                // the same line as the `else` -> `else if`
                                elseif = e4;
                            case EBlock(_):
                                // catch double-nested blocks and replace
                                // outer block with inner block
                                e2 = e4;
                            default:
                        }
                    }
                case EIf(_, _, _):
                    elseif = e2;
                default:
            }
            //writeNL();
            if (elseif != null) {
                //writeIndent(" else ");
                write(" else ");
                result = writeExpr(elseif);
            } else {
                //writeIndent(" else");
                write(" else");
                writeStartStatement();
                result = writeExpr(e2);
            }
        } else {
            result = getEIfBlockEnd(e1);
        }
        return result;
    }

    inline function writeETernarny(cond:Expr, e1:Expr, ?e2:Expr):BlockEnd {
        write("(");
        var rb = rebuildIfExpr(cond);
        if(rb != null) writeExpr(rb);
        else writeExpr(cond);
        write(") ? ");
        writeExpr(e1);
        write(" : ");
        switch (e2) {
            case null:
            case EIdent("null"):
            default:
                if (getExprType(e1) == "String" && getExprType(e2) != "String") {
                    e2 = getToStringExpr(e2);
                }
        }
        return writeExpr(e2);
    }

    function getVarName(e:Expr):String {
        switch(e) {
            case EIdent(v): return v;
            case EVars(vars) if (vars.length > 0): return vars[0].name;
            default: return null;
        }
    }

    inline function writeEWhile(cond:Expr, e:Expr, doWhile:Bool):BlockEnd {
        var result:BlockEnd;
        var rcond:Expr = rebuildIfExpr(cond);
        if (rcond != null) {
            cond = rcond;
        }
        if (doWhile) {
            write("do");
            writeStartStatement();
            writeExpr(EBlock(formatBlockBody(e)));
            writeStartStatement();
            write("while (");
            result = writeExpr(cond);
            write(")");
        } else {
            write("while (");
            writeExpr(cond);
            writeCloseStatement();
            result = writeExpr(EBlock(formatBlockBody(e)));
        }
        return result;
    }

    inline function writeEFor(inits:Array<Expr>, conds:Array<Expr>, incrs:Array<Expr>, e:Expr):BlockEnd {
        //Sys.println('inits: ${inits}; conds: ${conds}; incrs: ${incrs}');
        for (i in 0...inits.length - 1) {
            var e:Expr = inits[i];
            writeExpr(ENL(e));
        }
        write("for (");
        switch(inits[inits.length - 1]) {
            case EVars(v):
                write(v[0].name);
                write(" in ");
                writeExpr(v[0].val);
                write("...");
            // var i:int = 0;
            // for (i = 0; i < size; i++)
            case EBinop(op, e1, e2, newLineAfterOp):
                if (op == "=") {
                    switch (e1) {
                        case EIdent(v):
                            write(v);
                        default:
                    }
                    write(" in ");
                    writeExpr(e2);
                    write("...");
                }
            default:
        }
        switch(conds[0]) {
            case EBinop(op, e1, e2, nl):
                switch(op) {
                    case ">", ">=":
                        var t:Expr = e1;
                        e1 = e2;
                        e2 = t;
                    default:
                }
                switch(op) {
                    //corner case, for "<=" binop, limit value should be incremented
                    case "<=", ">=":
                        switch(e2) {
                            case EConst(CInt(v)):
                                //increment int constants
                                var e = EConst(CInt(Std.string(Std.parseInt(v) + 1)));
                                writeExpr(e);
                            case _:
                                //when var used (like <= array.length), no choice but
                                //to append "+1"
                                writeExpr(e2);
                                write(" + 1");
                        }
                    case _: writeExpr(e2);
                }
                writeCloseStatement();
            default:
        }
        var es = formatBlockBody(e);
        writeLoop([], function() { writeExpr(EBlock(es)); });
        return None;
    }

    function getForEachType(type:String):String {
        if (isArrayType(type) || isVectorType(type)) {
            return Typer.getVectorParam(type);
        } else if (type == "FastXML" || type == "FastXMLList") {
            return type;
        } else if (isMapType(type) || isOpenFlDictionaryType(type)) {
            type = Typer.getMapParam(type, 1);
            if (type == null) {
                return "Dynamic";
            } else {
                return type;
            }
        } else {
            return "String";
        }
    }

    inline function writeEForEach(ev:Expr, e:Expr, block:Expr):BlockEnd {
        var t = getExprType(e);

        var isMap:Bool = isMapType(t);
        //var isArray:Bool = isArrayType(t) || isVectorType(t);
        //var isXml:Bool = t == "FastXML" || t == "FastXMLList";
        var isDictionary:Bool = isOpenFlDictionaryType(t);
        var isObject:Bool = t == "Object" || t == "openfl.utils.Object" || t == null || t == "Dynamic";
        var eValueType:String = getForEachType(t);

        write("for (");
        var castLoopVariableType:String = null;
        var varName:String = getVarName(ev);
        if (varName != null) {
            write(varName);
            var varType:String = getExprType(ev);
            if (varType != eValueType && (eValueType == "Dynamic" || typer.doImplements(varType, eValueType))) {
                // as we are supposing that this was a valid as3 code, we are trying to cast values to as3-defined type
                castLoopVariableType = varType;
                write("_");
            }
        } else {
            write("/* AS3HX ERROR unhandled " + e + " */");
            writeExpr(e);
        }
        write(" in ");
        var old = inArrayAccess;
        inArrayAccess = true;
        if (isDictionary) {
            writeExpr(ECall(EField(e, "each"), []));
        } else if (isObject) {
            write("as3hx.Compat.each(");
            writeExpr(e);
            write(")");
        } else {
            writeExpr(e);
        }
        inArrayAccess = old;
        writeCloseStatement();
        var es:Array<Expr> = formatBlockBody(block);
        if (castLoopVariableType != null) {
            es.unshift(ENL(EVars([{
                name:varName,
                t:TPath([castLoopVariableType]),
                //val:EBinop("as", EIdent(varName + "_"), EIdent(castLoopVariableType), false)
                val:EIdent("cast " + varName + "_")
            }])));
        }
        return writeExpr(EBlock(es));
    }

    function writeEForIn(ev:Expr, e:Expr, block:Expr):BlockEnd {
        var etype = getExprType(e);
        var canBeDictionary:Bool = isOpenFlDictionaryType(etype);
        var isMap:Bool = canBeDictionary || isMapType(etype);
        var isArray:Bool = isArrayType(etype) || isVectorType(etype);
        var castLoopVariableType:String = null;
        write("for (");
        var varName:String = getVarName(ev);
        if (varName != null) {
            write(varName);
            var varType:String = getExprType(ev);
            var mapKeyType:String;
            if (isMap) {
                mapKeyType = Typer.getMapParam(etype, 1);
            //} else if (isArray) {
                //mapKeyType = "Int";
            } else {
                mapKeyType = "String";
            }
            if (varType != mapKeyType && typer.doImplements(varType, mapKeyType)) {
                // as we are supposing that this was a valid as3 code, we are trying to cast values to as3-defined type
                castLoopVariableType = varType;
                write("_");
            }
        } else {
            write("/* AS3HX ERROR unhandled " + e + " */");
            writeExpr(e);
        }
        write(" in ");
        if (isMap) {
            writeExpr(e);
            if (!canBeDictionary) {
                write(".keys()");
            }
        } else if (isArray) {
            write("0...");
            writeExpr(e);
            write(".length");
        } else {
            write("Reflect.fields(");
            writeExpr(e);
            write(")");
        }
        writeCloseStatement();
        var es:Array<Expr> = formatBlockBody(block);
        if (castLoopVariableType != null) {
            es.unshift(EVars([{
                name:varName,
                t:TPath([castLoopVariableType]),
                val:EIdent(varName + "_")
            }]));
        }
        return writeExpr(EBlock(es));
    }

    function writeEBinop(op:String, e1:Expr, e2:Expr, newLineAfterOp:Bool):BlockEnd {
        if (op == "as") {
            var defaultCast:Bool = false;
            switch(e2) {
                case EIdent(s):
                    switch(s) {
                        case "String": writeToString(e1);
                        case "int", "Int", "uint", "UInt": writeCastToInt(e1);
                        case "Number": writeCastToFloat(e1);
                        case "Array":
                            write("AS3.asArray(");
                            writeExpr(e1);
                            write(")");
                        case "Class":
                            //addWarning("as Class", true);
                            write("as3hx.Compat.castClass(");
                            writeExpr(e1);
                            write(")");
                        case "Function":
                            addWarning("as Function", false);
                            write("cast ");
                            writeExpr(e1);
                        default:
                            if (s == "Dictionary" || s == "PropertyProxy" || s == "Object") {
                                write("AS3.as(");
                                writeExpr(e1);
                                write(", " + s + ")");
                            } else if (s == "ByteArray" || s == "Bitmap" || isVectorType(s) || s == "Dictionary") {
                                write("(try cast(");
                                writeExpr(e1);
                                write(", ");
                                switch(e2) {
                                    case EIdent(s): writeModifiedIdent(s);
                                    default: writeExpr(e2);
                                }
                                write(") catch(e:Dynamic) null)");
                            } else {
                                defaultCast = true;
                            }
                    }
                case EField(_):
                    defaultCast = true;
                case EVector(_):
                    if (cfg.useOpenFlTypes) {
                        write("as3hx.Compat.castVector(");
                        writeExpr(e1);
                        write(")");
                    } else {
                        write("try cast(");
                        writeExpr(e1);
                        write(", ");
                        write("Vector");
                        write(") catch(e:Dynamic) null");
                    }
                default: throw "Unexpected " + Std.string(e2);
            }
            if (defaultCast) {
                var e2t:String = typer.getExprType(e2, true);
                if (e2t == "Object" || e2t == "openfl.utils.Object" || e2t == "Dynamic") {
                    write("(cast ");
                    writeExpr(e1);
                    write(")");
                } else {
                    write("AS3.as(");
                    writeExpr(e1);
                    write(", ");
                    writeExpr(e2);
                    write(")");
                }
            }
        } else if (op == "is") {
            switch(e2) {
                case EVector(t) if (cfg.useOpenFlTypes):
                    write("as3hx.Compat.isVector(");
                    writeExpr(e1);
                    var ts:String = tstring(t);
                    if (ts != "Dynamic") {
                        write(", ");
                        write(ts);
                    }
                    write(")");
                case EIdent("Object"):
                    writeEBinop("!=", e1, EIdent("null"), false);
                default:
                    write("Std.is(");
                    writeExpr(e1);
                    write(", ");
                    writeExpr(e2);
                    write(")");
            }

        } else if (op == "in") {
            var type2:String = getExprType(e2);
            var result:Expr;
            if (isMapType(type2) || isOpenFlDictionaryType(type2)) {
                var rebuiltExpr = EField(e2, "exists");
                result = ECall(rebuiltExpr, [ETypedExpr(e1, TPath([typer.getMapIndexType(type2)]))]);
            } else if (isDynamicType(type2)) {
                //Reflect.hasField(e, f);
                result = ECall(EField(EIdent("Reflect"), "hasField"), [e2, e1]);
            } else {
                //(Type.getInstanceFields(Type.getClass(e)).indexOf(params[0]) != -1)
                result = EParent(EBinop("!=", ECall(EField(ECall(EField(EIdent("Type"), "getInstanceFields"), [ECall(EField(EIdent("Type"), "getClass"), [e2])]), "indexOf"), [e1]), EConst(CInt("-1")), false));
            }
            writeExpr(result);
        } else { // op e1 e2
            var eBinop = rebuildBinopExpr(op, e1, e2);
            if (eBinop != null) return writeExpr(eBinop);

            //if (op == "=") {
                //switch(e1) {
                    //case EArray(e, index):
                        //var etype:String = getExprType(e);
                        //if (!isArrayAccessable(etype)) {
                            //if (isDynamicType(etype)) {
                                //write("Reflect.setField(");
                            //} else {
                                //write("Reflect.setProperty(");
                            //}
                            //writeExpr(e);
                            //write(", ");
                            //writeETypedExpr(index, TPath(["String"]));
                            //write(")");
                        //}
                        //return Semi;
                    //default:
                //}
            //}

            var lookForRValue:Bool = true;
            var oldInLVA = inLvalAssign;
            if (op.indexOf("=") != -1 /*&& op != "=="*/ && op != "!=") {
                if (op == "=") inLvalAssign = true;
                rvalue = e2;
                var t = getExprType(e1);
                if (t != null) {
                    switch (e2) {
                        case null:
                        case EIdent("null"):
                        default:
                            e2 = ETypedExpr(e2, TPath([t]));
                    }
                }
            } else {
                switch(e1) {
                    case EArrayDecl(_): rvalue = e2;
                    case ECall(_, _): rvalue = e1;
                    case _:lookForRValue = false;
                }
            }

            switch(e1) {
                case EIdent(s): writeModifiedIdent(s);
                default: writeExpr(e1);
            }

            //for right part of indenting, add 2 extra
            //indenting level if spead on multiple lines
            if (op == "=")
                lvl += 2;

            inLvalAssign = oldInLVA;
            if(!lookForRValue || rvalue != null) {
                //check wether newline was found just before
                //op while parsing
                if (newLineAfterOp) {
                    writeNL();
                    writeIndent(op);
                } else {
                    write(" " + op);
                }

                //minor formatting fix, if right expression starts
                //with a newline or comment, no need for extra
                switch(e2) {
                    case ECommented(_,_,_,_):
                    case ENL(_):
                    default: write(" ");
                }
                switch(e2) {
                    case EIdent(s): writeModifiedIdent(s);
                    default: writeExpr(e2);
                }
            }

            if (op == "=")
                lvl -= 2;
        }
        return Semi;
    }

    function writeEUnop(op:String, prefix:Bool, e:Expr):BlockEnd {
        var result = Semi;
        var type = getExprType(e);
        switch(e) {
            case EField(a, "length") if (op == "++" || op == "--"):
                var type = getExprType(a);
                if (isVectorType(type)) {
                    if (op == "++") {
                        writeExpr(EBinop("+=", e, EConst(CInt("1")), false));
                    } else {
                        writeExpr(EBinop("-=", e, EConst(CInt("1")), false));
                    }
                    return result;
                }
            default:
        }
        if((isIntType(type) || type == "UInt") && op == "!") {
            writeExpr(EBinop("!=", e, EConst(CInt("0")), false));
            result = None;
        } else if(prefix) {
            write(op);
            writeExpr(e);
        } else {
            writeExpr(e);
            write(op);
        }
        return result;
    }

    function writeToString(e:Expr) {
        var type = getExprType(e);
        if (type != "String") {
            e = getToStringExpr(e);
        }
        writeExpr(e);
    }

    inline function getToStringExpr(e:Expr):Expr return ECall(EField(EIdent("Std"), "string"), [e]);

    function writeCastToInt(e:Expr) {
        var type = getExprType(e);
        if(type != "Int") {
            e = getCastToIntExpr(e);
        }
        writeExpr(e);
    }

    inline function needCastToInt(e:Expr):Bool {
        var isCompatParseInt:Expr->Bool = function(e) return e.match(ECall(EField(EIdent("AS3"), "int"), _));
        return switch(e) {
            case EBinop(op,e1,_,_): !isCompatParseInt(e1) && (isBitwiseOp(op) || isNumericOp(op));
            case EUnop(op,_,e): op == "~" && !isCompatParseInt(e);
            case EIdent(_) | EConst(_): getExprType(e) == "Float";
            case EParent(e): needCastToInt(e);
            case _: false;
        }
    }

    function getCastToIntExpr(e:Expr):Expr {
        if(cfg.useCompat) {
            return ECall(EField(EIdent("AS3"), "int"), [e]);
        }
        return ECall(EField(EIdent("Std"), "parseInt"), [getToStringExpr(e)]);
    }

    function writeCastToFloat(e:Expr) {
        var type = getExprType(e);
        if (type != "Float" && type != "Int") {
            e = getCastToFloatExpr(e);
        }
        writeExpr(e);
    }

    function getCastToFloatExpr(e:Expr):Expr {
        if (cfg.useCompat) {
            return getCompatCallExpr("parseFloat", [e]);
        }
        return ECall(EField(EIdent("Std"), "parseFloat"), [getToStringExpr(e)]);
    }

    inline function getCompatCallExpr(methodName:String, params:Array<Expr>):Expr {
        return ECall(getCompatFieldExpr(methodName), params);
    }

    inline function getCompatFieldExpr(fieldName:String):Expr {
        return EField(EIdent("as3hx.Compat"), fieldName);
    }

    // translate FlexUnit to munit meta data, if present.
    function writeMunitMetadata(m:Metadata) : Bool {
        var rv : Bool = false;
        switch (m.name) {
            case "BeforeClass", "AfterClass":
                write("@" + m.name);
                if (m.args.length > 0) {
                    addWarning("Metadata parameters on " + m.name + " ignored: " + Std.string(m.args));
                }
                rv = true;
            case "Before", "After":
                //special case, for those, write the "order" attribute if present, as an annotation in comments
                for (arg in m.args) {
                    if (arg.name == "order") {
                        write("// order=");
                        writeExpr(arg.val);
                        writeNL();
                        writeIndent();
                        break;
                    }
                }

                write("@" + m.name);
                rv = true;
            case "Ignore":
                write("@Ignore");
                if (m.args.length > 0) {
                    write("(");
                    var first = true;
                    for (arg in m.args) {
                        if (!first) {
                            write(",");
                            first = false;
                        }
                        if (arg.name == null) {
                            writeExpr(arg.val);
                        } else {
                            addWarning("Metadata parameter on " + m.name + " ignored: " + Std.string(arg));
                        }
                    }
                    write(")");
                }
                rv = true;
            case "Test":
                var testTag:String = "Test";
                var args:Array<Expr> = [];
                var dumpArgs = [];
                for (arg in m.args) {
                                    if (arg.name != null) {
                                        switch (arg.name) {
                                            case "description":
                                                args.push(arg.val);
                                                continue;
                                            case "dataProvider":
                                                write("@DataProvider(");
                                                writeExpr(arg.val);
                                                writeNL(")");
                                                writeIndent();
                                                continue;
                                            default:
                                                dumpArgs.push(arg);
                                        }
                                    } else {
                                        switch (arg.val) {
                                            case EIdent(i):
                                                switch(i) {
                                                    case "async":
                                                        testTag = "AsyncTest";
                                                        continue;
                                                    case "ui":
                                                        addWarning("UiImpersonator flexunit tests not supported", true);
                                                        continue;
                                                }
                                            default:
                                                trace("unknown value " + arg.val);
                                        }
                                    }
                                    addWarning("Metadata parameter on " + m.name + " ignored: " + Std.string(arg));
                }
                write("@" + testTag);
                if (args.length > 0) {
                    write("(");
                    var first = true;
                    for (arg in args) {
                        if (!first) {
                            write(",");
                            first = false;
                        }
                        writeExpr(arg);
                    }
                    write(")");
                }

                //dump args not used in commented line
                if (dumpArgs.length > 0) {
                    writeNL();
                    writeIndent();
                    write("//");
                    var first = true;
                    for (arg in dumpArgs) {
                        if (!first) {
                            write(", ");
                            first = false;
                        }
                        if (arg.name != null) {
                            write(arg.name);
                            write("=");
                        }
                        writeExpr(arg.val);
                    }
                }
                rv = true;
            case "Theory":
                addWarning("Theory flexunit tests not supported", true);
        }
        return rv;
    }

    // as3
    // xml.user.(@user_id == 3);
    // to haxe
    //XMLFast.filterNodes(xml.nodes.user,
    //  function(x) {
    //      if(x.att.user_id == 3)
    //          return true;
    //      return false;
    //  });
    // e1.(@user_id == 3) attribute search
    function writeE4XFilterExpr(e1:Expr, e2:Expr) {
        if(inE4XFilter)
            throw "Unexpected E4XFilter inside E4XFilter";

        write("FastXML.filterNodes(");
        //write("/*"+Std.string(e1)+"*/");
        var n = getBaseVar(e1);    // make sure it's set to FastXML in the
        var old = inArrayAccess;
        inArrayAccess = true; // ensure 'nodes' vs. 'node'
        writeExpr(e1);
        inArrayAccess = old;

        inE4XFilter = true;
        write(", function(x:FastXML) {\n");
        lvl++;
        writeIndent("if(");
        var ee = rebuildE4XExpr(e2);
        //write("/* "+e2+" rebuilt: " + ee + " */\n");
        writeExpr(ee);
        writeNL(")");
        lvl++;
        writeLine("return true;");
        lvl--;
        writeLine("return false;\n");
        lvl--;
        writeIndent("})");
        inE4XFilter = false;
    }

    function writeECommented(s:String, isBlock:Bool, isTail:Bool, e:Expr, ?delimiter:String):BlockEnd {
        var writeDelimiter = function() {
            if(delimiter == null) return;
            lineIsDirty = false;
            write(delimiter);
            lineIsDirty = false;
        }
        var result:BlockEnd = Semi;
        if(isTail) {
            result = writeExpr(e);
            writeDelimiter();
        }
        writeComment(formatComment(s, isBlock), isBlock);
        if(!isTail) {
            writeDelimiter();
            result = writeExpr(e);
        }
        if(e == null) result = Ret;
        return result;
    }

    private inline function writeDictionaryTypeConstructor(k:String, v:String):Void {
        //write("new ");
        //if (k == "Dynamic" || k == "Object" || k == "openfl.utils.Object") {
            //if (k == "Object" || k == "openfl.utils.Object") k = "Dynamic";
            //write("haxe.ds.ObjectMap<" + k + ", ");
        //} else if (k == "Float" || k == "Class<Dynamic>" || k == "Class") {
            //write("Dictionary<" + k + ",");
        //} else {
            //write("Map<" + k + ",");
        //}
        //write(v + ">(");
        if (k == "Dynamic") k = "Object";
        write("new Dictionary<" + k + "," + v + ">(");
    }

    inline function writeENew(t : T, params : Array<Expr>):Void {
        var writeParams = function() {
            var argTypes:Array<T> = typer.getClassConstructorTypes(tstring(t));
            for(i in 0...params.length) {
                if(i > 0)
                    write(", ");
                var param:Expr = params[i];
                switch(param) {
                    case EVector(t):
                        param = EIdent("Vector");
                    default:
                }
                if (argTypes != null && i < argTypes.length) {
                    writeETypedExpr(param, argTypes[i]);
                } else {
                    writeExpr(param);
                }
            }
        }
        switch(t) {
            case TComplex(e):
                var pack:Array<String> = typer.getPackString(e);
                if (pack != null) {
                    t = TPath(pack);
                }
            default:
        }
        var isVariable:Bool = false;
        var handled = false;
        switch(t) {
            case TPath(p) if (p.length == 1 && typer.isVariable(p[0])): isVariable = true;
            default:
        }
        if(isVariable) {
            write("Type.createInstance(");
            write(tstring(t, false, false));
            write(", [");
            writeParams();
            write("])");
            handled = true;
        }
        //in AS3, if Date constructed without argument, uses current time
        else if (tstring(t) == "Date") {
            if (params.length == 0) {
                write("Date.now()"); //use Haxe constructor for current time
                handled = true;
            } else if (params.length == 1) {
                write("Date.fromTime(");
                writeParams();
                write(")");
                handled = true;
            } else {
                while (params.length < 6) {
                    params.push(EConst(CInt("0")));
                }
            }
        }
        var isObject = false;
        var isDictionary = false;
        if (!handled) {
            switch(t) {
                case TDictionary(k, v):
                    if (cfg.useOpenFlTypes && !cfg.dictionaryToHash) {
                        var ks:String = tstring(k);
                        var kv:String = tstring(v);
                        writeDictionaryTypeConstructor(ks, kv);
                        isDictionary = true;
                    }
                case TPath(p) if (p[0] == "Object" || p[0] == "openfl.utils.Object"): isObject = true;
                case TPath(p) if (p[0] == "ByteArray" || p[0] == "openfl.utils.ByteArray"):
                    writeExpr(getCompatCallExpr("newByteArray", params));
                    handled = true;
                case TPath(p):
                    if (isOpenFlDictionaryType(p[0])) {
                        var ks:String = Typer.getMapParam(p[0], 0);
                        var kv:String = Typer.getMapParam(p[0], 1);
                        writeDictionaryTypeConstructor(ks, kv);
                        isDictionary = true;
                    }
                default:
            }
        }
        if (!handled) {
            if (isObject) write("{}");
            else if (isDictionary) {
            }
            else write("new " + tstring(t) + "(");
            // prevent params when converting vector to array
            var out = switch(t) {
                case TVector(_): !cfg.vectorToArray;
                case TDictionary(_, _): !cfg.dictionaryToHash;
                case TPath(p): !(p[0] == "Array");
                default: true;
            }
            if (isDictionary && params.length > 0) write("/*");
            if (out) writeParams();
            if (isDictionary && params.length > 0) write("*/");
            if (!isObject) write(")");
        }
    }

    inline function writeETry(e:Expr, catches:Array<{name:String, t:Null<T>, e:Expr}>):BlockEnd {
        var result = Semi;
        write("try");
        writeStartStatement();
        e = EBlock(formatBlockBody(e));
        writeExpr(e);
        for(it in catches) {
            writeStartStatement();
            write("catch (" + it.name);
            writeVarType(it.t, "Dynamic");
            writeCloseStatement();
            e = EBlock(formatBlockBody(it.e));
            result = writeExpr(e);
        }
        return result;
    }

    function isOpenFlDictionaryTypeT(t:T):Bool {
        switch (t) {
            case TDictionary(_, _): return true;
            case TPath(p):
                if (p.length == 1) {
                    if (p[0].indexOf("Dictionary") == 0 || p[0].indexOf("openfl.utils.Dictionary") == 0) {
                        return true;
                    }
                } else if (p.length == 3) {
                    if (p[0] == "openfl" && p[1] == "utils" && p[2].indexOf("Dictionary") == 0) {
                        return true;
                    }
                }
            default:
        }
        return false;
    }

    function writeETypedExpr(e:Expr, t:T):BlockEnd {
        var nullable:Bool = false;
        switch(e) {
            case null:
                write("intended error: ETypedExpr(null as " + tstring(t) + ")");
                return None;
            case ENL(e2):
                writeNL();
                writeIndent();
                return writeETypedExpr(e2, t);
                //return writeExpr(ENL(ETypedExpr(e2, t)));
            case ECommented(s, isBlock, isTail, e2):
                return writeECommented(s, isBlock, isTail, ETypedExpr(e2, t));
            case ETernary(cond, e1, e2):
                return writeETernarny(cond, ETypedExpr(e1, t), ETypedExpr(e2, t));
            case ENew(t2, params):
                if (isOpenFlDictionaryTypeT(t2) && isOpenFlDictionaryTypeT(t)) {
                    return writeExpr(ENew(typer.shortenType(t), params));
                }
            case EField(e, field):
                var t:String = getExprType(e);
                if (isDynamicType(t)) {
                    nullable = true;
                }
            case EArray(e, index):
                var t:String = getExprType(e);
                if (isMapType(t) || isOpenFlDictionaryType(t)) {
                    nullable = true;
                }
            case EIdent("null"):
                switch(tstring(t)) {
                    case "String":
                        return writeExpr(e);
                    case "Bool":
                        return writeExpr(EIdent("false"));
                    case "Int","UInt":
                        return writeExpr(EConst(CInt("0")));
                }
            default:
        }
        // fix of such constructions var tail:Signal = s || p;
        var type:String = tstring(t);
        switch(type) {
            case "Function", "haxe.Constraints.Function":
                var et:String = getExprType(e);
                if (et == "Function" || et == "haxe.Constraints.Function") {
                    write("cast ");
                }
            case "Signal":
                write("cast ");
            case "String":
                if (getExprType(e) != "String") {
                    if (nullable) {
                        e = ECall(EField(EIdent("AS3"), "string"), [e]);
                    } else {
                        e = getToStringExpr(e);
                    }
                }
            case "Bool":
                var re:Expr = rebuildIfExpr(e);
                if (re != null) {
                    e = re;
                }
            case "Int", "UInt":
                if (nullable) {
                        e = ECall(EField(EIdent("AS3"), "int"), [e]);
                } else {
                    var et:String = getExprType(e);
                    if (et != "Int" && et != "UInt") {
                        e = getCastToIntExpr(e);
                    }
                }
            default:
                switch (e) {
                    case EBinop("||", e1, e2, nl):
                        e = ETernary(e1, e1, e2);
                    case EBinop("&&", e1, e2, nl):
                        e = ETernary(EUnop("!", true, e1), e1, e2);
                    case ECall(EVector(t), params):
                        if (type == "Object" || type == "openfl.utils.Object" || (isVectorType(type) && getExprType(e) != type)) {
                            write("cast ");
                        }
                    default:
                        if (isArrayType(type)) {
                            var eType:String = getExprType(e);
                            if (isArrayType(eType) && type != eType) {
                                write("cast ");
                            }
                        }
                }
        }
        return writeExpr(e);
    }

    private function writeDelete(object:Expr, index:Expr):Void {
        var atype = getExprType(object);
        if (atype != null) {
            if (isMapType(atype) || isOpenFlDictionaryType(atype)) {
                writeExpr(object);
                write(".remove(");
                writeExpr(index);
                write(")");
            } else if (atype == "Dynamic" || atype == "Object" || atype == "openfl.utils.Object") {
                switch(index) {
                    case EConst(c):
                        switch(c) {
                            case CInt(v) | CFloat(v): index = EConst(CString(v));
                            default:
                        }
                    case EIdent(_):
                        var type = getExprType(index);
                        if (type == null || type != "String") {
                            index = getToStringExpr(index);
                        }
                    default:
                }
                writeExpr(ECall(EField(EIdent("Reflect"), "deleteField"), [object, index]));
            } else if(atype == "Dictionary") {
                addWarning("EDelete");
                writeNL("This is an intentional compilation error. See the README for handling the delete keyword");
                writeIndent('delete ${getIdentString(object)}[${getIdentString(index)}]');
            } else if (isArrayType(atype)) {
                writeExpr(EBinop("=", EArray(object, index), EIdent("null"), false));
            } else {
                addWarning("EDelete");
                writeNL("This is an intentional compilation error. See the README for handling the delete keyword");
                writeIndent('delete ${getIdentString(object)}[${getIdentString(index)}]');
                writeInComment(atype);
            }
        }
    }

    inline function writeEDelete(e:Expr) {
        switch(e) {
            case EField(e, f):
                writeDelete(e, EConst(CString(f)));
            case EArray(a, i):
                writeDelete(a, i);
            default:
                addWarning("EDelete");
                writeNL("This is an intentional compilation error. See the README for handling the delete keyword");
                writeIndent("delete ");
                writeExpr(e);
        }
    }

    /**
     * Rebuilds any E4X expression to check for instances where the string value
     * is compared to a numerical constant, and change all EIdent instances to
     * the FastXML version.
     * @return expr ready for writing
     */
    function rebuildE4XExpr(e:Expr) : Expr {
        switch(e) {
        case EBinop(op, e2, e3, n):
            if(isNumericConst(e2)) {
                return EBinop(op,ECall(EField(EIdent("Std"),"parseFloat"), [rebuildE4XExpr(e3)]), e2, n);
            }
            if(isNumericConst(e3)) {
                return EBinop(op,ECall(EField(EIdent("Std"),"parseFloat"), [rebuildE4XExpr(e2)]), e3, n);
            }
            var r1 = rebuildE4XExpr(e2);
            var r2 = rebuildE4XExpr(e3);
            return EBinop(op, r1, r2, n);
        case EIdent(id):
            if(id.charAt(0) == "@")
                return EIdent("x.att."+id.substr(1));
            //return EIdent("x.node."+id+".innerData");
            return EIdent("x.node."+id);
        case ECall(e2, params):
            //ECall(EField(EIdent(name),charAt),[EConst(CInt(0))])
            var f = function(e) : String {
                switch(e) {
                    case EConst(c):
                        switch(c) {
                            case CString(s):
                                if(s.charAt(0) == "@")
                                    s = s.substr(1);
                                return s;
                            default:
                        }
                    default:
                }
                return null;
            }
            switch(e2) {
                case EIdent(s):
                    if(params.length == 1) {
                        if(s == "hasOwnProperty") {
                            var i = f(params[0]);
                            if(i != null)
                                return EIdent("x.has." + i);
                        }
                    }
                default:
            }
            return ECall(rebuildE4XExpr(e2), params);
        case EField(e2, f):
            var n = checkE4XDescendants(e);
            if(n != null)
                return n;
            return EField(rebuildE4XExpr(e2),f);
        default:
        }
        return e;
    }

    /**
     * Check for a call to XML.descendants, returning null if the
     * expression is not modified, or a new expr
     */
    function checkE4XDescendants(e:Expr) : Expr {
        switch(e) {
            case EField(e2, f):
            //  e    -e2--------------------------------------  f
            //         -e3----------------------------
            //            -e4-------- -f2--------
            //EField(ECall(EField(EIdent(xml),descendants),[]),user)
            switch(e2) {
                case ECall(e3, p):
                    switch(e3) {
                        case EField(e4,f2):
                            if(getExprType(e4) == "FastXML" && f2 == "descendants")
                                return EE4XDescend(e4,EIdent(f));
                        default:
                    }
                default:
            }
            default:
        }
        return null;
    }

    /**
     * Rebuilds an if condition, checking for tests that should be compared
     * to null or to 0. Errors on the side of caution, which will just leave
     * the original expression to be used, which will cause a haxe compilation
     * error at worst.
     * @return expr ready for writing, or null if the expr could not be handled
     */
    function rebuildIfExpr(e:Expr) : Expr {
        var isNumericType = function(s) {
            return (s == "Float" || isIntType(s) || s == "UInt");
        }
        switch(e) {
            case EArray(_,_): return EBinop("!=", e, EIdent("null"), false);
            case EIdent("null"): return null;
            case EIdent(_), EField(_, _), ECall(_, _):
                var t = getExprType(e);
                if (t == "Bool") return null;
                if (t == null) {
                    return ECall(EField(EIdent("AS3"), "as"), [e, EIdent("Bool")]);
                }
                return switch(t) {
                    case "Int" | "UInt":
                        EBinop("!=", e, EConst(CInt("0")), false);
                    case "Float":
                        var lvalue = EBinop("!=", e, EConst(CInt("0")), false);
                        var rvalue = EUnop("!", true, ECall(EField(EIdent("Math"), "isNaN"), [e]));
                        EParent(EBinop("&&", lvalue, rvalue, false));
                    default: EBinop("!=", e, EIdent("null"), false);
                }
            case EBinop(op, e2, e3, n):
                if(isBitwiseOp(op) || isNumericOp(op)) return EBinop("!=", EParent(e), EConst(CInt("0")), false);
                if(isNumericConst(e2) || isNumericConst(e3)) return null;
                if(op == "==" || op == "!=" || op == "!==" || op == "===") return null;
                if(op == "is" || op == "in" || op == "as") return null;
                if(op == "<" || op == ">" || op == ">=" || op == "<=") return null;
                if(op == "?:") return null;
                var r1 = rebuildIfExpr(e2);
                var r2 = rebuildIfExpr(e3);
                if(r1 == null) r1 = e2;
                if(r2 == null) r2 = e3;
                return EBinop(op, r1, r2, n);
            case EUnop(op, prefix, e2):
                var r2 = rebuildIfExpr(e2);
                if(r2 == null) return null;
                if(op == "!") {
                    if(!prefix) return null;
                    var f:Expr->Expr = null;
                    f = function(r2) return switch(r2) {
                        case EBinop(op2, e3, e4, n):
                            if(op2 == "==") return EBinop("!=", e3, e4, n);
                            if(op2 == "!=") return EBinop("==", e3, e4, n);
                            return null;
                        case EParent(e): f(e);
                        default: null;
                    }
                    var r3 = f(r2);
                    return r3 == null ? EUnop(op, prefix, r2) : r3;
                }
                var t = getExprType(e2);
                if(t == null) return null;
                if(isNumericType(t)) return EBinop("!=", e, EConst(CInt("0")), false);
                return EBinop("!=", e, EIdent("null"), false);
            case EParent(e2):
                var r2 = rebuildIfExpr(e2);
                if(r2 == null) return null;
                return EParent(r2);
            case ENL(e):
                var expr = rebuildIfExpr(e);
                if (expr == null) return null;
                return ENL(expr);
            default:
        }
        return null;
    }

    /**
     * utils returning the ident string of an
     * expr or null if the expr is not an ident
     */
    inline static function getIdentString(e:Expr):String return switch (e) {
        case EIdent(v): v;
        default: null;
    }

    /**
     * Reconstruct a call expression before writing it if necessary. Used
     * for example to replace some ActionScript built-in method be Haxe ones.
     *
     * This is TiVo specific code
     *
     * @return the new expression, or null if no change were needed
     */
    function rebuildCallExpr(fullExpr : Expr, expr : Expr, params : Array<Expr>) : Expr {
        var result = null;
        switch (expr) {
            case EField(e, f):
                if (f == "hasOwnProperty") {
                    var type = getExprType(e);
                    if (isMapType(type) || isOpenFlDictionaryType(type)) {
                        var rebuiltExpr = EField(e, "exists");
                        result = ECall(rebuiltExpr, params);
                    } else if (isDynamicType(type)) {
                        //Reflect.hasField(e, f);
						var e1:Expr = params[0];
						if (getExprType(e1) != "String") {
							e1 = getToStringExpr(e1);
						}
                        result = ECall(EField(EIdent("Reflect"), "hasField"), [e, e1]);
                    } else if (true || isClassType(type)) {
                        result = ECall(EField(EIdent("AS3"), "hasOwnProperty"), [e, params[0]]);
                        //result = EParent(EBinop("!=", ECall(EField(ECall(EField(EIdent("Type"), "getClassFields"), [e]), "indexOf"), params), EConst(CInt("-1")), false));
                    } else {
                        //(Type.getInstanceFields(Type.getClass(e)).indexOf(params[0]) != -1)
                        //result = EParent(EBinop("!=", ECall(EField(ECall(EField(EIdent("Type"), "getInstanceFields"), [ECall(EField(EIdent("Type"), "getClass"), [e])]), "indexOf"), params), EConst(CInt("-1")), false));
                        result = ECall(EField(EIdent("AS3"), "hasOwnProperty"), [e, params[0]]);
                    }
                }
                else if(f == "replace") {
                    var type = getExprType(e);
                    if(type == "String") {
                        var param0 = params[0];
                        var param0Type = getExprType(param0);
                        var isRegexp = switch(param0) {
                            case ERegexp(str, opts): true;
                            default: param0Type == getRegexpType();
                        }
                        if(isRegexp) {
                            params[0] = e;
                            result = ECall(EField(param0, f), params);
                        } else {
                            params.insert(0, e);
                            result = ECall(EField(EIdent("StringTools"), f), params);
                        }
                    }
                }
                else if(f == "fromCharCode" && params.length > 1) {
                    var type = getIdentString(e);
                    if (type == "String") {
                        //replace AS3 slice by Haxe substr
                        var rebuiltExpr = ECall(EField(e, f), [params[0]]);
                        for (i in 1...params.length) {
                            rebuiltExpr = EBinop("+", rebuiltExpr, ECall(EField(e, f), [params[i]]), false);
                        }
                        result = rebuiltExpr;
                    }
                }
                else if(f == "slice") {
                    var type = getExprType(e);
                    if(type != null) {
                        if(type == "String") {
                            //replace AS3 slice by Haxe substr
                            var rebuiltExpr = EField(e, "substring");
                            result = ECall(rebuiltExpr, params);
                        } else if((isArrayType(type) || isVectorExpr(e)) && params.empty()) {
                            var rebuiltExpr = EField(e, "copy");
                            result = ECall(rebuiltExpr, params);
                        }
                    }
                }
                else if (f == "splice") {
                    if(isArrayExpr(e)) {
                        switch(params.length) {
                            case 0 | 2:
                            case 1:
                                params.push(EField(e, "length"));
                                result = ECall(EField(e, f), params);
                            default:
                                if (cfg.useCompat) {
                                    switch (params[1]) {
                                        case EConst(CInt("1")) if (params.length == 3):
                                            result = EBinop("=", EArray(e, params[0]), params[2], false);
                                        case EConst(CInt("0")) if (params.length == 3):
                                            result = ECall(EField(e, "insert"), [params[0], params[2]]);
                                        default:
                                            var p = [e].concat(params.slice(0, 2));
                                            p.push(EArrayDecl(params.slice(2, params.length)));
                                            result = getCompatCallExpr("arraySplice", p);
                                    }
                                }
                        }
                    }
                    if(isVectorExpr(e)) {
                        switch(params.length) {
                            case 0 | 2:
                            case 1:
                                params.push(EField(e, "length"));
                                result = ECall(EField(e, f), params);
                            default:
                                if(cfg.useCompat) {
                                    var p = [e].concat(params.slice(0, 2));
                                    p.push(EArrayDecl(params.slice(2, params.length)));
                                    result = getCompatCallExpr("vectorSplice", p);
                                }
                        }
                    }
                }
                else if(f == "match") {
                    var type = getExprType(e);
                    if(type != null) {
                        if (type == "String") {
                            result = ECall(EField(EIdent("as3hx.Compat"), "match"), [e, params[0]]);
                        }
                    }
                }
                else if(f == "toLocaleLowerCase") {
                    var type = getExprType(e);
                    if(type != null) {
                        if (type == "String") {
                            result = ECall(EField(e, "toLowerCase"), params);
                        }
                    }
                }
                else if(f == "toLocaleUpperCase") {
                    var type = getExprType(e);
                    if(type != null) {
                        if (type == "String") {
                            result = ECall(EField(e, "toUpperCase"), params);
                        }
                    }
                }
                else if(f == "search") {
                    var type = getExprType(e);
                    if(type != null) {
                        if (type == "String") {
                            var param0Type:String = getExprType(params[0]);
                            if (param0Type == "as3hx.Compat.Regex" || param0Type == "EReg") {
                                result = ECall(EField(EIdent("as3hx.Compat"), "search"), [e, params[0]]);
                            } else {
                                result = ECall(EField(e, "indexOf"), [params[0]]);
                            }
                        }
                    }
                }
                else if(f == "indexOf") {
                    //in AS3, indexOf is a method in Array while it is not in Haxe
                    //Replace it by the Labda.indexOf method
                    var type = getExprType(e);
                    if(type != null) {
                        //determine wheter the calling object is an Haxe iterable
                        //if it is, rebuild the expression to use Lamda
                        if(isArrayType(type) || isMapType(type)) {
                            var rebuiltExpr = EField(EIdent("Lambda"), "indexOf");
                            params.unshift(e);
                            result = ECall(rebuiltExpr, params);
                        }
                    }
                }
                else if(f == "insertAt") {
                    if(isArrayExpr(e)) {
                        result = ECall(EField(e, "insert"), params);
                    }
                }
                else if (f == "filter") {
                    if(isArrayExpr(e) || isVectorExpr(e)) {
                        result = ECall(EField(EIdent("as3hx.Compat"), "filter"), [e, params[0]]);
                    }
                }
                else if (f == "sort") {
                    if (isArrayExpr(e)) {
                        switch(params[0]) {
                            case EField(e1, "RETURNINDEXEDARRAY"):
                                switch(e1) {
                                    case EIdent("Array"):
                                        result = getCompatCallExpr("sortIndexedArray", [e]);
                                    default:
                                }
                            default:
                        }
                    }
                }
                else if((f == "min" || f == "max") && params.length > 2) {
                    if(getIdentString(e) == "Math") {
                        result = ECall(EField(e, f), params.slice(0, 2));
                        for(i in 2...params.length) {
                            result = ECall(EField(e, f), [result, params[i]]);
                        }
                    }
                }
                else if (f == "toFixed" || f == "toPrecision") {
                    if(getExprType(e) == "Float") {
                        result = getCompatCallExpr(f, [e].concat(params));
                    }
                }
                else if (f == "toString") {
                    if (params.length == 1) {
                        var type:String = getExprType(e);
                        if (type == "Int" || type == "UInt" || type == "Float") {
                            if (type == "Float") {
                                e = getCastToIntExpr(e);
                            }
                            result = getCompatCallExpr(f, [e].concat(params));
                        } else {
                            //result = getToStringExpr(e); // valid call
                        }
                    } else {
                        result = getToStringExpr(e);
                    }
                }
                else if(f == "concat" && params.empty()) {
                    if(isArrayExpr(e) || isVectorExpr(e)) {
                        var rebuildExpr = EField(e, "copy");
                        result = ECall(rebuildExpr, params);
                    }
                }
                else if(f == "join" && params.empty()) {
                    if(isArrayExpr(e)) {
                        result = ECall(EField(e, f), [EConst(CString(","))]);
                    }
                }
                else if(f == "charAt" || f == "charCodeAt") {
                    var type = getExprType(e);
                    if (type == "String" && params.empty()) {
                        result = ECall(EField(e, f), [EConst(CInt("0"))]);
                    }
                }
                else if (f == "apply") {
                    if(isFunctionExpr(e)) {
                        params = [EIdent("null"), e].concat(params.slice(1));
                        result = ECall(EField(EIdent("Reflect"), "callMethod"), params);
                    }
                }
                else if(f == "call") {
                    if(isFunctionExpr(e)) {
                        params = [EIdent("null"), e].concat([EArrayDecl(params.slice(1))]);
                        result = ECall(EField(EIdent("Reflect"), "callMethod"), params);
                    }
                }
                else if(f == "removeAt") {
                    if(isArrayExpr(e)) {
                        params = params.concat([EConst(CInt("1"))]);
                        result = EArray(ECall(EField(e, "splice"), params), EConst(CInt("0")));
                    }
                }
                else if(f == "trim") {
                    if(getIdentString(e) == "StringUtil") {
                        result = ECall(EField(EIdent("StringTools"), f), params);
                    }
                }
                else if (f == "resolveClass") {
                    if (getIdentString(e) == "Type") {
                        if (params.length == 1) {
                            switch(params[0]) {
                                case ECall(EIdent("getQualifiedSuperClassName"), params2):
                                    result = ECall(EField(EIdent("Type"), "getSuperClass"), [ECall(EField(EIdent("Type"), "getClass"), params2)]);

                                case ECall(EIdent("getQualifiedClassName"), params2):
                                    result = ECall(EField(EIdent("Type"), "getClass"), params2);
                                default:
                            }
                        }
                    }
                }
                else if(f == "isWhitespace") {
                    if(getIdentString(e) == "StringUtil") {
                        params.push(EConst(CInt("0")));
                        result = ECall(EField(EIdent("StringTools"), "isSpace"), params);
                    }
                }
                else if(getIdentString(e) == "JSON") {
                    result = ECall(EField(EIdent("haxe.Json"), f), params);
                }
            case EParent(e):
                result = switch(fullExpr) {
                    case ECall(e, params):
                        var f:Expr->Expr = null;
                        f = function(e) return switch(e) {
                            case EParent(e): f(e);
                            default: e;
                        }
                        e = f(e);
                        ECall(e, params);
                    default: null;
                }
            default:
                var ident = getIdentString(expr);
                if (ident != null) {
                    //utils returning a string representation
                    //of the provided param
                    var getCommentedParam = function(param) {
                        return switch(param) {
                            case EConst(CString(s)): s;
                            case EIdent(id): id;
                            default: null;
                        }
                    }

                    //helper to convert an AS3 test case to an Haxe one
                    var getUnitTestExpr = function(rebuiltExpr, params, commentFirstParam) {
                        var result = ECall(rebuiltExpr, params);

                        //in some cases, the first param is a description of the test,
                        //which should be converted to a comment
                        if (commentFirstParam) {
                            var comment = getCommentedParam(params.shift());
                            result = ECommented(comment, false, true, result);
                        }
                        return result;
                    }

                    switch (ident) {
                        //replace "hasAnyProperty(myVar)" by "myVar.keys().hasNext()"
                        // "myVar" is assumed to be an iterable
                        case "hasAnyProperties":
                            if (params.length == 1) {
                                //there should be one and only one identifier param
                                var paramIdent = getIdentString(params[0]);
                                if (paramIdent != null ) {
                                    var keysExpr =  ECall(EField(EIdent(paramIdent), "keys"), []);
                                    var rebuiltExpr = EField(keysExpr, "hasNext");
                                    result = ECall(rebuiltExpr, []);
                                }
                            }

                        //convert AS3 unit tests to Haxe tests
                        case "assertTrue":
                            var rebuiltExpr = EField(EIdent("Assert"), "isTrue");
                            result = getUnitTestExpr(rebuiltExpr, params, params.length == 2);

                        case "assertFalse":
                            var rebuiltExpr = EField(EIdent("Assert"), "isFalse");
                            result = getUnitTestExpr(rebuiltExpr, params, params.length == 2);

                         case "assertEquals":
                            var rebuiltExpr = EField(EIdent("Assert"), "areEqual");
                            result = getUnitTestExpr(rebuiltExpr, params, params.length == 3);

                        case "assertNull":
                            var rebuiltExpr = EField(EIdent("Assert"), "isNull");
                            result = getUnitTestExpr(rebuiltExpr, params, params.length == 2);

                        case "assertNotNull":
                            var rebuiltExpr = EField(EIdent("Assert"), "isNotNull");
                            result = getUnitTestExpr(rebuiltExpr, params, params.length == 2);

                        case "assertThat":
                            result = getUnitTestExpr(EIdent(ident), params, params.length == 3);

                        case "fail":
                            var rebuiltExpr = EField(EIdent("Assert"), "fail");
                            result = getUnitTestExpr(rebuiltExpr, params, false);
                    }
                }
        }
        return result;
    }

    function rebuildBinopExpr(op:String, lvalue:Expr, rvalue:Expr):Null<Expr> {
        function getResultForNumerics(op:String, lvalue:Expr, rvalue:Expr):Null<Expr> {
            var changed = false;
            if(needCastToInt(lvalue)) {
                lvalue = getCastToIntExpr(lvalue);
                changed = true;
            }
            if(needCastToInt(rvalue)) {
                rvalue = getCastToIntExpr(rvalue);
                changed = true;
            }
            return changed ? EBinop(op, lvalue, rvalue, false) : null;
        }
        if(isBitwiseAndAssignmetnOp(op)) return EBinop("=", lvalue, EBinop(op.charAt(0), lvalue, rvalue, false), false);
        switch(op) {
            case "||=":
                var type = getExprType(lvalue);
                if(type != null) {
                    var cond = switch(type) {
                        case "Bool": lvalue;
                        case "Int" | "UInt" | "Float" | _: rebuildIfExpr(lvalue);
                    }
                    if (cond == null) cond = lvalue;
                    if(isDynamicType(type)) {
                        cond = switch(cond) {
                            case EBinop(op, e1, e2, false) if(op == "!="): EBinop("==", e1, e2, false);
                            default: cond;
                        }
                        return EIf(cond, EBinop("=", lvalue, rvalue, false));
                    }
                    return EBinop("=", lvalue, ETernary(cond, lvalue, rvalue), false);
                }
            case "&&=":
                var type = getExprType(lvalue);
                if(type == "Bool") {
                    return EBinop("=", lvalue, EBinop("&&", lvalue, rvalue, false), false);
                }
            case "==" if (isFunctionExpr(lvalue) || isFunctionExpr(rvalue)):
                return ECall(EField(EIdent("Reflect"), "compareMethods"), [lvalue, rvalue]);
            case "=" | "+=" | "-=" | "*=" | "/=":
                if(cfg.useCompat) {
                    switch(lvalue) {
                        case EField(e, f):
                            if(f == "length" && isArrayExpr(e)) {
                                return getCompatCallExpr("setArrayLength", [e, rvalue]);
                            }
                        default:
                    }
                }
                if (isIntExpr(lvalue)) {
                    if (op == "/=") {
                        return EBinop("=", lvalue, EBinop("/", lvalue, rvalue, false), false);
                    } else if(needCastToInt(rvalue)) {
                        switch(rvalue) {
                            case EBinop(op, e1, e2, newLineAfterOp) if(isBitwiseOp(op)):  rvalue = getResultForNumerics(op, e1, e2);
                            case EUnop(op, prefix, e) if(op == "~"):
                                if(needCastToInt(e)) e = getCastToIntExpr(e);
                                rvalue = EUnop(op, prefix, e);
                            default: rvalue = getCastToIntExpr(rvalue);
                        }
                        return rvalue != null ? EBinop(op, lvalue, rvalue, false) : null;
                    } else switch(rvalue) {
                        case EBinop(rop, _, _, nl) if(isBooleanOp(rop)): return EBinop(op, lvalue, ETernary(rvalue, EConst(CInt("1")), EConst(CInt("0"))), nl);
                        case _:
                    }
                }
                switch(rvalue) {
                    case EBinop(op,e1,e2,_) if(op == "||="):
                        writeExpr(rebuildBinopExpr(op, e1, e2));
                        writeNL();
                        writeIndent();
                        return EBinop("=", lvalue, e1, false);
                    default:
                }
            case "&": return getResultForNumerics(op, lvalue, rvalue);
        }
        return null;
    }

    /**
     * For an if statement, return the
     * the appropriate block end, based on the
     * type of the first child expression
     */
    function getEIfBlockEnd(e:Expr) : BlockEnd {
        return switch(e) {
            case EObject(_): Ret;
            case EBlock(_): None;
            case EIf(_,_,_): Semi;
            case EReturn(_): Semi;

            //comments expression are ignored for this purpose,
            //and instead the first expression
            //following the comment is used
            case ECommented(s,b,t,e): getEIfBlockEnd(e);
            //like comment, wrapped expression used instead
            case ENL(e): getEIfBlockEnd(e);
            default: Semi;
        }
    }

    /**
     * Return wether the expression contained in an
     * "if" statement is a one liner with no block bracket
     */
    function isOneLiner(e : Expr, threatOneLineBlockAsOneLiner:Bool = false) : Bool {
        return switch (e) {
            case ENL(e): //ignore newline
                return isOneLiner(e, threatOneLineBlockAsOneLiner);

            case ECommented(s, b, t, e): //ignore comment
                if (isHaxeCodeComment(s)) return false;
                return isOneLiner(e, threatOneLineBlockAsOneLiner);

            case EBlock(e): //it is a regular block
                if (threatOneLineBlockAsOneLiner && e.length == 1) {
                    switch(e[0]) {
                        case ENL(ex)://skip
                        default: return true;
                    }
                }
                return false;

            default: //if it begins with anything but a block, one liner
                return true;
        }
    }

    /**
     * Return wether the content of the switch
     * case needs to be indented
     */
    function shouldIndentCase(expressions:Array<Expr>) : Bool {
        //copy as might need to change
        var expressions = expressions.copy();
        //search for the first significant expression
        //to determine indenting
        for (expr in expressions) {
            switch (expr) {
                case EBlock(_): return false;  //block will add its own indenting
                case ECommented(_):  //comments are skipped for this purpose
                case ENL(e): expressions.push(e); //newline are ignored but its content matters
                default: return true;
            }
        }
        //empty switch case
        return false;
    }

    function prepareObjectFieldName(name:String):String {
        if (validVariableNameEReg.match(name)) {
            return name;
        } else {
            return '"' + name + '"';
        }
    }

    /**
     * Checks if 'e' represents a numerical constant value
     * @return true if so
     */
    static inline function isNumericConst(e:Expr):Bool return switch(e) {
        case EConst(c): c.match(CInt(_)) || c.match(CFloat(_));
        default: false;
    }

    inline function isArrayExpr(e:Expr):Bool {
        var type = getExprType(e);
        return isArrayType(type);
    }

    inline function isVectorExpr(e:Expr):Bool {
        var type = getExprType(e);
        return isVectorType(type);
    }

    static inline function isArrayType(s:String):Bool {
        return s != null && ((s.indexOf("Array<") == 0) || s == "Array");
    }

    inline function isVectorType(s:String):Bool {
        return s != null && (s.indexOf("Vector<") == 0 || s.indexOf("openfl.Vector<") == 0 || s.indexOf(cfg.arrayTypePath + "<") == 0);
    }

    static inline function isDynamicType(s:String):Bool return s == "Dynamic" || s == "Object" || s == "openfl.utils.Object";

    inline function isMapType(s:String):Bool {
        return s != null && (s.indexOf("Map") == 0 || s.indexOf("haxe.ds.ObjectMap") == 0);
    }

    inline function isByteArrayType(s:String):Bool {
        return s == "ByteArray";
    }

    inline function isOpenFlDictionaryType(s:String):Bool {
        return s != null && (s.indexOf("Dictionary") == 0 || s.indexOf("openfl.utils.Dictionary") == 0) && cfg.useOpenFlTypes;
    }

    inline function isFunctionExpr(e:Expr):Bool {
        var type:String = getExprType(e);
        return type == "Function" || type == "haxe.Constraints.Function" || (type != null && type.indexOf("->") != -1);
    }

    inline function isIntExpr(e:Expr):Bool {
        var type = getExprType(e);
        return isIntType(type);
    }

    inline function isIntType(s:String):Bool return s == "Int";

    inline function isBoolType(s:String):Bool return s == "Bool";

    inline function isClassType(s:String):Bool return s == "Class" || s == "Class<Dynamic>";

    inline function isNumericOp(s:String):Bool return switch(s) {
        case "/" | "-" | "+" | "*" | "%" | "--" | "++": true;
        default: false;
    }

    inline function isBitwiseOp(s:String):Bool return switch(s) {
        case "<<" | ">>" | ">>>" | "^" | "|" | "&" | "~": true;
        default: false;
    }

    inline function isBooleanOp(s:String):Bool return switch(s) {
        case "||" | "&&" | "!=" | "!==" | "==" | "===": true;
        case _: false;
    }

    inline function isBitwiseAndAssignmetnOp(s:String):Bool return switch(s) {
        case "&=" | "|=" | "^=": true;
        default: false;
    }

    function addWarning(type:String, isError = false) {
        warnings.set(type, isError);
    }

    static function quote(s : String) : String
    {
        return '"' + StringTools.replace(s, '"', '\\"') + '"';
    }

    static function eregQuote(s : String) : String
    {
        return '"' + StringTools.replace(StringTools.replace(s, '\\', '\\\\'), '"', '\\"') + '"';
    }

    function isOverride(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "override");
    }

    function isStatic(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "static");
    }

    function isPublic(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "public");
    }

    function isPrivate(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "private");
    }

    function isInternal(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "internal");
    }

    function isFinal(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "final");
    }

    function isProtected(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "protected");
    }

    function isGetter(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "get");
    }

    function isSetter(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "set");
    }

    function isConst(kwds : Array<String>) : Bool
    {
        return Lambda.has(kwds, "const");
    }

    function istring(t : T, fixCase:Bool = true) : String {
        if(t == null) return null;
        return switch(t) {
            case TPath(p):
                if (p.length > 1) return null;
                var c = p[0];
                return switch(c) {
                    case "int" | "uint" | "void": return null;
                    default: return fixCase ? properCase(c, true) : c;
                }
            case TVector(t) if (cfg.useOpenFlTypes): return "Vector";
            default: null;
        }
    }

    function tstring(t : T, isNativeGetSet:Bool = false, fixCase:Bool = true) : String {
        return switch(t) {
            case null: null;
            case TComplex(e): buffer(function() { writeExpr(e); });
            default: typer.tstring(t, isNativeGetSet, fixCase);
        }
    }

    /**
     * Write an As3 package level function. As Haxe
     * does not have this, wrap it in a class definition
     */
    function writeFunctionDef(fDef : FunctionDef)
    {
        writeClassDef(wrapFuncDefInClassDef(fDef));
    }

    /**
     * Wrap a function definition inside a class definition,
     * using the function name as a basis for the class name
     */
    function wrapFuncDefInClassDef(fDef : FunctionDef) : ClassDef
    {
        //first func need to be converted to the field
        //type for classes
        var kwds:Array<String> = fDef.kwds.copy();
        kwds.push("static");
        var funcAsClassField : ClassField = {
            name : fDef.name,
            meta : [ENL(null)],
            condVars : [],
            kwds : kwds,
            kind : FFun(fDef.f)
        };

        //uppercase func name first letter
        var name = fDef.name.charAt(0).toUpperCase() + fDef.name.substr(1);

        //generate class doc
        var meta = fDef.meta.copy();
        meta.push(ENL(null));
        meta.push(ECommented("/**\n * Class for " + fDef.name + "\n */",false,false,null));
        meta.push(ENL(null));


        var result:ClassDef = new ClassDef();
        result.meta = meta;
        result.kwds = ["final"];
        result.imports = [];
        result.isInterface = false;
        result.name = name;
        result.typeParams = null;
        result.fields = [funcAsClassField];
        result.implement = [];
        result.extend = null;
        result.inits = [];
        return result;
    }

    function writeNamespaceDef(n : NamespaceDef)
    {

    }

    function loopCases(cases : Array<SwitchCase>, def: Null<Array<Expr>>, testVar:Expr, out:Array<CaseDef>):Array<CaseDef> {
        var c : { val : Expr, el : Array<Expr>, meta : Array<Expr> } = cases.pop();
        if(c == null)
            return out;

        var outCase = {
            vals: new Array(),
            el : new Array(),
            meta : new Array()
        };

        var falls = false;
        if(c.el == null || c.el.length == 0) {
            falls = true;
        } else {
            var f:Expr->Array<Expr>->Void = null;
            f = function(e, els) {
                switch(e) {
                    case EBreak(lbl):
                        if(lbl == null)
                            els.pop(); // remove break
                        falls = false;
                    case EReturn(ex):
                        falls = false;
                    case ENL(e): //newline might wrap a break or return
                        f(e, els);
                    case EBlock(exprs): //block might wrap a break or return, check last expr of block
                        f(exprs[exprs.length - 1], exprs);
                        falls = false;
                    default:
                        falls = true;
                }
            }
            f(c.el[c.el.length-1], c.el);
        }

        // if it's a fallthough, we have to add the cases val to the
        // next out case, and wrap the Expr list in another ESwitch
        if(falls && out.length > 0) {
            var nextCase = out[0];
            nextCase.vals.unshift(c.val);
            var el = c.el.slice(0);
            if(el.length > 0) {
                el.push(EBreak(null));
                nextCase.el.unshift(ESwitch(EParent(testVar), [{val:c.val, el: el, meta:[]}], null));
            }
        } else {
            outCase.vals.push(c .val);
            for(e in c.el)
                outCase.el.push(e);
            for(m in c.meta)
                outCase.meta.push(m);
            if(falls) {
                // last case before default, add default code since this case has no break
                if(def != null)
                    for(e in def)
                        outCase.el.push(e);
            }
            out.unshift(outCase);
        }
        out = loopCases(cases, null, testVar, out);
        return out;
    }

    function openb() : String
    {
        if (cfg.bracesOnNewline) {
            var s:String = cfg.newlineChars + indent() + "{";
            if (pendingTailComment != null) {
                s = pendingTailComment + s;
                pendingTailComment = null;
            }
            return s;
        } else {
            return " {";
        }
    }

    function closeb() : String {
        var s:String = cfg.newlineChars + indent() + "}";
        if (pendingTailComment != null) {
            s = pendingTailComment + s;
            pendingTailComment = null;
        }
        return s;
    }

    function write(s : String)
    {
        //set line as dirty if string contains something other
        //than whitespace/indent
        if (!containsOnlyWhiteSpace(s) && s != cfg.indentChars) {
            lineIsDirty = true;
        }

        o.writeString(s);
    }

    /** write Haxe "allow" metadata using current package */
    function writeAllow() {
        write("@:allow("+properCaseA(this.pack,false).join(".")+")");
        writeNL();
        writeIndent();
    }

    private inline function isHaxeCodeComment(s:String):Bool {
        return s.indexOf("haxe:") == 2;
    }

    /**
     * Writing for block and line comment. If
     * comment written on dirty line (not first text on line),
     * add extra whitespace before and after comment
     */
    function writeComment(s : String, blockComment : Bool)
    {
        if (blockComment) {
            if (isHaxeCodeComment(s)) {
                write(s.substring(7, s.length - 2));
            } else if (lineIsDirty) {
                write(" " + s + " ");
            } else {
                write(s);
            }
        } else {
            if (pendingTailComment == null) {
                pendingTailComment = s;
            } else {
                pendingTailComment += " " + s;
            }
        }
    }

    function writeIndent(s = "")
    {
        write(indent() + s);
    }

    function writeLine(s = "")
    {
        lineIsDirty = false;

        if (pendingTailComment != null) {
            write(indent() + s + pendingTailComment + cfg.newlineChars);
            pendingTailComment = null;
        } else {
            write(indent() + s + cfg.newlineChars);
        }
    }

    function writeNL(s = "")
    {
        write(s);
        if (pendingTailComment != null) {
            write(pendingTailComment);
            pendingTailComment = null;
        }
        write(cfg.newlineChars);
        lineIsDirty = false;
    }

    inline function writeStartStatement() {
        if(cfg.bracesOnNewline) {
            writeNL();
            writeIndent();
        } else {
            write(" ");
        }
    }

    inline function writeCloseStatement() {
        if(cfg.bracesOnNewline) {
            write(")");
            writeNL();
            writeIndent();
        } else {
            write(") ");
        }
    }

    function writeFinish(cond:BlockEnd) {
        switch(cond) {
            case None:
            case Semi: write(";");
            case Ret:
        }
    }

    /**
     * Write typedef that were generated during parsing
     */
    function writeGeneratedTypes(genTypes : Array<GenType>) : Void
    {
        for (genType in genTypes) {
            writeNL();
            write("typedef " + genType.name + " = {");
            for(field in genType.fields) {
                writeNL();
                writeIndent(cfg.indentChars);
                write("var "+field.name + " : " + field.t + ";");
            }
            writeNL();
            write("}");
            writeNL();
        }
    }

    function containsOnlyWhiteSpace(s : String) : Bool
    {
        return StringTools.trim(s) == "";
    }

    function extractComments(expr:Expr) : Expr {
        return switch(expr) {
            case ENL(e2):
                var re:Expr = extractComments(e2);
                if (re != null) {
                    return ENL(re);
                }
                return null;
            case ECommented(s,b,t,e2):
                var re:Expr = extractComments(e2);
                if (re != null) return ENL(re);
                return ECommented(s,b,t,null);
            default: null;
        }
    }

    /**
     * Switches output to a string accumulator
     * @return contents of buffer after calling f()
     */
    function buffer(f:Void->Void) : String {
        var old = o;
        o = new haxe.io.BytesOutput();
        f();
        var rv = untyped o.getBytes().toString();
        o = old;
        return rv;
    }

    function indent() : String
    {
        var b = [];
        for (i in 0...lvl)
            b.push(cfg.indentChars);
        return b.join("");
    }

    public function process(program : Program, output : Output):Map<String, Bool> {
        warnings = new Map();

        var commons:Map<String,String> = CommonImports.getImports(cfg);
        typeImportMap = new Map<String,String>();
        for (key in commons.keys()) {
            typeImportMap.set(key, commons.get(key));
        }

        //list of imported types must be reseted for each file,
        //as only one instance of Writer write all the files
        imported = [];

        var defined:Array<String> = [];

        pack = program.pack;
        var packWithDot:String = properCaseA(pack, false).join(".") + (program.pack.length > 0 ? "." : "");

        for (type in program.typesDefd) {
            defined.push(type.name);
            imported.push(packWithDot + type.name);
        }

        switch(program.defs[0]) {
            case CDef(c):
                for (meta in c.meta) {
                    switch (meta) {
                        case EImport(v):
                            if (cfg.importExclude != null && cfg.importExclude.indexOf(v.join(".")) != -1) {
                                continue;
                            }
                            defined.push(v[v.length - 1]);
                        default:
                    }
                }
            default:
        }

        for (def in program.defs) {
            switch(def) {
                case CDef(c):
                    defined.push(c.name);
                    imported.push(packWithDot + c.name);
                default:
            }
        }

        o = output;
        genTypes = program.genTypes;
        writeComments(program.header);
        writePackage(program.pack);
        writeImports(program.imports);
        writeAdditionalImports(program.pack, program.typesSeen, defined);
        generatedTypesWritten = false;
        writeDefinitions(program.defs);
        writeComments(program.footer);
        return warnings;
    }

    /**
     * This method outputs each warning and the associated affected files.
     * By doing it this way, it becomes easy to see all the places a specific
     * warning is affecting, so that the porter can more easily determine
     * the fix.
     */
    public static function showWarnings(allWarnings : Map<String,Map<String,Bool>>) {
        var wke : Map<String,Array<String>> = new Map(); // warning->files
        for(filename in allWarnings.keys()) {
            for(errname in allWarnings.get(filename).keys()) {
                var a = wke.get(errname);
                if(a == null) a = [];
                a.push(filename);
                wke.set(errname,a);
            }
        }
        var println =
            #if neko
                neko.Lib.println;
            #elseif cpp
                cpp.Lib.println;
            #end
        for(warn in wke.keys()) {
            var a = wke.get(warn);
            if(a.length > 0) {
                switch(warn) {
                case "EE4X": println("ERROR: The following files have xml notation that will need porting. See http://haxe.org/doc/advanced/xml_fast");
                case "EXML": println("WARNING: There is XML that may not have translated correctly in these files:");
                case "Vector.<T>": println("FATAL: These files have a Vector.<T> call, which was not handled. Check versus source file!");
                case "ETypeof": println("WARNING: These files use flash 'typeof'. as3hx.Compat is required, or recode http://haxe.org/doc/cross/reflect");
                case "as Class": println("WARNING: These files casted using 'obj as Class', which may produce incorrect code");
                case "as number", "as int": println("WARNING: "+warn+" casts in these files");
                case "as array": println("ERROR: type must be determined for 'as array' cast for:");
                case "as Function": println("WARNING: These files had a cast to Function which was ommited due to haxe type system");
                case "EDelete": println("FATAL: Files will not compile due to 'delete' keyword. See README");
                default: println("WARNING: " + warn);
                }
                for(f in a)
                    println("\t"+f);
            }
        }
    }

    public static function properCase(pkg:String, hasClassName:Bool):String {
        return properCaseA(pkg.split("."), hasClassName).join(".");
    }

    public static function properCaseA(path:Array<String>, hasClassName:Bool):Array<String> {
        var result = [];
        if (path.length == 3 && path[0] == "haxe" && path[1] == "Constraints" && path[2] == "Function") {
            return path;
        }
        for(i in 0...path.length) {
            if(hasClassName && i == path.length - 1)
                //result[i] = removeUnderscores(path[i]); removed by no reason
                result[i] = path[i];
            else {
                var p = path[i];
                result[i] = p.charAt(0).toLowerCase() + p.substr(1);
            }
        }
        if(hasClassName) {
            var f = result[result.length - 1];
            var o = "";
            for(i in 0...f.length) {
                var c = f.charCodeAt(i);
                if(i == 0)
                    o += String.fromCharCode(c).toUpperCase();
                else
                    o += String.fromCharCode(c);
            }
            result[result.length - 1] = o;
        }
        return result;
    }

    public static function removeUnderscores(id : String):String {
        return id.split("_").map(
            function (v:String) return v.length > 0 ? v.charAt(0).toUpperCase() + v.substr(1) : ""
        ).array().join("");
    }
}