package as3hx;
import as3hx.Config;
import as3hx.Parser;
import as3hx.Writer;
import haxe.io.BytesOutput;
import massive.munit.Assert;
import sys.FileSystem;
import sys.io.File;

class AS3HXTest {

    public function new() {}

    var cfg:Config;
    var parser:Parser;
    var writer:Writer;
    var output:haxe.io.BytesOutput;

    @BeforeClass
    public function beforeClass() {
        cfg = new Config();
        parser = new Parser(cfg);
        writer = new Writer(cfg);
        output = new BytesOutput();
    }
    
    @Test
    public function issue14() {
        generate("Issue14.as", "Issue14.hx");
    }

    @Test
    public function issue15() {
        generate("Issue15.as", "Issue15.hx");
    }

    @Test
    public function issue23() {
        generate("Issue23.as", "Issue23.hx");
    }

    @Test
    public function issue24() {
        generate("Issue24.as", "Issue24.hx");
    }

    @Test
    public function issue26() {
        generate("Issue26.as", "Issue26.hx");
    }

    @Test("ternarny operator")
    public function issue28() {
        generate("Issue28.as", "Issue28.hx");
    }

    @Test
    public function issue29() {
        generate("Issue29.as", "Issue29.hx");
    }

    @Test("array.concat() -> array.copy()")
    public function issue32() {
        generate("Issue32.as", "Issue32.hx");
    }

    @Test("string.charCodeAt() -> string.charCodeAt(0)")
    public function issue36() {
        generate("Issue36.as", "Issue36.hx");
    }

    @Test("Xml(string) -> FastXML.parse(string)")
    public function issue37() {
        generate("Issue37.as", "Issue37.hx");
    }

    @Test
    public function issue38() {
        generate("Issue38.as", "Issue38.hx");
    }

    @Test("private var name = 'value'")
    public function issue52() {
        generate("Issue52.as", "Issue52.hx");
    }

    @Test
    public function issue53() {
        generate("Issue53.as", "Issue53.hx");
    }

    @Test("flash.display.Dictionary -> haxe.ds.ObjectMap<Dynamic, Dynamic>")
    public function issue54() {
        cfg.dictionaryToHash = true;
        generate("Issue54.as", "Issue54.hx");
        cfg.dictionaryToHash = false;
    }

    @Test("array.length = 10 -> Compat.setArrayLegth(array, 10)")
    public function issue63() {
        generate("Issue63.as", "Issue63.hx");
    }

    @Test("for (var i:int = 0, n:int = array.length; i < n; i++)")
    public function issue64() {
        generate("Issue64.as", "Issue64.hx");
    }

    @Test
    public function issue65() {
        generate("Issue65.as", "Issue65.hx");
    }

    @Test("var i:int = (int)(number) -> var i:Int = as3hx.Compat.parseInt(number)")
    public function issue66() {
        generate("Issue66.as", "Issue66.hx");
    }

    @Test("array.slice() -> array.copy()")
    public function issue68() {
        generate("Issue68.as", "Issue68.hx");
    }

    @Test("string.charAt() -> string.charAt(0)")
    public function issue69() {
        generate("Issue69.as", "Issue69.hx");
    }

    @Test("function(...args) -> function(args:Array<Dynamic>")
    public function issue70() {
        generate("Issue70.as", "Issue70.hx");
    }

    @Test
    public function issue71() {
        generate("Issue71.as", "Issue71.hx");
    }

    @Test
    public function issue81() {
        generate("Issue81.as", "Issue81.hx");
    }

    @Test("JSON.parse(string) -> haxe.Json.parse(string)")
    public function issue83() {
        generate("Issue83.as", "Issue83.hx");
    }

    @Test("var i:uint = uint(1) -> var i:Int = 1")
    public function issue85() {
        generate("Issue85.as", "Issue85.hx");
    }

    @Test
    public function issue87() {
        generate("Issue87.as", "Issue87.hx");
    }

    @Test("NaN -> Math.NaN")
    public function issue89() {
        generate("Issue89.as", "Issue89.hx");
    }

    @Test("var b:Boolean = !int_value -> var b:Bool = int_value != 0")
    public function issue91() {
        generate("Issue91.as", "Issue91.hx");
    }

    @Test("[].join() -> [].join(',')")
    public function issue93() {
        generate("Issue93.as", "Issue93.hx");
    }

