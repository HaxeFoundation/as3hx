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

#### For Initializations:
The output of

```as3
if (true) {
    for (var i:uint = 0; i < 7; i++)
        val += "0";
} else {
    for (i = 0; i < 8; i++)
        val += "0";
}
```

is

```haxe
if (true) {
    var i:UInt = 0;
    while (i < 7) {
        val += "0";
        i++;
    }
} else {
    i = 0;
    while (i < 8) {
        val += "0";
        i++;
    }
}
```

As you can see, the scope of `i` in Flash is not the same as in Haxe,
so the `else` section will produce Unknown identifier : i. The solution
is to move the `var i : UInt = 0;` outside of the blocks in the generated
code.

This can not be avoided by always creating the `i` variable, as the code

```as3
for (var i:uint = 0; i < 7; i++)
    val += "0";
for (i = 0; i < 8; i++)
    val += "0";
```

would then produce a double initialization of `i`, also causing a compiler error.

```haxe
var i:UInt = 0;
while (i < 7) {
    val += "0";
    i++;
}
var i = 0;
while (i < 8) {
    val += "0";
    i++;
}
```
