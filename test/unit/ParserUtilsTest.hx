package;

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

    }
}