    @Test("array.push(1,2,3,4,5,6,7,8,9,0)")
    public function issue94() {
        generate("Issue94.as", "Issue94.hx");
    }

    @Test
    public function issue95() {
        generate("Issue95.as", "Issue95.hx");
    }

    @Test("s is String ? 1 : 0")
    public function issue96() {
        generate("Issue96.as", "Issue96.hx");
    }

    @Test
    public function issue103() {
        generate("Issue103.as", "Issue103.hx");
    }

    @Test("setTimeout() -> as3hx.Compat.setTimeout()")
    public function issue112() {
        generate("Issue112.as", "Issue112.hx");
    }

    @Test
    public function issue115() {
        generate("Issue115.as", "Issue115.hx");
    }

    @Test("/pattern/flags.exec(string) -> as3hx.Compat.FlashRegExp(pattern, flags).exec(string)")
    public function issue119_useCompat() {
        generate("Issue119.as", "Issue119_useCompat.hx");
    }

    @Test("/pattern/flags.exec(string) -> flash.utils.RegExp(pattern, flags).exec(string)")
    public function issue119_notUseCompat() {
        cfg.useCompat = false;
        generate("Issue119.as", "Issue119_notUseCompat.hx");
        cfg.useCompat = true;
    }

    @Test("function.apply(null, args) -> Reflect.callMethod(null, function, args)")
    public function issue120() {
        generate("Issue120.as", "Issue120.hx");
    }

    @Test("delete object['key']")
    public function issue121() {
        generate("Issue121.as", "Issue121.hx");
    }

    @Test("delete dictionary['key']")
    public function issue124() {
        generate("Issue124.as", "Issue124.hx");
    }

    @Test("if(number) -> if((number != 0 && !Math.isNaN(number)))")
    public function issue128() {
        generate("Issue128.as", "Issue128.hx");
    }

    @Test("int.MIN_VALUE -> as3hx.Compat.INT_MIN, int.MAX_VALUE -> as3hx.Compat.INT_MAX")
    public function issue133() {
        generate("Issue133.as", "Issue133.hx");
    }

    @Test
    public function issue134() {
        generate("Issue134.as", "Issue134.hx");
    }

    @Test("Number.MIN_VALUE -> as3hx.Compat.FLOAT_MIN, Number.MAX_VALUE -> as3hx.Compat.FLOAT_MAX")
    public function issue139() {
        generate("Issue139.as", "Issue139.hx");
    }

    @Test
    public function issue142() {
        generate("Issue142.as", "Issue142.hx");
    }

    @Test("import flash.display3D.Context3D;")
    public function issue143() {
        generate("Issue143.as", "Issue143.hx");
    }

    @Test
    public function issue144() {
        generate("Issue144.as", "Issue144.hx");
    }

    @Test("function enqueue(...rawAssets) -> function enqueue(rawAssets : Array<Dynamic> = null)")
    public function issue148() {
        generate("Issue148.as", "Issue148.hx");
    }

    @Test
    public function issue150() {
        generate("Issue150.as", "Issue150.hx");
    }

    @Test
    public function issue152() {
        generate("Issue152.as", "Issue152.hx");
    }

    @Test
    public function issue156() {
        generate("Issue156.as", "Issue156.hx");
    }

    @Test("Object(this).constructor as Class")
    public function issue158() {
        generate("Issue158.as", "Issue158.hx");
    }

    @Test("parseInt(n) -> as3hx.Compat.parseInt(n), parseFloat(n) -> as3hx.Compat.parseFloat(n)")
    public function issue162() {
        generate("Issue162.as", "Issue162.hx");
    }

    @Test
    public function issue164() {
        generate("Issue164.as", "Issue164.hx");
    }

    @Test("array.splice(0,0,1,2,3,4,5) -> as3hx.Compat.arraySplice(a, 0, 0, [1,2,3,4,5])")
    public function issue165() {
        generate("Issue165.as", "Issue165.hx");
    }

    @Test("number_value.toFixed(fractionDigits) -> as3hx.Compat.toFixed(number_value, fractionDigits)")
    public function issue166() {
        generate("Issue166.as", "Issue166.hx");
    }

    @Test("||=")
    public function issue167() {
        generate("Issue167.as", "Issue167.hx");
    }

    @Test("function.call(null, 1,2,3,4,5,6,7,8,9,0) -> Reflect.callMethod(null, function, [1,2,3,4,5,6,7,8,9,0])")
    public function issue176() {
        generate("Issue176.as", "Issue176.hx");
    }

