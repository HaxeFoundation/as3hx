package as3hx.parsers;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;


class ImportParserTest 
{
	
	
	public function new() 
	{
	}
	
	
	@Test
	public function testCustomClass():Void
	{
		var importParts = getImportParts('import com.test.myapp.MyClass;');
		Assert.areEqual(importParts.length, 4);
		Assert.areEqual(importParts[0], 'com');
		Assert.areEqual(importParts[1], 'test');
		Assert.areEqual(importParts[2], 'myapp');
		Assert.areEqual(importParts[3], 'MyClass');
	}
	
	@Test
	public function testNoPackage():Void
	{
		var importParts = getImportParts('import MyClass;');
		Assert.areEqual(importParts.length, 1);
		Assert.areEqual(importParts[0], 'MyClass');
	}
	
	@Test
	public function testSprite():Void
	{
		var importParts = getImportParts('import flash.display.Sprite;');
		Assert.areEqual(importParts.length, 3);
		Assert.areEqual(importParts[0], 'flash');
		Assert.areEqual(importParts[1], 'display');
		Assert.areEqual(importParts[2], 'Sprite');
	}
	
	@Test
	public function testDictionary():Void
	{
		var importParts = getImportParts('import flash.utils.Dictionary;');
		Assert.areEqual(importParts.length, 3);
		Assert.areEqual(importParts[0], 'flash');
		Assert.areEqual(importParts[1], 'utils');
		Assert.areEqual(importParts[2], 'Dictionary');
	}
	
	@Test
	public function testGetQualifiedClassName():Void
	{
		var importParts = getImportParts('import flash.utils.getQualifiedClassName;');
		Assert.areEqual(importParts.length, 0);
	}
	
	@Test
	public function testSetTimeout():Void
	{
		var importParts = getImportParts('import flash.utils.setTimeout;');
		Assert.areEqual(importParts.length, 0);
	}
	
	@Test
	public function testClearTimeout():Void
	{
		var importParts = getImportParts('import flash.utils.clearTimeout;');
		Assert.areEqual(importParts.length, 0);
	}
	
	@Test
	public function testSetInterval():Void
	{
		var importParts = getImportParts('import flash.utils.setInterval;');
		Assert.areEqual(importParts.length, 0);
	}
	
	@Test
	public function testClearInterval():Void
	{
		var importParts = getImportParts('import flash.utils.clearInterval;');
		Assert.areEqual(importParts.length, 0);
	}
	
	@Test
	public function testWildcard():Void
	{
		var importParts = getImportParts('import com.test.myapp.*;');
		Assert.areEqual(importParts.length, 4);
		Assert.areEqual(importParts[0], 'com');
		Assert.areEqual(importParts[1], 'test');
		Assert.areEqual(importParts[2], 'myapp');
		Assert.areEqual(importParts[3], '*');
	}
	
	@Test
	@Ignore
	public function testWildcardNoPackage():Void
	{
		// Not sure if this test should be included. Is "import *" valid AS3?
		var importParts = getImportParts('import *;');
		Assert.areEqual(importParts.length, 1);
		Assert.areEqual(importParts[0], '*');
	}
	
	function getImportParts(importString:String):Array<Dynamic> 
	{
		var tokenizer = new Tokenizer(new haxe.io.StringInput(importString));
		Assert.areEqual(tokenizer.id(), 'import');
		var cfg = new as3hx.Config();
		var importParts = ImportParser.parse(tokenizer, cfg);
		return importParts;
	}
	
}