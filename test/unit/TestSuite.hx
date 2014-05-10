import massive.munit.TestSuite;

import ParserUtilsTest;
import ExampleTest;
import TokenizerTest;

/**
 * Auto generated Test Suite for MassiveUnit.
 * Refer to munit command line tool for more information (haxelib run munit)
 */

class TestSuite extends massive.munit.TestSuite
{		

	public function new()
	{
		super();

		add(ParserUtilsTest);
		add(ExampleTest);
		add(TokenizerTest);
	}
}
