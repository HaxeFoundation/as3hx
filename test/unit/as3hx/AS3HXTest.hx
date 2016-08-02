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
    public function issue32() {
        generate("Issue32.as", "Issue32_generated.hx", "Issue32.hx");
    }
    
    @Test
    public function issue82() {
        generate("Issue82.as", "Issue82_generated.hx", "Issue82.hx");
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