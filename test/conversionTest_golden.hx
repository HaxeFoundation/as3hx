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

package as3tohx;

import as3tohx.MyClass;
import as3tohx.UInt;

/**
 * Class for standaloneFunc
 */
class @:final ClassForStandaloneFunc
{
    /**
     * Standalone function at package level with no class.
     * 
     * @return always false
     */
    public function standaloneFunc(object:Dynamic):Boolean
    {
        #if TIVOCONFIG_COVERAGE
        {
            trace("blah");
        }
        #end // TIVOCONFIG_COVERAGE

        #if TIVOCONFIG_ASSERT 
        {
            if (object != null)
            {
                #if TIVOCONFIG_DEBUG_PRINT 
                {
                    trace(object.value);
                }
                #end // TIVOCONFIG_DEBUG_PRINT
            }
            else
            {
                trace("blah");
            }
        }
        #end // TIVOCONFIG_ASSERT

        return false;
    }
}

/**
 * This interface is implemented by classes that want to receive
 * ICE commands. 
 */
interface ISomeInterface
{
    /**
     * Send a command to the ICE server.
     */
    function sendCommand(args:String):Void;
}

/**
 *  This class is marked with final and
 *  should be converted to the Haxe "@:final"
 */
class @:final Main extends MyClass implements ISomeInterface
{
    static public var someMonths : Array<Dynamic>= [ "January", "February", "March" ];
    static public var someDay : Array<Dynamic>= [ "January", 1, 1970, "AD" ]; 

    var mIntKeyMap : Map<Int, ValueClass>;
    var mStringKeyMap : Map<String, ValueClass>;
    var mObjectKeyMap : Map<KeyClass, ValueClass>;
    var mMapOfArray : Map<Int, Array<AnotherClass>>;
    var mMapOfMap : Map<Int, Map<String, AnotherClass>>;

    public var intKeyMap (get_intKeyMap, never) : Map<Int, ValueClass>;
    public var stringKeyMap (get_stringKeyMap, never) : Map<String, ValueClass>;
    public var objectKeyMap (get_objectKeyMap, never) : Map<KeyClass, ValueClass>;
    public var mapOfArray (get_mapOfArray, never) : Map<Int, Array<AnotherClass>>;
    public var mapOfMap (get_mapOfMap, never) : Map<Int, Map<String, AnotherClass>>;

    public function get_intKeyMap() : Map<Int, ValueClass>
    {
       if (mIntKeyMap == null) 
       {
          mIntKeyMap = new Map<Int, ValueClass>();
       }
       return mIntKeyMap;
    }

    public function get_stringKeyMap() : Map<String, ValueClass>
    {
       if (mStringKeyMap == null) 
       {
          mStringKeyMap = new Map<String, ValueClass>();
       }
       return mStringKeyMap;
    }

    public function get_objectKeyMap() : Map<KeyClass, ValueClass>
    {
       if (mObjectKeyMap == null) 
       {
          mObjectKeyMap = Map<KeyClass, ValueClass>();
       }
      
       return mObjectKeyMap;
    }

    public function get_mapOfArray() : Map<Int, Array<AnotherClass>>
    {
       if (mMapOfArray == null) 
       {
          mMapOfArray = new Map<Int, Array<AnotherClass>>();
       }
       return mMapOfArray;
    }

    public function get_mapOfMap() : Map<Map<AnotherClass>>
    {
       if (mMapOfMap == null) 
       {
          mMapOfMap = new Map<Int, Map<String, AnotherClass>>();
       }
       return mMapOfMap;
    }

    public var sampleProperty(get_sampleProperty, set_sampleProperty) : Dynamic;

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

    public function get_sampleProperty() : Dynamic
    {
        return _sampleProperty;
    }

    public function set_sampleProperty(value : Dynamic) : Dynamic
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
        funcB(paramA,
                paramB,
                paramC,
                paramD);

