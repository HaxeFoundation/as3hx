# as3hx [![Build Status](https://travis-ci.org/HaxeFoundation/as3hx.svg?branch=master)](https://travis-ci.org/HaxeFoundation/as3hx)
Convert ActionScript 3 to Haxe 3 code.

### Build
You'll need Haxe 3.* to build the project and Neko 2.* to run it.
    
    haxe --no-traces as3hx.hxml
Build the as3hx tool.

    haxe -debug as3hx.hxml
Build with debug output when converting files.

### Use

    neko run.n test/ out/
    
This will take all the ActionScript 3 files in the test/ directory 
and generate the corresponding Haxe files in out/

To generate the tests you can also use :

    make run-test

This will generate the tests in test-out

To get the basic tool usage :

    neko run.n -help

### Config

There are many configuration options to choose how the Haxe code
is generated, check the src/as3hx/Config.hx file for the full list.

as3hx looks for, or creates, a config file in your home directory
called ".as3hx_config.xml". You can also create one in the directory
you are running as3hx from, which will override the home file.


#### Licence

MIT, see [LICENCE.md](LICENCE.md)



### Current failures:

#### 'delete' keyword:
In ActionScript, the `delete` keyword will cause an intentional failure in the
generated .hx file. Take a close look at the object being deleted.

1. if it is a local variable, replace `delete varname` with `varname = null`
2. if it is a class member variable, remove the `delete` entirely
3. it it is an E4X (FastXML), well, hmmm... still working on that one.

Senocular did a little writeup on `delete` that might make it more clear
http://www.kirupa.com/forum/showthread.php?223798-ActionScript-3-Tip-of-the-Day/page3


#### E4X:
E4X is currently partly done. This will fail in some cases, just examine source
and output carefully.

### AS3 markup
You can use comments in ActionScript 3 code to enchance quality of conversion

#### Haxe code injection
Use comment `/*haxe:*/` in arbitrary place in code to inject enclosed string as a raw Haxe code.

    /*haxe:
    methodToCallInHaxe();
    */

    var trueInHaxe:Boolean = /*haxe:true;//*/false;

Use conditional compilation blocks to hide AS3 code from Haxe compiler

    CONFIG::AS3 {
        methodToCallInAs3();
    }

#### Type hints
Use comment `/*haxe:*/` after AS3 type to override AS3 type with type from comment.

    var o:*/*haxe:utils.RawData*/ = {};

You can use it to define strict Haxe function types:

    function registerCallback(callback:Function/*haxe:Event->Void*/):void { }



Use comment `/*<>*/` to force Haxe type parameters on AS3 types:

    var b:Dictionary = new Dictionary/*<Int,String>*/();
    
    public class ItemRenderer/*<ItemValue>*/ {
    }
 
### Conversion tips
The bigger part of the complete project is converted at once, the better results you will get since type info takes a great role in conversion.

You can chain src paths `neko as3hx.n "src\path\1" "src\path\2" "src\path\2"` if your project has more than one src path.

Use `-libPath "path\to\as3\classes"` command line parameter to define path with all related code that should be taken into account during conversion but should not be converted by itself. The internal directory structure is not important since only package names are taken into consideration.

For better results include interfaces to swc libraries that you use in your project. You can decompile swcs to get such interfaces.

It's a good idea to include decompiled interfaces from playerglobal.swc to enhance interaction with Flash API.



### Disclaimer
This fork is made for a single project in mind. So there are probably some breaking changes in formatting of converted code for different code styles.

Also there are no publicly available test cases for added functionality.