    @Test
    public function issue178() {
        generate("Issue178.as", "Issue178.hx");
    }

    @Test("array.insertAt(position, element) -> array.insert(position, element)")
    public function issue184() {
        generate("Issue184.as", "Issue184.hx");
    }

    @Test("array.removeAt(0) -> array.splice(0, 1)[0]")
    public function issue185() {
        generate("Issue185.as", "Issue185.hx");
    }

    @Test
    public function issue187() {
        generate("Issue187.as", "Issue187.hx");
    }

    @Test
    public function issue192() {
        generate("Issue192.as", "Issue192.hx");
    }

    @Test("&&=")
    public function issue198() {
        generate("Issue198.as", "Issue198.hx");
    }

    @Test("getQualifiedClassName(this) -> Type.getClassName(Type.getClass(this))")
    public function issue200() {
        generate("Issue200.as", "Issue200.hx");
    }

    @Test("string.replace(new Regex(pattern, opts), by) -> new Regex(pattern, opts).replace(string, by)")
    public function issue202() {
        generate("Issue202.as", "Issue202.hx");
    }

    @Test
    public function issue204() {
        generate("Issue204.as", "Issue204.hx");
    }

    @Test("function.length -> as3hx.Compat.getFunctionLength(function)")
    public function issue205() {
        generate("Issue205.as", "Issue205.hx");
    }

    @Test
    public function issue208() {
        generate("Issue208.as", "Issue208.hx");
    }

    @Test("Number.NaN -> Math.NaN")
    public function issue210() {
        generate("Issue210.as", "Issue210.hx");
    }

    @Test
    public function issue213() {
        generate("Issue213.as", "Issue213.hx");
    }

    @Test
    public function issue214() {
        generate("Issue214.as", "Issue214.hx");
    }

    @Test("string.replace(regex, by) -> regex.replace(string, by)")
    public function issue215() {
        generate("Issue215.as", "Issue215.hx");
    }

    @Test("string.replace(stribg_sub, by) -> StringTools.replace(string, stribg_sub, by)")
    public function issue218() {
        generate("Issue218.as", "Issue218.hx");
    }

    @Test("Math.min(1, 2, 3) -> Math.min(Math.min(1, 2), 3)")
    public function issue223() {
        generate("Issue223.as", "Issue223.hx");
    }

    @Test
    public function issue226() {
        cfg.dictionaryToHash = true;
        generate("Issue226.as", "Issue226.hx");
        cfg.dictionaryToHash = false;
    }

    @Test("Number.POSITIVE_INFINITY -> Math.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY -> Math.NEGATIVE_INFINITY")
    public function issue228() {
        generate("Issue228.as", "Issue228.hx");
    }

    @Test("new Dictionary(true) -> new haxe.ds.ObjectMap<Dynamic, Dynamic>()")
    public function issue230() {
        cfg.dictionaryToHash = true;
        generate("Issue230.as", "Issue230.hx");
        cfg.dictionaryToHash = false;
    }

    @Test("flash.display3D.Context3D['supportsVideoTexture'] -> Reflect.field(flash.display3D.Context3D, 'supportsVideoTexture')")
    public function issue234() {
        generate("Issue234.as", "Issue234.hx");
    }

    @Test("if(!(mask & flag)) -> if((mask & flag) == 0), if((mask & flag)) -> if((mask & flag) != 0)")
    public function issue235() {
        cfg.dictionaryToHash = true;
        generate("Issue235.as", "Issue235.hx");
        cfg.dictionaryToHash = false;
    }

    @Test("x &= y -> x = x & y; x |= y -> x = x | y; x ^= y -> x = x ^ y")
    public function issue238() {
        generate("Issue238.as", "Issue238.hx");
    }

