package as3hx;

import massive.munit.Assert;
import as3hx.Tokenizer;

class TokenizerTest
{
    public function new()
    {

    }

    @Test
    public function testToken()
    {
        assertTokens('Hello', [TId('Hello'), TEof]);
    }

    function assertTokens(input:String, tokens:Array<Token>)
    {
        var tokenizer = new Tokenizer(new haxe.io.StringInput(input));
        var token = null;
        while (token != TEof)
        {
            token = tokenizer.token();
            Assert.areEqual(token, tokens.shift());
        }
    }

    @Test
    public function testId()
    {
        var tokenizer = new Tokenizer(new haxe.io.StringInput('Hello'));
        Assert.areEqual(tokenizer.id(), 'Hello');
    }

    @Test
    public function testPeek()
    {
        var tokenizer = new Tokenizer(new haxe.io.StringInput('Hello'));
        Assert.areEqual(tokenizer.peek(), TId('Hello'));
    }

    @Test
    public function testAdd()
    {
        var tokenizer = new Tokenizer(new haxe.io.StringInput(''));
        tokenizer.add(TId('world'));
        Assert.areEqual(tokenizer.token(), TId('world'));
    }

    @Test
    public function testEnsure()
    {
        var tokenizer = new Tokenizer(new haxe.io.StringInput('Hello'));
        try {
            tokenizer.ensure(TId('Hello'));
        }
        catch (e:Dynamic) {
            Assert.fail('not the expected token');
        }
    }
}
