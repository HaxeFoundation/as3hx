package as3hx;
import as3hx.Config;
import as3hx.Error;
import as3hx.Parser;
import as3hx.Writer;
import haxe.io.BytesOutput;
import massive.munit.Assert;
import massive.sys.io.File;

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
    public function issue32() {
        generate("Issue32.as", "Issue32_generated.hx", "Issue32.hx");
    }
    
    function generate(as3FileName:String, generatedFileName:String, expectedFileName:String) {
        var issuesDirectory = "test/issues";
        var as3File = File.current.resolveFile('$issuesDirectory/$as3FileName');
        var program = parser.parseString(as3File.readString(), as3File.path.dir, as3File.path.file);
        var fw = sys.io.File.write('$issuesDirectory/$generatedFileName', false);
        writer.process(program, fw);
        fw.close();
        var expectedText = File.current.resolveFile('$issuesDirectory/$expectedFileName').readString();
        var actualText = File.current.resolveFile('$issuesDirectory/$generatedFileName').readString();
        Assert.areEqual(expectedText, actualText);
    }
}