        /**
         * Function call: Each parameter on a
         * seperate line with comments and
         * white space to preserve
         */
        funcC(paramA,    // comment on paramA
                paramB,    /* comment describing paramB */
                paramC,
                paramD);   // one more comment


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
                paramA, paramB, /* comment */ paramC, /* comment describing paramC */
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


        /**
         * if statement:
         * series of else if statements with comments
         */
        if (isResult1) 
        {
            // comment within if
            isResult1 = true;
        }
        // comment line
        else if (isResult2) 
        {
            trace("trace line");

            // Testing nested else/if statements

            if (isResult3) 
            {
                // Testing that "map.hasOwnProperty(xxx)" is
                // replaced with "map.exists(xxx)"
                value = map.exists(myClass);
            }
            else if (isResult4) 
            {
                // Testing that "hasAnyProperties(map)" is
                // replaced with "map.keys().hasNext()"
                value = map.keys().hasNext();
            }
        }
        /* comment line */
        else if (isResult3) // coment at the end of the line
        {
            // one nested if
            if (!isResult1) 
                trace("trace line");
        }

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
            // comment line
            case funcT(param):     // comment explaining function
            {
                // The if statement below tests that
                // 'if (obj)' is converted into 'if (obj != null)'

                var obj : Dynamic = {};
                if (obj != null) 
                {
                    trace("trace line");
                }

                value = 2;
            }

            /*
             Another comment line
             which usually disappear when
             the break is removed and leaves
             the dangling semicolon
             */
            case 1:
            {
                value = 1;   /* comment line1
                                comment line2
                                comment line3 */
                value = 2;
                /*
                // the lines below tests if the converter
                // can correctly handle concatenated values
                // on seperate lines
                // The converter needs to preserve line breaks
                */

                value = "string part1" + "string part2" +
                        "string part3" + "string part4";
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
    public @:final function testPublicMethod3(var1 : Bool, // comment line 1
            var2 : String, var3 : UInt, /* comment line 2 */
            func4 : Dynamic, var5 : Array<Dynamic>) : Bool // comment line 3
    {
        return true;
    }

    /**
     * All function arguments are on individual lines
     * with comments inbetween
     */
    public function testPublicMethod5(var1 : Bool,
            var2 : String,
            // comment line here
            var3 : UInt,
            /* comment line there before 2 white space line above*/
            func4 : Dynamic,
            /* comment line there before white space*/
            var5 : Array<Dynamic>) : Bool
    {
        return true;
    }

    /**
     * This is how we receive a command from the ICE Server.
     */
    public function sendCommand(args: String):Void
    {
        return; 
    }

    /**
     * Conditionally compiled code with comments
     */
    #if TIVOCONFIG_ASSERT
    public function someFunctionToTestTiVoConfig():Void
    {
        return; 
    }
    #end // TIVOCONFIG_ASSERT

    // below are unit tests' methods with annotations
    
    @Test("this will test prime number function")
    public function testPrime(val:Int):Bool
    {
        return true;
    }

    @AsyncTest("Test for missing golden")
    public function testWhole(val:Int):Bool
    {
        return true;
    }

    @DataProvider("trueAndFalse")
    @Test
    public function testBooleanValues(val:Bool):Bool
    {
        return true;
    }

    @Ignore("Memory leak detection is not deterministic")
    @DataProvider("memoryMap")
    @Test
    public function testBooleanValues(val:Bool):Bool
    {
        return true;
    }

    @:meta(Before(order=-1))
    public function firstMostBefore():Void
    {
        return;
    }

    @Before
    public function unorderedBefore():Void
    {
        return;
    }

    @After
    public function tearDown():Void
    {
        return;
    }

    @BeforeClass
    public function preConstruction():Void
    {
        return;
    }

    @AfterClass
    public function onDestroy():Void
    {
        return;
    }

    public function new()
    {
        intKeyMap = null;
        stringKeyMap = null;
        objectKeyMap = null;
        mapOfArray = null;
        mapOfMap = null;
        isResult1 = true;
        isResult2 = true;
        isResult3 = true;
        isResult4 = true;
        intVal = 6;
        super();
    }
}