    @Test("d is Dictionary -> Std.is(d, haxe.ds.ObjectMap)")
    public function issue241() {
        cfg.dictionaryToHash = true;
        generate("Issue241.as", "Issue241.hx");
        cfg.dictionaryToHash = false;
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/244")
    public function issue244() {
        generate("Issue244.as", "Issue244.hx");
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/246")
    public function issue246() {
        generate("Issue246.as", "Issue246.hx");
    }

    @Test("function(...args:*) -> function(args:Array<Dynamic> = null)")
    public function issue247() {
        generate("Issue247.as", "Issue247.hx");
    }

    @Test("new Object() -> {}")
    public function issue250() {
        generate("Issue250.as", "Issue250.hx");
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/254")
    public function issue254() {
        generate("Issue254.as", "Issue254.hx");
    }

    @Test("private const NORMAL:int = 0 -> private var NORMAL(default, never) : Int = 0")
    public function issue255() {
        generate("Issue255.as", "Issue255.hx");
    }

    @Test("navigateToURL(request, window) -> flash.Lib.getURL(request, window)")
    public function issue257() {
        generate("Issue257.as", "Issue257.hx");
    }

    @Test("Issue 261. Case 1")
    public function issue261_1() {
        generate("Issue261.as", "Issue261.hx");
    }

    @Test("Issue 261. Case 2")
    public function issue261_2() {
        generate("Issue261_1.as", "Issue261_1.hx");
    }

    @Test("Issue 261. Case 3")
    public function issue261_3() {
        generate("Issue261_2.as", "Issue261_2.hx");
    }

    @Test("v += condition ? 1 : 0")
    public function issue274() {
        generate("Issue274.as", "Issue274.hx");
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/264")
    public function issue264() {
        generate("Issue264.as", "Issue264.hx");
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/277")
    public function issue277() {
        generate("Issue277.as", "Issue277.hx");
    }

    @Test("v_numeric += condition1 || condition2 -> v_numeric = (condition1 || condition2) ? 1 : 0")
    public function issue275() {
        generate("Issue275.as", "Issue275.hx");
    }

    @Test("for(i; i < max; i++) -> whil(i < max) { ++i; }")
    public function issue285() {
        generate("Issue285.as", "Issue285.hx");
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/2")
    public function issue2() {
        generate("Issue2.as", "Issue2.hx");
    }

    @Test("var v:int = parseInt('0xffffff', 16) -> var v:Int = as3hx.Compat.parseInt('0xffffff', 16)")
    public function issue265() {
        generate("Issue265.as", "Issue265.hx");
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/273")
    public function issue273() {
        generate("Issue273.as", "Issue273.hx");
    }

    @Test("setTimeout(callback, (a + b) * 1000, args)")
    public function issue293() {
        generate("Issue293.as", "Issue293.hx");
    }

    @Test("v = 1.79e+308 -> v = 1.79e+308")
    public function issue298() {
        generate("Issue298.as", "Issue298.hx");
    }

    @Test("typeof 3 -> as3hx.Compat.typeof(3)")
    public function issue300() {
        generate("Issue300.as", "Issue300.hx");
    }

    @Test("function(i:int = 1.5)")
    public function issue302() {
        generate("Issue302.as", "Issue302.hx");
    }

    @Test("function(i:int = 1e5)")
    public function issue303() {
        generate("Issue303.as", "Issue303.hx");
    }

    @Test("this[param1].something = false")
    public function issue314() {
        generate("Issue314.as", "Issue314.hx");
    }

    @Test("https://github.com/HaxeFoundation/as3hx/issues/27")
    public function issue27() {
        generate("Issue27.as", "Issue27.hx");
    }

    @Test("for(var i = 5; i < a.length; a.pop()) -> while(i < a.length)")
    public function issue296() {
        generate("Issue296.as", "Issue296.hx");
    }

    @Test("for(var i = 0; some(i); i++) -> while(i < some(i))")
    public function issue296_1() {
        generate("Issue296_1.as", "Issue296_1.hx");
    }
    
    @Test("https://github.com/HaxeFoundation/as3hx/issues/323")
    public function issue323() {
        generate("Issue323.as", "Issue323.hx");
    }
    
    function generate(as3FileName:String, expectedHaxeFileName:String) {
        var issuesDirectory = FileSystem.absolutePath("test/issues");
        var generatedDirectoryPath = '$issuesDirectory/generated';
        if (!FileSystem.exists(generatedDirectoryPath)) FileSystem.createDirectory(generatedDirectoryPath);
        var content = File.getContent('$issuesDirectory/$as3FileName');
        var program = parser.parseString(content, issuesDirectory, '$issuesDirectory/$as3FileName');
        var fw = File.write('$generatedDirectoryPath/$expectedHaxeFileName', false);
        writer.process(program, fw);
        fw.close();
        var expectedText = File.getContent('$issuesDirectory/$expectedHaxeFileName');
        var actualText = File.getContent('$generatedDirectoryPath/$expectedHaxeFileName');
        Assert.areEqual(expectedText, actualText);
    }
}