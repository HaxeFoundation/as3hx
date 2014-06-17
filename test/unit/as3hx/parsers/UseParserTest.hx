package as3hx.parsers;

import as3hx.parsers.UseParser;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;


class UseParserTest 
{
	
	
	public function new() 
	{
	}
	
	@Test
	@Ignore
	public function testUse():Void
	{
		var tokenizer = new Tokenizer(new haxe.io.StringInput('use namespace mx_internal;'));
		Assert.areEqual(tokenizer.id(), 'use');
		UseParser.parse(tokenizer);
		Assert.areEqual(tokenizer.id(), 'mx_internal'); // This test hangs here for some reason. Could be because UseParser.parse ends the tokenizer.
	}
}