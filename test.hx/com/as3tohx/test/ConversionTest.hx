/*
 * Example Copyright Header. All Rights Reserved.
 */
 ////////////////////////////////////////////////////////////////////////////////
 //
 // Example Header different style
 //
 ////////////////////////////////////////////////////////////////////////////////
/**
 * Below are examples of differently formatted
 * function calls, function definitions, else/if, and switch statements
 * with comments inbetween code lines and empty lines.
 * This file was created to test that as3tohx correctly maintains
 * white space, comments, function parameters, and value concatenation
 * across mutiple lines
 *
 * Please refer to "conversionTest_golden.hx" as the golden file.
 */
package com.as3tohx.test;

// Additional implicit imports...
import com.as3tohx.test.MyClass;
import com.as3tohx.test.UInt;

/**
     *  This class is marked with final and
     *  should be converted to the Haxe "@:final"
     */
@:final class Main extends MyClass
{
	public var sampleProperty(getSampleProperty, setSampleProperty) : Dynamic;

	var isResult1 : Bool;
	var isResult2 : Bool;
	var isResult3 : Bool;
	var isResult4 : Bool;
	 // the line below is to test assigning a value
	 // during variable declaration
	var intVal : Int;
	var _sampleProperty : Dynamic;
	/**
         * GETTER & SETTER STATEMENTS
         * This section tests to make property set / get methods private
         * and make them named with set_ get_
         */
	public function getSampleProperty() : Dynamic
	{
		return _sampleProperty;
	}

	public function setSampleProperty(value : Dynamic) : Dynamic
	{
		_sampleProperty = value;
		return value;
	}

	public function testPublicMethod() : Void
	{
		/**
             * FUNCTION CALLS
             *
             * Below are 6 different versions of
             * function call formats with
             * comments inbetween
             */
		/**
             * Function call: Simple function call
             * with all parameters on the same
             * line no comments
             *
             * @param paramA    dummy parameter A
             * @param paramB    dummy parameter B
             * @param paramC    dummy parameter C
             * @param paramD    dummy parameter D
             */
		funcA(paramA, paramB, paramC, paramD);
		 //
		 // Function call: Each parameter on a
		 // seperate line with no comments but
		 // with white space
		 //
		funcB(paramA, paramB, paramC, paramD);
		/**
             * Function call: Each parameter on a
             * seperate line with comments and
             * white space to preserve
             */
		funcC(paramA,  // comment on paramA
		paramB, /* comment describing paramB */
		paramC, paramD);
		 // one more comment
		/**
             * Function call: Parameters across different
             * lines, with comments interspersed and
             * white space
             */
		retValue = funcD(paramA,  // comment on paramA
		paramB, paramC, /* comment describing paramB */
		paramD);
		/**
             * Function call: Parameters across different
             * lines with concatenation of parameters across
             * multiple lines, comments interspersed, and
             * white space to preserve
             */
		retValue = funcE(valueA + valueB + valueC +  // comment on paramA, B, C
		valueD + valueE + valueF,  // comment on paramD, E, F
		paramA, paramB, /* comment */
		paramC, /* comment describing paramC */
		 // last comment
		paramD);
		/**
             * IF / ELSE IF STATEMENTS
             * Below are 2 different versions of
             * "if else if" formats with
             * comments inbetween
             */
		/**
             * If statement:
             * simple if different style
             */
		if (isResult1) 
			 // simple if with comments
		
		{
			isResult1 = true;
		}
;
		/**
             * if statement:
             * series of else if statements with comments
             */
		if (isResult1) 
		{
			 // comment within if
			isResult1 = true;
		}
		else  // comment line
		if (isResult2) 
		{
			trace("trace line");
			 // Testing nested else/if statements
			if (isResult3) 
			{
				 // Testing that "map.hasOwnProperty(xxx)" is
				 // replaced with "map.exists(xxx)"
				value = map.hasOwnProperty(myClass);
			}
			else if (isResult4) 
			{
				 // Testing that "hasAnyProperties(map)" is
				 // replaced with "map.keys().hasNext()"
				value = hasAnyProperties(map);
			}
;
		}
		else /* comment line */
		if (isResult3) 
			 // coment at the end of the line
		
		{
			 // one nested if
			if (!isResult1) 
				trace("trace line");
		}
;
		/**
             * SWITCH STATEMENT
             * Below is a switch with some comment variations
             * interspersed inbetween cases and white space
             */
		var value : Int;
		switch (param)
		{
			case 0:
				
				{
					value = 1;
				}
			case funcT(param):
				 // comment explaining function
				
				{
					 // The if statement below tests that
					 // 'if (obj)' is converted into 'if (obj != null)'
					if (obj) 
					{
						trace("trace line");
					}
;
					value = 2;
				}
;
			case 1:
				
				{
					value = 1;
					/* comment line1
                                   comment line2
                                   comment line3 */
					value = 2;
					/*
                    // the lines below tests if the converter
                    // can correctly handle concatenated values
                    // on seperate lines
                    // The converter needs to preserve line breaks
                    */
					value = "string part1" + "string part2" + "string part3" + "string part4";
				}
			default:
				value = 0;
		}
		return true;
	}

	/**
        * FUNCTION DEFINITION FORMATS
        * Below are two function definitions
        * with parameters on different lines
        * and comment interspersed
        *
        * Parameters are placed on different lines
        * with comments and white space to preserve
        * Also this function is marked as "final" and
        * should be converted to the Haxe "@:final"
        */
	@:final public function testPublicMethod3(var1 : Bool, var2 : String, var3 : UInt, func4 : Function, var5 : Array<Dynamic>) : Bool
	{
		return true;
	}

	/**
        * All function arguments are on individual lines
        * with comments inbetween
        */
	public function testPublicMethod5(var1 : Bool, var2 : String, var3 : UInt, func4 : Function, var5 : Array<Dynamic>) : Bool
	{
		return true;
	}

	public function new()
	{
		super();
	}


	public function new()
	{
		isResult1 = true;
		isResult2 = true;
		isResult3 = true;
		isResult4 = true;
		intVal = 6;
		super();
	}
}

