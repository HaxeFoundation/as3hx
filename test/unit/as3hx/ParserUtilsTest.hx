package as3hx;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

import as3hx.Tokenizer;
import as3hx.As3;
import as3hx.ParserUtils;

class ParserUtilsTest 
{
    public function new() 
    {

    }

    @Test
    public function testExplodeComment():Void
    {
        Assert.isTrue(ParserUtils.explodeComment(null).length == 0);
        Assert.areEqual(ParserUtils.explodeComment(TEof)[0], TEof);
        Assert.isTrue(ParserUtils.explodeComment(TEof).length == 1);
        Assert.areEqual(ParserUtils.explodeComment(TCommented('', false, TEof))[0],
                [TCommented('', false, null), TEof][0]);
        Assert.areEqual(ParserUtils.explodeComment(TCommented('', false, TEof))[1],
                [TCommented('', false, null), TEof][1]);
    }

    @Test
    public function testUncomment():Void
    {
        Assert.isNull(ParserUtils.uncomment(null));
        Assert.areEqual(ParserUtils.uncomment(TEof), TEof);
        Assert.areEqual(ParserUtils.uncomment(
                    TCommented('', false, TEof)), TEof);
    }

    @Test
    public function testUncommentExpr():Void
    {
        Assert.isNull(ParserUtils.uncommentExpr(null));
        Assert.areEqual(ParserUtils.uncommentExpr(EContinue), EContinue);
        Assert.areEqual(ParserUtils.uncommentExpr(
                    ECommented('', false, false, EContinue)),
                EContinue);
    }

    @Test
    public function testExplodeCommentExpr():Void
    {
        Assert.isTrue(ParserUtils.explodeCommentExpr(null).length == 0);
        Assert.areEqual(ParserUtils.explodeCommentExpr(EContinue)[0],
                [EContinue][0]);
        Assert.areEqual(ParserUtils.explodeCommentExpr(ECommented('', false, false, EContinue))[0],
                [ECommented('', false, false, null), EContinue][0]);
        Assert.areEqual(ParserUtils.explodeCommentExpr(ECommented('', false, false, EContinue))[1],
                [ECommented('', false, false, null), EContinue][1]);
    }

    @Test
    public function testTailComment():Void
    {
        Assert.areEqual(ParserUtils.tailComment(EContinue, TEof), 
                EContinue);
        Assert.areEqual(ParserUtils.tailComment(
                    EContinue, TCommented('', false, TEof)),
                ECommented('', false, true, EContinue));
    }

    @Test
    public function testMakeECommented():Void
    {
        Assert.areEqual(ParserUtils.makeECommented(TCommented('', false, TEof), EContinue), 
                ECommented('', false, false, EContinue));
        Assert.areEqual(ParserUtils.makeECommented(
                    TCommented('', false, TCommented('', false, TEof)), EContinue), 
                ECommented('', false, false, ECommented('', false, false, EContinue)));
    }

    @Test
    public function testRemoveNewLine():Void
    {
        Assert.areEqual(ParserUtils.removeNewLine(TEof), TEof);
        Assert.areEqual(ParserUtils.removeNewLine(TNL(TEof)), TEof);
        Assert.areEqual(ParserUtils.removeNewLine(TCommented('', false, TEof)), TEof);
        Assert.areEqual(ParserUtils.removeNewLine(TCommented('', false, TEof), false), TCommented('', false, TEof));
    }

    @Test
    public function testRemoveNewLineExpr():Void
    {
        Assert.areEqual(ParserUtils.removeNewLineExpr(EContinue), EContinue);
        Assert.areEqual(ParserUtils.removeNewLineExpr(ENL(EContinue)), EContinue);
        Assert.areEqual(ParserUtils.removeNewLineExpr(ECommented('', false, false, EContinue)), EContinue);
        Assert.areEqual(ParserUtils.removeNewLineExpr(ECommented('', false, false, EContinue), false), ECommented('', false, false, EContinue));
    }

    @Test
    @Ignore
    public function testOpt():Void
    {

    }

    @Test
    @Ignore
    public function testOpt2():Void
    {

    }

    @Test
    public function testMakeUnop():Void
    {
        Assert.areEqual(ParserUtils.makeUnop('+', EContinue), EUnop('+', true, EContinue));
        Assert.areEqual(ParserUtils.makeUnop('+', EBinop('+', EContinue, EContinue, false)), 
                EBinop('+', EUnop('+', true, EContinue), EContinue, false));
    }

    @Test
    @Ignore
    public function testMakeBinop():Void
    {

    }
}
