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
    
    var cfg:as3hx.Config;
    var parser:as3hx.Parser;
    var writer:as3hx.Writer;
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
        generate("Issue14.as", "Issue14_generated.hx", "Issue14.hx");
    }
    
    @Test("array.concat() -> array.copy()")
    public function issue32() {
        generate("Issue32.as", "Issue32_generated.hx", "Issue32.hx");
    }
    
    @Test("string.charCodeAt() -> string.charCodeAt(0)")
    public function issue36() {
        generate("Issue36.as", "Issue36_generated.hx", "Issue36.hx");
    }
    
    @Test("Xml(string) -> FastXML.parse(string)")
    public function issue37() {
        generate("Issue37.as", "Issue37_generated.hx", "Issue37.hx");
    }
    
    @Test
    public function issue38() {
        generate("Issue38.as", "Issue38_generated.hx", "Issue38.hx");
    }
    
    @Test("private var name = 'value'")
    public function issue52() {
        generate("Issue52.as", "Issue52_generated.hx", "Issue52.hx");
    }
    
    @Test("array.length = 10 -> Compat.setArrayLegth(array, 10)")
    public function issue63() {
        generate("Issue63.as", "Issue63_generated.hx", "Issue63.hx");
    }
    
    @Test("array.slice() -> array.copy()")
    public function issue68() {
        generate("Issue68.as", "Issue68_generated.hx", "Issue68.hx");
    }
    
    @Test("string.charAt() -> string.charAt(0)")
    public function issue69() {
        generate("Issue69.as", "Issue69_generated.hx", "Issue69.hx");
    }
    
    @Test
    public function issue81() {
        generate("Issue81.as", "Issue81_generated.hx", "Issue81.hx");
    }
    
    @Test("JSON.parse(string) -> haxe.Json.parse(string)")
    public function issue83() {
        generate("Issue83.as", "Issue83_generated.hx", "Issue83.hx");
    }
    
    @Test("uint(1) -> as3hx.Compat.parseInt(1)")
    public function issue85() {
        generate("Issue85.as", "Issue85_generated.hx", "Issue85.hx");
    }
    
    @Test
    public function issue87() {
        generate("Issue87.as", "Issue87_generated.hx", "Issue87.hx");
    }
    
    @Test("NaN -> Math.NaN")
    public function issue89() {
        generate("Issue89.as", "Issue89_generated.hx", "Issue89.hx");
    }
    
    @Test("var b:Boolean = !int -> var b:Bool = int != 0")
    public function issue91() {
        generate("Issue91.as", "Issue91_generated.hx", "Issue91.hx");
    }
    
    function generate(as3FileName:String, generatedFileName:String, expectedFileName:String) {
        var issuesDirectory = FileSystem.absolutePath("test/issues");
        var content = File.getContent('$issuesDirectory/$as3FileName');
        var program = parser.parseString(content, issuesDirectory, '$issuesDirectory/$as3FileName');
        var fw = File.write('$issuesDirectory/$generatedFileName', false);
        writer.process(program, fw);
        fw.close();
        var expectedText = File.getContent('$issuesDirectory/$expectedFileName');
        var actualText = File.getContent('$issuesDirectory/$generatedFileName');
        Assert.areEqual(expectedText, actualText);
    }
}