package as3hx;
import as3hx.Config;
import as3hx.Error;
import as3hx.Parser;
import as3hx.Writer;
import haxe.io.BytesOutput;
import massive.munit.Assert;
import massive.sys.io.File;

/**
 * @author SlavaRa
 */
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
        var file = File.current.resolveFile("test/issues/Issue32.as");
        var content = file.readString();
        var program = parser.parseString(content, file.path.dir, file.path.file);
        var resultFileName = "test/issues/Issue32_generated.hx";
        var fw = sys.io.File.write(resultFileName, false);
        writer.process(program, fw);
        fw.close();
        var expectedText = File.current.resolveFile("test/issues/Issue32.hx").readString();
        var actualText = File.current.resolveFile(resultFileName).readString();
        Assert.areEqual(expectedText, actualText);
    }
}