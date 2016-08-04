package as3hx.parsers;

import as3hx.As3.Expr;
import as3hx.Config;
import haxe.io.StringInput;
import massive.munit.Assert;

class ExprParserTest
{
    public function new() {}
    
    @Test
    public function testParseBinop()
    {
        var actual = parse("a > b");
        Assert.areEqual(EBinop(">",EIdent("a"),EIdent("b"),false), actual);
    }
    
    @Test
    public function testParseTernary()
    {
        var actual = parse("a ? 1 : 0");
        Assert.areEqual(ETernary(EIdent("a"),EConst(CInt("1")),EConst(CInt("0"))), actual);
    }
    
    @Test
    public function testParseTernary_1()
    {
        var actual = parse("(a > b) ? 1 : 0");
        Assert.areEqual(ETernary(EParent(EBinop(">",EIdent("a"),EIdent("b"),false)),EConst(CInt("1")),EConst(CInt("0"))), actual);
    }
    
    @Test
    public function testParseTernary_2()
    {
        var actual = parse("a > b ? 1 : 0");
        Assert.areEqual(ETernary(EBinop(">",EIdent("a"),EIdent("b"),false),EConst(CInt("1")),EConst(CInt("0"))), actual);
    }
    
    @Test
    public function testParseTernary_3()
    {
        var actual = parse("a && b && c ? 1 : 0");
        Assert.areEqual(ETernary(EBinop("&&",EBinop("&&",EIdent("a"),EIdent("b"),false),EIdent("c"),false),EConst(CInt("1")),EConst(CInt("0"))), actual);
    }
    
    @Test
    public function testParseBinop_is()
    {
        var actual = parse("s is String");
        Assert.areEqual(EBinop("is",EIdent("s"),EIdent("String"),false), actual);
    }
    
    @Test
    public function testParseTernary_4()
    {
        var actual = parse("s is String ? 1 : 0");
        Assert.areEqual(ETernary(EBinop("is",EIdent("s"),EIdent("String"),false),EConst(CInt("1")),EConst(CInt("0"))), actual);
    }
    
    function parse(s:String):Expr
    {
        var cfg = new Config();
        var tokenizer = new Tokenizer(new StringInput(s));
        return ExprParser.parse(tokenizer, {seen:[], defd:[], gen:[]}, cfg, false);
    }
}