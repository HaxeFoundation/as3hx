package as3hx;

using Lambda;

import as3hx.As3;
import haxe.io.Output;

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
 * ...
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
    var context : Map<String,String>;
    var contextStack : Array<Map<String,String>>;
    var inArrayAccess : Bool;
    var inE4XFilter : Bool;
    var inLvalAssign : Bool; // current expr is lvalue in assignment (expr = valOfSomeSort)
    var rvalue : Expr;
    var typeImportMap : Map<String,String>;
    var lineIsDirty : Bool; // current line contains some non-whitespace/indent characters
    var genTypes : Array<GenType>; //typedef generated while parsing
    var imported : Array<String>; // store written imports to prevent duplicated
    var pack : Array<String>; // stores the haxe file package
    
    public function new(config:Config)
    {
        this.lvl = 0;
        this.cfg = config;
        this.varCount = 0;
        this.context = new Map();
        this.contextStack = new Array();
        this.inArrayAccess = false;
        this.inE4XFilter = false;
        this.inLvalAssign = false;
        this.lineIsDirty = false;

        this.typeImportMap = new Map<String,String>();
        this.genTypes = [];
        this.imported = [];

        var doNotImportClasses = [
            "Array", "Bool", "Boolean", "Class", "Date",
            "Dynamic", "EReg", "Enum", "EnumValue",
            "Float", "Map", "Int", "IntIter",
            "Lambda", "List", "Math", "Number", "Reflect",
            "RegExp", "Std", "String", "StringBuf",
            "StringTools", "Sys", "Type", "Void",
            "Function", "Object", "XML", "XMLList"
            ];
        for (c in doNotImportClasses) {
            this.typeImportMap.set(c, null);
        }

        var topLevelErrorClasses = [
            "ArgumentError", "DefinitionError", "Error",
            "EvalError", "RangeError", "ReferenceError",
            "SecurityError", "SyntaxError", "TypeError",
            "URIError", "VerifyError"
            ];
        for (c in topLevelErrorClasses) {
            this.typeImportMap.set(c, "flash.errors." + c);
        }

        for (c in cfg.importTypes.keys()) {
            this.typeImportMap.set(c, cfg.importTypes.get(c));
        }
    }

    /**
     * Opens a new context for variable typing
     **/
    function openContext() {
        var c = new Map();
        for(k in context.keys())
            c.set(k, context.get(k));
        contextStack.push(context);
        context = c;
    }

    /**
     * Closes the current variable typing copntext
     **/
    function closeContext() {
        context = contextStack.pop();
    }

    function formatComment(s:String, isBlock:Bool):String {
        if(!isBlock) {
            return s;
        }
        var r = new EReg("^(" + cfg.indentChars + ")+", "mg");
        return StringTools.ltrim(r.replace(s,indent()));
    }

    function writeComments(comments : Array<Expr>) {
        for(c in comments) {
            switch(c) {
            case ECommented(s,b,t,e):
                writeComment(indent() + formatComment(s,b));
                if (e != null) {
                    switch (e) {
                        case ECommented(_):
                            writeComments([e]);
                        default:
                            throw "Unexpected " + e + " in comments";
                    }
                }
            case EImport(i):
                writeImport(i);
            case ENL(e):
                writeNL();  
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
            var imported = []; //holds already written types to prevent duplicates
            for(i in imports) {
                writeImport(i);
                writeNL(); 
            }
            writeNL(); 
        }
    }

    function writeImport(i : Array<String>)
    {
        var type = properCaseA(i,true).join(".");
        if (!Lambda.has(this.imported, type)) { //prevent duplicate import
            write("import " + type + ";");
            imported.push(type);
            // do not add an implicit import for
            // this type since it has an explicit one.
            typeImportMap.set(i[i.length-1], null);
        }
    }
        
    function writeAdditionalImports(defPackage : Array<String>, allTypes : Array<Dynamic>,
                    definedTypes : Array<String>)
    {
        // We don't want to import any type that is defined within
        // this file, so add each of those to the type import map
        // first.
        for(d in definedTypes) {
        typeImportMap.set(d, null);
        }

        // Now convert each seen type enum into the corresponding
        // type import string.
        var uniqueTypes : Map<String,Bool> = new Map<String,Bool>();
        for(t in allTypes) {
        var importType : String = istring(t);
        if (importType != null) uniqueTypes.set(importType, true);
        }

        // Now look up each type import string in the type import
        // map.
        var addnImports : Array<String> = new Array<String>();
        for(u in uniqueTypes.keys()) {
        var importType : String;
        if (typeImportMap.exists(u)) {
            u = typeImportMap.get(u);
        } else {
            u = properCaseA(defPackage,false).concat([u]).join(".");
        }
        if (u != null)
            addnImports.push(u);
        }

        // Finally, if any additional implicit imports were found
        // to be needed, output them.
        if (addnImports.length > 0) {
        addnImports.sort(
            function(a : String, b : String) : Int {
            if (a<b) return -1;
            if (b<a) return 1;
            return 0;
            } );
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
            case CDef( c ):
                writeClassDef(c);
            case FDef( f ):
                writeFunctionDef(f);
            case NDef( n ):
                writeNamespaceDef(n);
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
            case ECommented(s,b,t,e):
                writeExpr(d);
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

        var buf = new StringBuf();
        this.isInterface = c.isInterface;
        
        if (!c.isInterface && isFinal(c.kwds)) {
            buf.add("@:final ");
        }

        buf.add(c.isInterface ? "interface " : "class ");

        buf.add(properCase(c.name,true));
        
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
        var getOrCreateProperty = function(name, t, stat)
        {
            var property = h.get(name);
            if (null == property)
            {
                property = {
                    name : name,
                    get : "never",
                    set : "never",
                    ret : t,
                    sta : stat,
                    pub : false,
                    getMeta : null,
                    setMeta : null
                };
                p.push(property);
                h.set(name, property);
                context.set(name, tstring(t, true));
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

                        var property = getOrCreateProperty(field.name, f.ret.t, isStatic(field.kwds));
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

                        var property = getOrCreateProperty(field.name, f.args[0].t, isStatic(field.kwds));
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

                context.set(property.name, tstring(property.ret, false));
            }
        }
        if (c.isInterface) {
            writeNL();
        }
        
    }
    
    function writeFields(c : ClassDef)
    {
        for (field in c.fields)
            writeField(field, c);
        if(c.isInterface)
            return;
            
        if(!Lambda.exists(c.fields,
            function(field:ClassField) {
                switch(field.kind) {
                    case FFun( f ):
                        if (field.name == c.name)
                            return true;
                    default:
                }
                return false;
            }
        ))
        {
            addWarning("Required constructor was added for member var initialization");
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
            writeConstructor({
                args : [],
                varArgs : null,
                ret : null,
                expr : EBlock(((null != c.extend) ? [ENL(ECall(EIdent("super"),[]))] : []))
            }, c.extend != null);
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

        writeMetaData(field.meta);
        
        var start = function(name:String, isFlashNative:Bool=false, isConstructor=false) {
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
            if (isFinal(field.kwds))
                write("@:final ");  
            if (isOverride(field.kwds))
                write((isFlashNative && (isGet || isSet)) ? "" : "override ");
            
            //coner-case, constructor of internal AS3 class is set to private in 
            //Haxe with a meta allowing access from same package
            if (isConstructor && isInternal(c.kwds)) {
                writeAllow();
                write("private ");
            }
            else if (isPublic(field.kwds)) {
                if (!(isGet && cfg.forcePrivateGetter) //check if forced private getter
                    && !(isSet && cfg.forcePrivateSetter)) //check if forced private setter
                    write("public ");
                else {
                    if (! isInterface) {
                        write("private ");
                    }
                }    
            }
            else if(!isInterface) {
                //if func uses AS3 'internal', convert to Haxe
                //equivalent, which is to allow access to the current
                //package
                if (isInternal(field.kwds)) {
                    writeAllow();
                }
                write("private ");
            }
            if (isStatic(field.kwds))
                write("static ");
            
                
            //check wheter the field is an AS3 constants, which can be inlined in Haxe
            //the field must be either a static constant or a private constant. 
            //If it is a non-static public constant it can't be inlined as Haxe can only inline
            //static field. Converting non-static public field to static will likely cause compilation
            //errors, whereas it won't for private field as they will be accessed in the same way
            if (isConst(field.kwds) && (isStatic(field.kwds) || isPrivate(field.kwds))) {
                switch(field.kind) {
                    case FVar(t, val):
                        //only constants (bool, string, int/float) field can
                        //be safely inlined for Haxe as we don't havve full typing
                        //available. For instance trying to inline a field referencing another
                        //static non-inlined field would prevent Haxe compilation

                        if (val != null) {
                            switch (val) {

                                case EConst(c):
                                    write("inline ");

                                default:
                            }
                        }

                    default:
                }
            }
               
        }
        switch(field.kind)
        {
            case FVar( t, val ):
                start(field.name, false);
                write("var " + getModifiedIdent(field.name));

                var type = tstring(t, false); //check wether a specific type was defined for this array
                if (type != null && type.indexOf("Array") != -1) {
                    for (genType in this.genTypes) {
                        if (field.name == genType.fieldName) {
                            t = TVector(TPath([genType.name]));
                        }
                    }
                }
                writeVarType(t);
                context.set(field.name, tstring(t, false));

                //initialise class property
                if(val != null) {
                    write(" = ");
                    lvl++; //extra indenting if init is on multiple lines
                    writeExpr(val);
                    lvl--;
                }

                write(";");
            case FFun( f ):
                if (field.name == c.name)
                {
                    start("new", false, true);
                    writeConstructor(f, c.extend != null);
                } else {
                    var ret = f.ret;
                    var name = if (isGetter(field.kwds)) {
                        cfg.makeGetterName(field.name); //"get" + ucfirst(field.name);
                    } else if (isSetter(field.kwds)) {
                        ret.t = f.args[0].t;
                        cfg.makeSetterName(field.name); //"set" + ucfirst(field.name);
                    } else {
                        getModifiedIdent(field.name);
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
                        writeFunction(f, isGetter(field.kwds), isSetter(field.kwds), false, name, ret);
                    }
                }

            case FComment:
                //writeComments(field.meta);
                null;
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
            else if (field == f){
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

    /***
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
            if (i == 0) {
                writeNL();
                writeIndent("#end // ");
            } else {
                write(" && ");
            }
            write(condComps[i]);
        }
    }
    
    function writeArgs(args : Array<{ name : String, t : Null<T>, val : Null<Expr>, exprs : Array<Expr> }>)
    {
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

            for (expr in arg.exprs) //for each expression within that argument
            {
                switch (expr) {
                    case EIdent(s):

                        if (s == arg.name) { //this is the start of a new argument

                            var isFirst = null == fst;
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
                       
                    case ETypedExpr(e, t):
                        writeVarType(t);
                        context.set(arg.name, tstring(arg.t, false));
                        if(arg.val != null) {
                            write(" = ");
                            writeExpr(arg.val);
                        }
                        pendingComma = true;

                    case ENL(e): //newline
                        if (pendingComma){
                            pendingComma = false;
                            write(",");
                        }
                        writeNL();    
                        writeIndent();   

                    case ECommented(s,b,t,e): // comment among arguments
                        if (pendingComma){
                            pendingComma = false;
                            write(",");
                        }
                        writeComment(s);
                    
                    default:

                }
            }
        }

        lvl -= 2;

        return fst;
    }
    
    function writeConstructor(f : Function, isSubClass:Bool)
    {
        //add super if missing, as it is mandatory in Haxe for subclasses
        if (isSubClass == true && constructorHasSuper(f.expr) == false) {
            switch(f.expr) {
                case EBlock(exprs):
                    exprs.unshift(ENL(ECall(EIdent("super"), [])));
                
                default:
            }
        }

        write("function new(");
        writeArgs(f.args);
        write(")");
        writeNL();
        writeIndent();
        writeExpr(f.expr);
    }

    /**
     * Wether constructor method has a super() call
     */
    function constructorHasSuper(expr : Expr) : Bool
    {
        if (expr == null)
            return false;

        return switch(expr) {
            case ECall(EIdent("super"), _):
                true;

            case EBlock(exprs): 
                for (expr in exprs){
                    if (constructorHasSuper(expr)) {
                        return true;
                    }
                }
                false;

            case ENL(expr):
                constructorHasSuper(expr);

            default:
                false;    
        }
    }

    
    function writeFunction(f : Function, isGetter:Bool, isSetter:Bool, isNative:Bool, name : Null<String>, ?ret : FunctionRet)
    {
        write("function");
        if(null != name)
            write(" " + name);
        write("(");
        var fst = writeArgs(f.args);
        write(")");
        // return type
        if (null == ret)
            ret = f.ret;
        writeFunctionReturn(ret, isGetter, isSetter, isNative);

        // ensure the function body is in a block
        var es = [];
        if(f.expr != null) {
            switch(f.expr)
            {
                case EBlock(e):
                    es = es.concat(e);
                case ENL(e): //newline may wrap a block
                    switch (e) {
                        case EBlock(e):
                            es = es.concat(e);
                        default:
                            es.push(f.expr);
                    }
                    
                default:
                    es.push(f.expr);
            }
        }
        // haxe setters must return the provided type
        if(isSetter && !isNative && f.args.length == 1) {
            es.push(ENL(EReturn(EIdent(f.args[0].name))));
        }
        writeExpr(EBlock(es));
    }
    
    /**
     * Write the returned typed of a function and all
     * comments and newline until opening bracket
     */
    function writeFunctionReturn(ret:FunctionRet, isGetter : Bool, isSetter : Bool, isNative : Bool) {
        
        //write return type
        if(isNative) {
            if(isGetter)
                writeVarType(ret.t, "{}", true);
            if(isSetter)
                writeVarType(null, "Void", true);
        }
        else
            writeVarType(ret.t,null,false);

        //write comments and newline after return type
        for (expr in ret.exprs) {
            switch (expr) {
                case ENL(e):
                    writeNL();
                    writeIndent();

                case ECommented(s,b,t,e):
                    writeComment(s);

                default:
            }
        }   
    }

    function writeLoop(incrs:Array<Expr>, f:Void->Void) {
        var old = loopIncrements;
        loopIncrements = incrs.slice(0);
        f();
        loopIncrements = old;
    }
    
    static function ucfirst(s : String)
    {
        return s.substr(0, 1).toUpperCase() + s.substr(1);
    }
    
    function writeVarType(t : Null<T>, ?alt : String, isNativeGetSet:Bool=false)
    {
        if (t == null)
        {
            if (alt != null)
                write(" : " + alt);
            return;
        }
        write(" : " + tstring(t,isNativeGetSet));
    }

    function writeInits(c : ClassDef) {
        if(c.inits == null || c.inits.length == 0)
            return;
        writeNL("");
        writeIndent();
        writeNL("private static var init = {");
        lvl++;
        for(e in c.inits) {
            writeIndent();
            writeExpr(e);
            writeNL(";");
        }
        lvl--;
        writeIndent();
        writeNL("}");
    }
    
    function getConst(c : Const)
    {
        switch(c)
        {
            case CInt( v ), CFloat( v ):
                return v;
            case CString( s ):
                return quote(s);
        }
    }

    function getExprType(e:Expr) : String {
        /*EField(ECall(EField(EIdent(xml),descendants),[]),user)*/
        switch(e) {
            case ETypedExpr(e2, t):
                return tstring(t, false);
            case EField(e2, f):
                var t2 = getExprType(e2);
                //write("/* e2 " + e2 + "."+f+" type: "+t2+" */");
                switch(t2) {
                    case "FastXML":
                        switch(f) {
                            case "descendants", "nodes":
                                return "FastXMLList";
                            case "node":
                                return "FastXML";
                            case "length":
                                return "Int";
                        }
                        return "FastXMLList";
                    case "FastXMLList":
                        switch(f) {
                            case "length": return "Int";
                        }
                    default:
                }
            case EIdent(s):
                s = getModifiedIdent(s);
                //if(context.get(s) == null)
                //  write("/* AS3HX WARNING var " + s + " is not in scope */");
                return context.get(s);
            case EVars(vars):
                if(vars.length != 1)
                    return null;
                return tstring(vars[0].t, false);
            case EArray(n, i):
                return getExprType(n);
            case EUnop(op, prefix, e2):
                return getExprType(e2);
            case EConst(c):
                return switch(c) {
                case CInt(_): "Int";
                case CFloat(_): "Float";
                case CString(_): "String";
                }
            default:
        }
        return null;
    }

    /**
     * Returns the base variable from expressions like xml.user
     * EField(EIdent(xml),user) or EE4XDescend(EIdent(xml), EIdent(user))
     **/
    function getBaseVar(e:Expr) : String {
        switch(e) {
            case EField(e2, f):
                return getExprType(e2);
            case EIdent(s):
                return s;
            case EE4XDescend(e2, e3):
                return getBaseVar(e2);
            default:
        }
        throw "Unexpected " + e;
    }

    function typeExpr(e:Expr) : String {
        switch(e) {
            case EIdent(s):
                return context.get(s);
            default:
        }
        return null;
    }

    function getModifiedIdent(s : String) {
        return switch(s) {
            case "string":              "String";
            case "int":                 "Int";
            case "uint":                cfg.uintToInt ? "Int" : "UInt";
            case "number","Number":     "Float";
            case "boolean","Boolean":   "Bool";
            case "Function":            cfg.functionToDynamic ? "Dynamic" : s;
            case "Object":              "Dynamic";
            case "undefined":           "null";
            //case "Error":     cfg.mapFlClasses ? "flash.errors.Error" : s;
            case "XML":                 "FastXML";
            case "XMLList":             "FastXMLList";
            case "NaN":"Math.NaN";
            //case "QName":     cfg.mapFlClasses ? "flash.utils.QName" : s;
            default: s;
        };
    }

    function writeModifiedIdent(s : String) {
        write(getModifiedIdent(s));
    }

    /**
     * Write an expression
     * @return if the block requires a terminating ;
     **/
    function writeExpr(expr : Expr) : BlockEnd
    {
        if(cfg.debugExpr)
            write(" /* " + Std.string(expr) + " */ ");

        if (expr == null) return None;
        var rv = Semi;
        switch(expr)
        {
            case ETypedExpr( e, t ):
                rv = writeExpr(e);
            case EConst( c ):
                write(getConst(c));
            case EIdent( v ):
                writeModifiedIdent(v);
            case EVars( vars ):
                for (i in 0...vars.length)
                {
                    if (i > 0) {
                        writeNL(";");
                        writeIndent("");
                    }
                    var v = vars[i];
                    context.set(v.name, tstring(v.t, false));
                    write("var " + getModifiedIdent(v.name));
                    writeVarType(v.t);
                    if (null != v.val)
                    {
                        write(" = ");
                        writeExpr(v.val);
                    }
                }
            case EParent( e ):
                write("(");
                writeExpr(e);
                write(")");
            case EBlock( e ):
                if(!isInterface) {
                    openContext();
                    write("{");
                    lvl++;
                    for (ex in e)
                    {
                        writeFinish(writeExpr(ex));
                    }
                    lvl--;
                    write(closeb());
                    closeContext();
                    rv = None;
                } else { write(";"); rv = None; }
            case EField( e, f ):
                var n = checkE4XDescendants(expr);
                if(n != null)
                    return writeExpr(n);
                var t1 = getExprType(expr);
                var t2 = getExprType(e);
                //write("/* EField ("+Std.string(e)+","+Std.string(f)+") " +t1 + ":"+t2+ "  */\n");
                var old = inArrayAccess;
                if(t1 == "FastXMLList" || (t1 == null && t2 == "FastXML")) {
                    //write("/* t1 : " + t1 + " */");
                    writeExpr(e);
                    if(inArrayAccess)
                        write(".nodes." + f);
                    else
                        write(".node." + f + ".innerData");
                }
                else if(t1 == "FastXML" || (t1 == null && t2 == "FastXMLList")) {
                    writeExpr(e);
                    write(".node");
                    write("." + f + ".innerData");
                }
                else {
                    switch(e) {
                        case EField(e2, f2):
                            //write("/* -- " +e2+ " " +getExprType(e2)+" */");
                            if(getExprType(e2) == "FastXML")
                                inArrayAccess = true;
                        default:
                    }
                    writeExpr(e);
                    write("." + f);
                }
                inArrayAccess = old;
            case EBinop( op, e1, e2, newlineBeforeOp):
                if(op == "as") {
                    switch(e2) {
                    case EIdent(s):
                        switch(s) {
                        case "string":
                            write("Std.string(");
                            writeExpr(e1);
                            write(")");
                        case "int":
                            write("Std.parseInt(");
                            writeExpr(e1);
                            write(")");
                            addWarning("as int",false);
                        case "number":
                            write("Std.parseFloat(");
                            writeExpr(e1);
                            write(")");
                        case "Array":
                            write("try cast(");
                            writeExpr(e1);
                            write(", Array</*AS3HX WARNING no type*/>) catch(e:Dynamic) null");
                            addWarning("as array", true);
                        case "Class":
                            addWarning("as Class",true);
                            write("Type.getClass(");
                            writeExpr(e1);
                            write(")");
                        default:
                            write("try cast(");
                            writeExpr(e1);
                            write(", ");
                            switch(e2) {
                            case EIdent(s):
                                writeModifiedIdent(s);
                            default:
                                writeExpr(e2);
                            }
                            write(") catch(e:Dynamic) null");
                        }
                    case EField(_):
                        write("try cast(");
                        writeExpr(e1);
                        write(", ");
                        switch(e2) {
                        case EIdent(s):
                            writeModifiedIdent(s);
                        default:
                            writeExpr(e2);
                        }
                        write(") catch(e:Dynamic) null");
                    case EVector(_):
                        write("try cast(");
                        writeExpr(e1);
                        write(", ");
                        writeExpr(e2);
                        write(") catch(e:Dynamic) null");
                    default:
                        throw "Unexpected " + Std.string(e2);
                    }
                }
                else if(op == "is") {
                    write("Std.is(");
                    writeExpr(e1);
                    write(", ");
                    switch(e2) {
                    case EIdent(s):
                        writeModifiedIdent(s);
                    default:
                        writeExpr(e2);
                    }
                    write(")");
                }
                else if(op == "in") {
                    write("Lambda.has(");
                    writeExpr(e2);
                    write(", ");
                    writeExpr(e1);
                    write(")");
                }
                else { // op e1 e2
                    var eBinop = rebuildBinopExpr(op, e1, e2);
                    if (eBinop != null) return writeExpr(eBinop);
                    
                    var oldInLVA = inLvalAssign;
                    rvalue = e2;
                    if(op == "=")
                        inLvalAssign = true;
                        
                    switch(e1) {
                    case EIdent(s):
                        writeModifiedIdent(s);
                    default:
                        writeExpr(e1);
                    }
                     
                    //for right part of indenting, add 2 extra
                    //indenting level if spead on multiple lines
                    if (op == "=")
                        lvl += 2;

                    inLvalAssign = oldInLVA;
                    if(rvalue != null) {

                        //check wether newline was found just before
                        //op while parsing
                        if (newlineBeforeOp) {
                            writeNL();
                            writeIndent(op);
                        }
                        else {
                            write(" " + op);
                        }
                        
                        //minor formatting fix, if right expression starts
                        //with a newline or comment, no need for extra 
                        switch (e2) {
                            case ECommented(s,b,t,e):
                            case ENL(e):
                            default:write(" ");
                        }

                        switch(e2) {
                        case EIdent(s):
                            writeModifiedIdent(s);
                        default:
                            writeExpr(e2);
                        }
                    }
                    
                    if (op == "=")
                        lvl -= 2;
                }
            case EUnop( op, prefix, e ):
                if (prefix)
                {
                    write(op);
                    writeExpr(e);
                } else {
                    writeExpr(e);
                    write(op);
                }
            case ECall( e, params ):
                //write("/*ECall " + e + "(" + params + ")*/\n");

                //rebuild call expr if necessary
                var eCall = rebuildCallExpr(expr, e, params);
                if (eCall != null) {
                    switch(eCall) {
                        case ECall(e2, params2):
                            e = e2;
                            params = params2;

                        case ECommented(s, b, t, e2):
                            //This is a hack for the AS3 unit test to 
                            //Haxe unit test conversion. In some cases,
                            //the first param of the test if converted
                            //to an end-of-line comment
                            writeExpr(e2);
                            write(";");
                            write("  // "+ s);
                            return None;

                        default:    
                    }
                }

                //func call use 2 levels of indentation if
                //spread on multiple lines
                lvl += 2;

                var handled = false;
                if(cfg.guessCasts && params.length == 1) {
                    switch(e) {
                    case EIdent(n):
                        var c = n.charCodeAt(0);
                        if(n.indexOf(".") == -1 && (c>=65 && c<=90)) {
                            handled = true;
                            switch(n) {
                            case "Number":
                                write("Std.parseFloat(");
                                writeExpr(params[0]);
                                write(")");
                            case "String":
                                write("Std.string(");
                                writeExpr(params[0]);
                                write(")");
                            case "Boolean":
                                write("cast(");
                                writeExpr(params[0]);
                                write(", ");
                                write("Bool)");
                            case "XML":
                                var type = tstring(TPath(["XML"]));
                                write('$type.parse(');
                                writeExpr(params[0]);
                                write(")");
                            default:
                                write("cast((");
                                writeExpr(params[0]);
                                write("), ");
                                write(n + ")");
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
                            if (cfg.useCompat) {
                                write("as3hx.Compat.parseInt(");
                            }
                            else {
                                //if compat class not used, fallback to Haxe
                                //standard lib. 
                                //Add overhead as values need all to be
                                //converted to string beforehand, as there is
                                //no way to know what the type of the expression
                                //at this point and "Std.parseInt" only accepts
                                //strings
                                write("Std.parseInt(Std.string(");
                            }
                            
                            writeExpr(params[0]);

                            write(")");
                            if (!cfg.useCompat) {
                                write(")");
                            }
                            handled = true;
                        }
                    case EVector(t):
                        handled = true;
                        if(cfg.vectorToArray) {
                            writeExpr(params[0]);
                        } else {
                            write("Vector.ofArray(cast ");
                            writeExpr(params[0]);
                            write(")");
                        }
                    default:
                    }
                }
                if(!handled) {
                    //return wether the param at the index is the last
                    //method call argument
                    var isLastArgument:Array<Expr>->Int->Bool = function(params, index) {
                        
                        //return wether the expression is a method call
                        //argument, which excludes comments and newlines
                        var isArgument : Expr->Bool = null;
                        isArgument = function(expr) {
                            if (expr == null)
                                 return false;

                            return switch (expr) {
                                case ECommented(s,b,t,e): isArgument(e);
                                case ENL(e): isArgument(e);
                                default:return true;
                            }
                        }
                        
                        //check all remaining parameters
                        var i = index;
                        while(i <= params.length) {
                            if(isArgument(params[i]))
                                return false;
                            i++;
                        }
                        return true;
                    }

                    writeExpr(e);
                    write("(");
                    for (i in 0...params.length)
                    {
                        if (i > 0) {
                            //check if arguments remain before adding comma
                            if(!isLastArgument(params, i))
                                write(",");

                            //minor formatting fix, if arg is newline or 
                            //comment, no need for extra space
                            switch (params[i]) {
                                case ECommented(s,b,t,e):
                                case ENL(e):
                                default:write(" ");
                            }
                        }
                       
                        writeExpr(params[i]);
                    }
                    write(")");
                }

                lvl -= 2;
            case EIf( cond, e1, e2 ):

                write("if (");
                lvl++; //extra indenting if condition on multiple lines
                var rb = rebuildIfExpr(cond);
                if(rb != null)
                    writeExpr(rb);
                else
                    writeExpr(cond);
                lvl--;
                write(") ");

                //check if if expr is one line
                //with no block bracket
                if (isOneLiner(e1)) {
                    switch (e1) {
                        //if it is, start a new line
                        //if present in formatting
                        case ENL(e): 
                            writeNL();
                            e1 = e;
                        default:    
                    }
                    
                    //add extra level of indent for
                    //teh one liner
                    lvl += 1;
                    writeIndent();
                    lvl -= 1;
                }

                
                writeExpr(e1);
                if (e2 != null)
                {
                    //corner case : comment located
                    //before the "else" keyword in the
                    //source file.
                    //As to be called recursively, in 
                    //case of multiple one-line comment
                    //before the "else"
                    var f:Expr->Expr = null;
                    f = function(e2) {
                        
                        return switch (e2) {
                            case ECommented(s,b,t,e):
                                writeNL();
                                writeIndent(s);
                                f(e); //skip the comment
                            default:
                                e2;
                        }
                    }
                    e2 = f(e2);

                    writeNL();
                    writeIndent("else ");

                    rv = writeExpr(e2);
                } else {
                    rv = getEIfBlockEnd(e1);
                }
            case ETernary( cond, e1, e2 ):
                write("(");
                var rb = rebuildIfExpr(cond);
                if(rb != null)
                    writeExpr(rb);
                else
                    writeExpr(cond);

                write(") ? ");
                writeExpr(e1);
                write(" : ");
                writeExpr(e2);
            case EWhile( cond, e, doWhile ):
                if (doWhile)
                {
                    write("do");
                    writeExpr(e);
                    writeIndent("while (");
                    writeExpr(cond);
                    write(")");
                } else {
                    write("while (");
                    writeExpr(cond);
                    write(")");
                    rv = writeExpr(e);
                }
            case EFor( inits, conds, incrs, e ):
                openContext();
                
                var useWhileLoop:Void->Bool = function() {
                    if (inits.empty() || conds.empty()) return true;
                    if (conds[0].match(EBinop("&&" | "||", _, _, _))) return true;
                    
                    //index must be incremented by 1
                    if (incrs.length == 1) {
                        return switch (incrs[0]) {
                            case EUnop(op, _, _): op != "++";
                            default: false;
                        }
                    }
                    return true;
                }
                var isWhileLoop = useWhileLoop();
                
                if (!isWhileLoop) {
                    write("for (");
                    switch (inits[0]) {
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
                            //corne case, for "<=" binop, limit value should be incremented
                            if (op == "<=") {
                                switch (e2) {
                                    case EConst(CInt(v)):
                                        //increment int constants
                                        var e = EConst(CInt(Std.string(Std.parseInt(v) + 1)));
                                        writeExpr(e2);
                                    default:
                                        //when var used (like <= array.length), no choice but
                                        //to append "+1"
                                        writeExpr(e2);
                                        write(" + 1");
                                }
                            }
                            else {
                                writeExpr(e2);
                            }
                            write(")");
                        default:
                    }
                }
                else {
                    for (init in inits)
                    {
                        writeExpr(init);
                        writeNL(";");
                    }
                    writeIndent();
                    write("while (");
                    if (conds.empty()) {
                        write("true");
                    } else {
                        for (i in 0...conds.length)
                        {
                            if (i > 0)
                                write(" && ");
                            writeExpr(conds[i]);
                        }
                    }
                    write(")");
                }
                
                var es = [];
                var f:Expr->Void = null;
                f = function(e) {
                    switch(e) {
                        case EBlock(ex):
                            es = ex.copy();
                        case ENL(e):
                            f(e);
                        default:
                            es.push(e);
                    }
                }
                f(e);

                //don't write increments for a "for" loop
                if (isWhileLoop) {
                    for (incr in incrs) {
                        es.push(ENL(incr));
                    }
                }

                writeLoop(incrs, function() { writeExpr(EBlock(es)); });
                closeContext();
                rv = None;
            case EForEach( ev, e, block ):

                openContext();
                var varName = null;
                write("for (");
                switch(ev) {
                    case EVars(vars):
                        if(vars.length == 1 && vars[0].val == null) {
                            write(vars[0].name);
                            varName = vars[0].name;
                        } else {
                            writeExpr(ev);
                        }
                    case EIdent(i):
                        varName = i;
                        writeExpr(ev);
                    default:
                        write("/* AS3HX ERROR unhandled " + ev + " */");
                        writeExpr(ev);
                }
                var t = getExprType(e);
                var regexpMap:EReg = ~/^Map<([^,]*, *)?(.*)>$/;
                var regexpArray:EReg = ~/^Array<(.*)>$/;
                if(varName == null) {
                    write("/* AS3HX ERROR varName is null in expression " + e);
                } else if(t == "FastXML" || t == "FastXMLList") {
                    context.set(varName, t);
                } else if (t != null && regexpMap.match(t)) {
                    if (cfg.debugInferredType) {
                        write("/* inferred type: " + regexpMap.matched(1) + " */" );
                    }
                    context.set(varName, regexpMap.matched(1));
                } else if (t != null && regexpArray.match(t)) {
                    if (cfg.debugInferredType) {
                        write("/* inferred type: " + regexpArray.matched(1) + " */" );
                    }
                    context.set(varName, regexpArray.matched(1));
                } else {
                    write("/* AS3HX WARNING could not determine type for var: " + varName + " exp: " + e + " type: " + t + " */");
                }
                write(" in ");
                var old = inArrayAccess;
                inArrayAccess = true;
                writeExpr(e);
                inArrayAccess = old;
                write(")");
                switch(block) {
                    case EBlock(_):
                        null;
                    default:
                }
                rv = writeExpr(block);
                closeContext();
            case EForIn( ev, e, block ):
                openContext();
                var etype = getExprType(e);
                var regexp:EReg = ~/^Map<([^,]*)?,?.*>$/;
                var isMap:Bool = etype != null && regexp.match(etype);
                write("for (");
                switch(ev) {
                    case EVars(vars):
                        if(vars.length == 1 && vars[0].val == null) {
                            write(vars[0].name);
                            if (!isMap || regexp.matched(1) == null) {
                                context.set(vars[0].name, "String");
                            } else if (regexp.matched(1) == "Int") {
                                context.set(vars[0].name, "Int");
                            } else {
                                context.set(vars[0].name, regexp.matched(1));
                            }
                            if (cfg.debugInferredType) {
                                write("/* inferred type: " + context.get(vars[0].name) + " */" );
                            }
                        } else {
                            writeExpr(ev);
                        }
                    default:
                        writeExpr(ev);
                }
                write(" in ");
                if (isMap) {
                    writeExpr(e);
                    write(".keys()");
                } else {
                    write("Reflect.fields(");
                    writeExpr(e);
                    write(")");
                }
                write(")");
                rv = writeExpr(block);
                closeContext();
            case EBreak( label ):
                write("break");
            case EContinue:
                if(loopIncrements != null && loopIncrements.length > 0) {
                    var exp = loopIncrements.slice(0);
                    exp.push(EIdent("continue"));
                    rv = writeExpr(EBlock(exp));
                } else {
                    write("continue");
                }
            case EFunction( f, name ):
                writeFunction(f, false, false, false, name);
            case EReturn( e ):
                write("return");
                if (null != e)
                {
                    write(" ");
                    writeExpr(e);
                }
            case EArray( e, index ):
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
                } else if (etype != null && StringTools.startsWith(etype, "Map")) {
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
                    //write("/*!!!" + etype + "!!!*/");
                    if(etype != null && !StringTools.startsWith(etype, "Array<") && itype != null && itype != "Int" && itype != "UInt") {
                        if (cfg.debugInferredType) {
                            write("/* etype: " + etype + " itype: " + itype + " */");
                        }
                        var isString = (itype == "String");
                        var oldInLVA = inLvalAssign;
                        inLvalAssign = false;
                        if(oldInLVA)
                            write("Reflect.setField(");
                        else
                            write("Reflect.field(");
                        writeExpr(e);
                        inArrayAccess = old;
                        write(", ");
                        if(!isString)
                            write("Std.string(");
                        writeExpr(index);
                        if(!isString)
                            write(")");
                        if(oldInLVA) {
                            write(", ");
                            writeExpr(rvalue);
                            rvalue = null;
                        }
                        inLvalAssign = oldInLVA;
                        write(")");
                    } else {
                        writeExpr(e);
                        inArrayAccess = old;
                        write("[");
                        writeExpr(index); 
                        write("]");
                    }
                }
            case EArrayDecl( e ):
                write("[");
                for (i in 0...e.length)
                {
                    if (i > 0)
                        write(", ");
                    writeExpr(e[i]);
                }
                write("]");
            case ENew( t, params ):
                //write("/* " +context.get(tstring(t,false,false))+ " */");
                var origType = context.get(tstring(t,false,false));
                if(origType == "Class<Dynamic>") {
                    write("Type.createInstance(");
                    write(tstring(t,false,false));
                    write(", [");
                    for (i in 0...params.length)
                    {
                        if (i > 0)
                            write(", ");
                        writeExpr(params[i]);
                    }
                    write("])");
                } 
                //in AS3, if Date constructed without argument, uses current time
                else if (tstring(t) == "Date" && params.length == 0) {
                      write("Date.now()"); //use Haxe constructor for current time
                } else {
                    write("new " + tstring(t) + "(");
                    var out = true;
                    // prevent params when converting vector to array
                    switch(t) {
                    case TVector(_): out = !cfg.vectorToArray;
                    default:
                    }
                    if(out) {
                        for (i in 0...params.length)
                        {
                            if (i > 0)
                                write(", ");
                            writeExpr(params[i]);
                        }
                    }
                    write(")");
                }
            case EThrow( e ):
                write("throw ");
                writeExpr(e);
            case ETry( e, catches ):
                write("try");
                writeExpr(e);
                for (c in catches)
                {
                    writeIndent("catch (" + c.name);
                    writeVarType(c.t, "Dynamic");
                    write(")");
                    rv = writeExpr(c.e);
                }
            case EObject( fl ):
                if (fl.length == 0)
                {
                    write("{ }");
                } else {
                    writeNL("{");
                    lvl++;
                    for (i in 0...fl.length)
                    {
                        var field = fl[i];
                        writeIndent(field.name + " : ");
                        writeExpr(field.e);
                        writeNL(i > 0 || fl.length > 1 ? "," : "");
                    }
                    lvl--;
                    writeNL();
                    writeIndent("}");
                }
            case ERegexp( str, opts ):
                write('new EReg('+eregQuote(str)+', "'+opts+'")');
            case ESwitch( e, cases, def):
                var newCases : Array<CaseDef> = new Array();
                var writeTestVar = false;
                var testVar = switch(e) {
                case EParent(ex):
                    switch(ex) { 
                        case EIdent(i): ex;
                        case ECall(_): ex;
                        default: null; }
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
                newCases = loopCases(cases.slice(0), def == null ? null : def.el.slice(0), testVar, newCases);
  
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
                if (def != null)
                {
                    writeMetaData(def.meta); //write commnent and newline before "default"
                    write("default:");
                    lvl++;
                    for (i in 0...def.el.length)
                    {
                        writeFinish(writeExpr(def.el[i]));
                    }
                    lvl--;
                }
                lvl--;
                write(closeb());
                rv = Ret;
            case EVector( t ):
                // Vector.<T> call
                // _buffers = Vector.<MyType>([inst1,inst2]);
                // t is TPath([inst1,inst2]), which should have been handled in ECall
                write("Array/*Vector.<T> call?*/");
                addWarning("Vector.<T>", true);
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
            case ECommented(s,b,t,ex):
                if(t)
                    rv = writeExpr(ex);
                writeComment(formatComment(s,b));
                    
                if(!t) 
                    rv = writeExpr(ex);

                if (ex == null) rv = Ret;
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
            case EDelete(e):
                switch(e) {
                    case EArray(a, i):
                        var atype = getExprType(a);
                        if (atype != null && StringTools.startsWith(atype, "Map")) {
                            writeExpr(a);
                            write(".remove(");
                            writeExpr(i);
                            write(")");
                        }
                    default:
                        addWarning("EDelete");
                        writeNL("This is an intentional compilation error. See the README for handling the delete keyword");
                        writeIndent("delete ");
                        writeExpr(e);
                }
            case ECondComp( kwd, e , e2):

                var writeECondComp:Expr->Void = null;
                writeECondComp = function(e) {
                    switch(e) {
                        case EBlock(elist):
                            for (ex in elist) {
                                writeFinish(writeExpr(ex));
                            }
                        case ENL(e): 
                            writeECondComp(e);
                        case ECommented(s,b,t,e): writeECondComp(e);
                        default:
                            writeIndent();
                            writeFinish(writeExpr(e));
                    }
                }

                write("#if " + kwd);
                writeECondComp(e);
                writeNL();
                if (e2 != null) {
                    writeIndent("#else");
                    writeECondComp(e2);
                    writeNL();
                }
                writeIndent("#end // " + kwd);
                writeNL();
                writeIndent();
                rv = Ret;

            case ENL( e ): 
                //newline starts new indented line before parsing
                //wrapped expression
                writeNL( );
                writeIndent( );
                rv = writeExpr(e);
            case EImport(s):   
        }
        return rv;
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
    function writeE4XFilterExpr(e1, e2) {
        if(inE4XFilter)
            throw "Unexpected E4XFilter inside E4XFilter";

        write("FastXML.filterNodes(");
        //write("/*"+Std.string(e1)+"*/");
        var n = getBaseVar(e1);    // make sure it's set to FastXML in the
        if(n != null)
            context.set(n, "FastXML"); // current context
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

    /**
     * Rebuilds any E4X expression to check for instances where the string value
     * is compared to a numerical constant, and change all EIdent instances to
     * the FastXML version.
     * @return expr ready for writing
     **/
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
            return EIdent("x.node."+id+".innerData");
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
     **/
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
     **/
    function rebuildIfExpr(e:Expr) : Expr {
        var isNumericType = function(s) {
            return (s == "Float" || s == "Int" || s == "UInt");
        }
        switch(e) {
        case EIdent(id):
            if(id == "null")
                return null;
            var t = getExprType(e);
            if(t == null || t == "Bool")
                return null;
            if(isNumericType(t))
                return EBinop("!=", e, EConst(CInt("0")), false);
            return EBinop("!=", e, EIdent("null"), false);
        case EBinop(op, e2, e3, n):
            if(isNumericConst(e2) || isNumericConst(e3))
                return null;
            if(op == "==" || op == "!=" || op == "!==" || op == "===")
                return null;
            if(op == "is" || op == "in" || op == "as")
                return null;
            if(op == "<" || op == ">" || op == ">=" || op == "<=")
                return null;
            if(op == "?:")
                return null;
            if(op == "&" || op == "|" || op == "^")
                return EBinop("!=", e, EConst(CInt("0")), false);
            var r1 = rebuildIfExpr(e2);
            var r2 = rebuildIfExpr(e3);
            if(r1 == null) r1 = e2;
            if(r2 == null) r2 = e3;
            return EBinop(op, r1, r2, n);
        case EUnop(op, prefix, e2):
            var r2 = rebuildIfExpr(e2);
            if(r2 == null)
                return null;
            if(op == "!") {
                if(!prefix)
                    return null;
                switch(r2) {
                    case EBinop(op2, e3, e4, n):
                        if(op2 == "==") return EBinop("!=", e3, e4, n);
                        if(op2 == "!=") return EBinop("==", e3, e4, n);
                    default:
                }
                return null;
            }
            var t = getExprType(e2);
            if(t == null) return null;
            if(isNumericType(t))
                return EBinop("!=", e, EConst(CInt("0")), false);
            return EBinop("!=", e, EIdent("null"), false);
        case EParent(e2):
            var r2 = rebuildIfExpr(e2);
            if(r2 == null) return null;
            return EParent(r2);
        case ECall(e2, params): //These would require a full typer
        case EField(e2, f):
            null;
        case ENL(e): 
            var expr = rebuildIfExpr(e);
            if (expr != null) {
                return ENL(expr);
            }
            else {
                return null;
            }
            
        default:
        }
        return null;
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
        var rebuiltCall = null;

        //utils returning the ident string of an
        //expr or null if the expr is not an ident
        var getIdentString = function(expr) {
            return switch (expr) {
                case EIdent(v):
                    v;
                default:
                    null;
            }
        }

        switch (expr) {
            case EField(e, f):
                //replace "myVar.hasOwnProperty(myProperty)" by "myVar.exists(myProperty)"
                if (f == "hasOwnProperty") {
                    var rebuiltExpr = EField(e, "exists");
                    rebuiltCall = ECall(rebuiltExpr, params);
                }
                else if (f == "slice") {
                    var type = getExprType(e);
                    if (type != null) {
                        if (type.indexOf("String") != -1) {
                            //replace AS3 slice by Haxe substr
                            var rebuiltExpr = EField(e, "substring");
                            rebuiltCall = ECall(rebuiltExpr, params);
                        } else if(type.indexOf("Array") != -1 && params.empty()) {
                            var rebuiltExpr = EField(e, "copy");
                            rebuiltCall = ECall(rebuiltExpr, params);
                        }
                    }
                }
                else if (f == "indexOf") {
                    //in AS3, indexOf is a method in Array while it is not in Haxe
                    //Replace it by the Labda.indexOf method
                    var type = getExprType(e);
                    if (type != null) {
                        //determine wheter the calling object is an Haxe iterable
                        //if it is, rebuild the expression to use Lamda
                        if (type.indexOf("Array") != -1 || type.indexOf("Map") != -1) {
                            var rebuiltExpr = EField(EIdent("Lambda"), "indexOf");
                            params.unshift(e);
                            rebuiltCall = ECall(rebuiltExpr, params);
                        }
                    }
                }
                else if (f == "toString") {
                    //replace AS3 toString by Haxe Std.string
                    var rebuiltExpr = EField(EIdent("Std"), "string");
                    rebuiltCall = ECall(rebuiltExpr, [e]);
                }
                else if (f == "concat" && params.empty()) {
                    var type = getExprType(e);
                    if (type != null && type.indexOf("Array") != -1) {
                        var rebuildExpr = EField(e, "copy");
                        rebuiltCall = ECall(rebuildExpr, params);
                    }
                }
                else if (f == "charAt") {
                    var type = getExprType(e);
                    if (type != null && type.indexOf("String") != -1 && params.empty()) {
                        var rebuildExpr = EField(e, "charAt");
                        rebuiltCall = ECall(rebuildExpr, [EConst(CInt("0"))]);
                    }
                }
                else if (f == "charCodeAt") {
                    var type = getExprType(e);
                    if (type != null && type.indexOf("String") != -1 && params.empty()) {
                        var rebuildExpr = EField(e, "charCodeAt");
                        rebuiltCall = ECall(rebuildExpr, [EConst(CInt("0"))]);
                    }
                }
                else if (getIdentString(e) != null) {
                    var ident = getIdentString(e);
                    //replace AS3 StringUtil by Haxe StringTools
                    if (ident == "StringUtil") {
                        var rebuiltExpr = EField(EIdent("StringTools"), f);
                        rebuiltCall = ECall(rebuiltExpr, params);
                    } else if (ident == "JSON") {
                        var rebuiltExpr = EField(EIdent("haxe.Json"), f);
                        rebuiltCall = ECall(rebuiltExpr, params);
                    }
                }

            default:
                var ident = getIdentString(expr);
                if (ident != null) {
                    //utils returning a string representation
                    //of the provided param
                    var getCommentedParam = function(param) {
                        return switch(param) {
                            case EConst(CString(s)):
                                return s;
                            case EIdent(id):
                                return id;
                            default: null;
                        }
                    }

                    //helper to convert an AS3 test case to an Haxe one
                    var getUnitTestExpr = function(rebuiltExpr, params, commentFirstParam) {
                        var rebuiltCall = ECall(rebuiltExpr, params);
                        
                        //in some cases, the first param is a description of the test, 
                        //which should be converted to a comment
                        if (commentFirstParam) {
                            var comment = getCommentedParam(params.shift());
                            rebuiltCall = ECommented(comment, false, true, rebuiltCall);
                        }
                        return rebuiltCall;
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
                                    rebuiltCall = ECall(rebuiltExpr, []);
                                }
                            }

                        //convert AS3 unit tests to Haxe tests
                        case "assertTrue":
                            var rebuiltExpr = EField(EIdent("Assert"), "isTrue");
                            rebuiltCall = getUnitTestExpr(rebuiltExpr, params, params.length == 2);

                        case "assertFalse":
                            var rebuiltExpr = EField(EIdent("Assert"), "isFalse");
                            rebuiltCall = getUnitTestExpr(rebuiltExpr, params, params.length == 2); 

                         case "assertEquals":
                            var rebuiltExpr = EField(EIdent("Assert"), "areEqual");
                            rebuiltCall = getUnitTestExpr(rebuiltExpr, params, params.length == 3);     

                        case "assertNull":
                            var rebuiltExpr = EField(EIdent("Assert"), "isNull");
                            rebuiltCall = getUnitTestExpr(rebuiltExpr, params, params.length == 2); 

                        case "assertNotNull":
                            var rebuiltExpr = EField(EIdent("Assert"), "isNotNull");
                            rebuiltCall = getUnitTestExpr(rebuiltExpr, params, params.length == 2);     

                        case "assertThat":
                            rebuiltCall = getUnitTestExpr(EIdent(ident), params, params.length == 3);     

                        case "fail":
                            var rebuiltExpr = EField(EIdent("Assert"), "fail");
                            rebuiltCall = getUnitTestExpr(rebuiltExpr, params, false);            
                    }
                }
        }
        return rebuiltCall;
    }

    function rebuildBinopExpr(op:String, lvalue:Expr, rvalue:Expr):Expr {
        if(cfg.useCompat && op == "=") {
            switch(lvalue) {
                case EField(e, f):
                    if (f == "length") {
                        var type = getExprType(e);
                        if (type != null && type.indexOf("Array") != -1) {
                            return ECall(EField(EIdent("as3hx.Compat"), "setArrayLength"), [e, rvalue]);
                        }
                    }
                default:
            }
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
    function isOneLiner(e : Expr) : Bool
    {
        return switch (e) {
            case ENL(e): //ignore newline
                return isOneLiner(e);

            case ECommented(s,b,t,e): //ignore comment
                return isOneLiner(e);

            case EBlock(e): //it is a regular block
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
        for (expr in expressions)
        {
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

    /**
     * Checks if 'e' represents a numerical constant value
     * @return true if so
     **/
    function isNumericConst(e:Expr) : Bool {
        switch(e) {
        case EConst(c):
            switch(c) {
            case CInt(_), CFloat(_):
                return true;
            default:
            }
        default:
        }
        return false;
    }

    function addWarning(type:String, isError = false) {
        warnings.set(type, isError);
    }
    
    static function quote(s : String)
    {
        return '"' + StringTools.replace(s, '"', '\\"') + '"';
    }

    static function eregQuote(s : String)
    {
        return "'" + StringTools.replace(s, "\\", "\\\\") + "'";
    }
    
    function isOverride(kwds : Array<String>)
    {
        return Lambda.has(kwds, "override");
    }
    
    function isStatic(kwds : Array<String>)
    {
        return Lambda.has(kwds, "static");
    }
    
    function isPublic(kwds : Array<String>)
    {
        return Lambda.has(kwds, "public");
    }

    function isPrivate(kwds : Array<String>)
    {
        return Lambda.has(kwds, "private");
    }

    function isInternal(kwds : Array<String>)
    {
        return Lambda.has(kwds, "internal");
    }
    
    function isFinal(kwds : Array<String>)
    {
        return Lambda.has(kwds, "final");
    }
    
    function isProtected(kwds : Array<String>)
    {
        return Lambda.has(kwds, "protected");
    }

    function isGetter(kwds : Array<String>)
    {
        return Lambda.has(kwds, "get");
    }
    
    function isSetter(kwds : Array<String>)
    {
        return Lambda.has(kwds, "set");
    }

    function isConst(kwds : Array<String>)
    {
        return Lambda.has(kwds, "const");
    }
    
    function istring(t : T, fixCase:Bool=true)
    {
        if(t == null) return null;
        switch(t)
        {
        case TStar:     return null;
        case TVector( t ):  return null;
        case TComplex(e):   return null;
        case TPath( p ):
            if (p.length > 1)   return null;
            var c = p[0];
            switch(c)
            {
            case "int": return null;
            case "uint":    return null;
            case "void":    return null;
            default:    return fixCase ? properCase(c,true) : c;
            }
        case TDictionary(k, v): return null;
        }
    }
    
    function tstring(t : T, isNativeGetSet:Bool=false, fixCase:Bool=true)
    {
        if(t == null)
            return null;
        switch(t)
        {
            case TStar:
                return "Dynamic";
            case TVector( t ):
                return cfg.vectorToArray ? "Array<" + tstring(t) + ">" : "Vector<" + tstring(t) + ">";
            case TPath( p ):
                var c = p.join(".");
                return switch(c)
                {
                    case "Array"    : "Array<Dynamic>";
                    case "Boolean"  : "Bool";
                    case "Class"    : "Class<Dynamic>";
                    case "int"      : "Int";
                    case "Number"   : "Float";
                    case "uint"     : cfg.uintToInt ? "Int" : "UInt";
                    case "void"     : "Void";
                    case "Function" : cfg.functionToDynamic ? "Dynamic" : c;
                    case "Object"   : isNativeGetSet ? "{}" : "Dynamic";
                    case "XML"      : cfg.useFastXML ? "FastXML" : "Xml";
                    case "XMLList"  : cfg.useFastXML ? "FastXMLList" : "Iterator<Xml>";
                    case "RegExp"   : "EReg";
                    default         : fixCase? properCase(c,true) : c;
                }
            case TComplex(e):
                return buffer(function() { writeExpr(e); });
            case TDictionary(k, v):
                return "Map<" + tstring(k) + ", " + tstring(v) + ">";
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
       var funcAsClassField : ClassField = {
           name : fDef.name,
           meta : fDef.meta,
           condVars : [],
           kwds : fDef.kwds,
           kind : FFun(fDef.f)
       };

       //uppercase func name first letter
       var name = fDef.name.charAt(0).toUpperCase() + fDef.name.substr(1);

       //generate class doc
       var meta = [];
       meta.push(ENL(null));
       meta.push(ECommented("/**\n * Class for " + fDef.name + "\n */",false,false,null));
       meta.push(ENL(null));


       //builds the class definition
       return {
            name : "ClassFor" + name,
            meta:meta,
            kwds:["final"], //always final as generated class
            imports:[],
            isInterface : false,
            extend : null,
            implement : [],
            fields:[funcAsClassField],
            inits : []
       };
    }
    
    function writeNamespaceDef(n : NamespaceDef)
    {
        
    }

    function loopCases(cases : Array<SwitchCase>, def: Null<Array<Expr>>, testVar:Expr, out:Array<CaseDef>) {
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

    function openb()
    {
        if (cfg.bracesOnNewline)
            return cfg.newlineChars + indent() + "{";
        else
            return " {";
    }
    
    function closeb()
    {
        return cfg.newlineChars + indent() + "}";
    }
    
    function write(s : String)
    {
        //set line as dirty if string contains something other
        //than whitespace/indent
        if (!containsOnlyWhiteSpace(s) && s != cfg.indentChars)
            lineIsDirty = true;

        o.writeString(s);
    }
    
    /** write Haxe "allow" metadata using current package */
    function writeAllow() {
        write("@:allow("+properCaseA(this.pack,false).join(".")+")");
        writeNL();
        writeIndent();
    }

   /**
    * Writing for block and line comment. If 
    * comment written on dirty line (not first text on line),
    * add extra whitespace before and after comment
    */
    function writeComment(s : String)
    {
        if (lineIsDirty)
            s = "  " + s + "  ";

        write(s);    
    }

    function writeIndent(s = "")
    {
        write(indent() + s);
    }
    
    function writeLine(s = "")
    {
        lineIsDirty = false;

        write(indent() + s + cfg.newlineChars);
    }
    
    function writeNL(s = "")
    {
        lineIsDirty = false; //reset line dirtyness

        write(s);
        write(cfg.newlineChars);
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
            write("typedef "+genType.name+"Typedef" + " = {");
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

    /**
     * Switches output to a string accumulator
     * @return contents of buffer after calling f()
     **/
    function buffer(f:Void->Void) : String {
        var old = o;
        o = new haxe.io.BytesOutput();
        f();
        var rv = untyped o.getBytes().toString();
        o = old;
        return rv;
    }
    
    function indent()
    {
        var b = [];
        for (i in 0...lvl)
            b.push(cfg.indentChars);
        return b.join("");
    }
    
    public function process(program : Program, writer : Output)
    {
        this.warnings = new Map();

        //list of imported types must be reseted for each file,
        //as only one instance of Writer write all the files
        this.imported = [];

        var defined:Array<String> = [];

        for (type in program.typesDefd)
            defined.push(type.name);

        switch(program.defs[0]) {
            case CDef(c):
                for (meta in c.meta) {
                    switch (meta) {
                    case EImport(v):
                        defined.push(v[v.length-1]);
                    default:
                    }
                }
            default:
        }

        this.o = writer;
        this.genTypes = program.genTypes;
        this.pack = program.pack;
        writeComments(program.header);
        writePackage(program.pack);
        writeImports(program.imports);
        writeAdditionalImports(program.pack, program.typesSeen, defined);
        writeGeneratedTypes(program.genTypes);
        writeDefinitions(program.defs);
        writeComments(program.footer);
        return this.warnings;
    }

    /**
     * This method outputs each warning and the associated affected files.
     * By doing it this way, it becomes easy to see all the places a specific
     * warning is affecting, so that the porter can more easily determine
     * the fix.
     **/
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
                case "EDelete": println("FATAL: Files will not compile due to 'delete' keyword. See README");
                default: println("WARNING: " + warn);
                }
                for(f in a)
                    println("\t"+f);
            }
        }
    }

    public static function properCase(pkg:String, hasClassName:Bool) {
        return properCaseA(pkg.split("."), hasClassName).join(".");
    }

    public static function properCaseA(path:Array<String>, hasClassName:Bool):Array<String> {
        var p = [];
        for(i in 0...path.length) {
            if(hasClassName && i == path.length - 1)
                p[i] = removeUnderscores(path[i]);
            else
                p[i] = path[i].toLowerCase();
        } 
        if(hasClassName) {
            var f = p[p.length-1];
            var o = "";
            for(i in 0...f.length) {
                var c = f.charCodeAt(i);
                if(i == 0)
                    o += String.fromCharCode(c).toUpperCase();
                else
                    o += String.fromCharCode(c);
            }
            p[p.length-1] = o;
        }
        return p;
    }

    public static function removeUnderscores(id : String) {
        return id.split("_").map( 
            function (v:String) return v.length > 0 ? v.charAt(0).toUpperCase() + v.substr(1) : ""
        ).array().join("");
    }
    
}
