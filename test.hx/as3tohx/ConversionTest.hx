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

// Additional implicit imports...
import as3tohx.AnotherClass;
import as3tohx.KeyClass;
import as3tohx.MyClass;
import as3tohx.SomeType;
import as3tohx.UInt;
import as3tohx.ValueClass;

/**
 * Most commonly failing interface use case.
 */
interface IAnotherInterface
{
    function oneMethod() : Date;
    
    // missing semi-colon in AS3 code is Valid
    function twoMethod() : Date;
    /**
      * Function comments
      */
    function fiveCommand(arg1 : String,
            arg2 : Int,
            arg3 : Float) : Void;
    
    function fourMethod() : Date;
    
    // missing semi-colon in AS3 code is Valid
    function keepCommand(arg1 : String,
            arg2 : Int,  // parameter comments  
            arg3 : Float) : Void;
}
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
    public function standaloneFunc(object : Dynamic) : Bool
    {
        #if TIVOCONFIG_COVERAGE
        {            
            trace("blah");
        }
        #end // TIVOCONFIG_COVERAGE
        
        #if TIVOCONFIG_ASSERT
        {            
            
            if (object != null){
                #if TIVOCONFIG_DEBUG_PRINT
                {                    
                    trace(object.value);
                }
                #end // TIVOCONFIG_DEBUG_PRINT
            }
            else {
                trace("blah");
            }
        }
        #end // TIVOCONFIG_ASSERT
        
        return false;
    }

    public function new()
    {
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
    function sendCommand(args : String) : Void;
}

/**
 *  This class is marked with final and
 *  should be converted to the Haxe "@:final"
 */
class @:final Main extends MyClass implements ISomeInterface
{
    public var intKeyMap(get_intKeyMap, never) : Map<Int, ValueClass>;
    public var stringKeyMap(get_stringKeyMap, never) : Map<String, ValueClass>;
    public var objectKeyMap(get_objectKeyMap, never) : Map<KeyClass, ValueClass>;
    public var mapOfArray(get_mapOfArray, never) : Map<Int, Array<AnotherClass>>;
    public var mapOfMap(get_mapOfMap, never) : Map<Int, Map<String, AnotherClass>>;
    public var sampleProperty(get_sampleProperty, set_sampleProperty) : Dynamic;

    static public var someMonths : Array<Dynamic> = ["January", "February", "March"];
    static public var someDay : Array<Dynamic> = ["January", 1, 1970, "AD"];
    
    static inline var ROLE_PRIORITY : Int = 99;
    
    var mIntKeyMap : Map<Int, ValueClass> = null;
    var mStringKeyMap : Map<String, ValueClass> = null;
    var mObjectKeyMap : Map<KeyClass, ValueClass> = null;
    var mMapOfArray : Map<Int, Array<AnotherClass>> = null;
    var mMapOfMap : Map<Int, Map<String, AnotherClass>> = null;
    
    @:final function get_intKeyMap() : Map<Int, ValueClass>
    {
        
        if (mIntKeyMap == null){
            mIntKeyMap = new Map<Int, ValueClass>();
        }return mIntKeyMap;
    }
    
    @:final function get_stringKeyMap() : Map<String, ValueClass>
    {
        
        if (mStringKeyMap == null){
            mStringKeyMap = new Map<String, ValueClass>();
        }return mStringKeyMap;
    }
    
    @:final function get_objectKeyMap() : Map<KeyClass, ValueClass>
    {
        
        if (mObjectKeyMap == null){
            mObjectKeyMap = new Map<KeyClass, ValueClass>();
        }return mObjectKeyMap;
    }
    
    @:final function get_mapOfArray() : Map<Int, Array<AnotherClass>>
    {
        
        if (mMapOfArray == null){
            mMapOfArray = new Map<Int, Array<AnotherClass>>();
        }return mMapOfArray;
    }
    
    @:final function get_mapOfMap() : Map<Int, Map<String, AnotherClass>>
    {
        
        if (mMapOfMap == null){
            mMapOfMap = new Map<Int, Map<String, AnotherClass>>();
        }return mMapOfMap;
    }
    
    var isResult1 : Bool = true;
    var isResult2 : Bool = true;
    var isResult3 : Bool = true;
    var isResult4 : Bool = true;
    
    // the line below is to test assigning a value
    // during variable declaration
    var intVal : Int = 6;
    
    var _sampleProperty : Dynamic;
    
    /**
     * GETTER & SETTER STATEMENTS
     * This section tests to make property set / get methods private
     * and make them named with set_ get_
     */
    
    function get_sampleProperty() : Dynamic
    {
        return _sampleProperty;
    }
    
    function set_sampleProperty(value : Dynamic) : Dynamic
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
        funcC(paramA,  // comment on paramA  
                paramB,  /* comment describing paramB */  
                paramC,
                paramD);  // one more comment  
        
        
        /**
         * Function call: Parameters across different
         * lines, with comments interspersed and
         * white space
         */
        retValue = funcD(paramA,  // comment on paramA  
                        paramB, paramC,  /* comment describing paramB */  
                        paramD);
        
        
        /**
         * Function call: Parameters across different
         * lines with concatenation of parameters across
         * multiple lines, comments interspersed, and
         * white space to preserve
         */
        retValue = funcE(valueA + valueB + valueC +  // comment on paramA, B, C  
                        valueD + valueE + valueF,  // comment on paramD, E, F  
                        paramA, paramB,  /* comment */  paramC,  /* comment describing paramC */  
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
        }  /**
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
            else 
            if (isResult4)
            {
                // Testing that "hasAnyProperties(map)" is
                // replaced with "map.keys().hasNext()"
                value = map.keys().hasNext();
            }
        }
        /* comment line */
        else 
        
        if (isResult3)  // coment at the end of the line  
        {
            // one nested if
            
            
            if (!isResult1)
                trace("trace line");
        }  /**
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
            case funcT(param):  // comment explaining function  
            {
                // The if statement below tests that
                // 'if (obj)' is converted into 'if (obj != null)'
                
                var obj : Dynamic = { };
                
                
                if (obj != null)
                {
                    trace("trace line");
                }value = 2;
            }
            
            /*
             Another comment line
             which usually disappear when
             the break is removed and leaves
             the dangling semicolon
             */
            case 1:
            {
                value = 1;  /* comment line1
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
        }return true;
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
    public @:final function testPublicMethod3(var1 : Bool,  // comment line 1  
            var2 : String,var3 : UInt,  /* comment line 2 */  
            func4 : Dynamic,var5 : Array<Dynamic>) : Bool  // comment line 3  
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
    public function sendCommand(args : String,anObj : Dynamic) : Void
    {
        var nowTheTimeIs : Date = Date.now();
        
        var Array : Array<SomeType> = new Array<SomeType>();
        
        var strTest : String = "Hello World is Just a String";
        
        var x : String = StringTools.trim(strTest.substr(9));
        
        var y : String = ((anObj != null)) ? anObj.toString() : "";
        
        var f : Float = 0.0;
        
        
        if (Std.is(anObj, SomeType)){
            f = (try cast(anObj, SomeType) catch(e:Dynamic) null).specialMethod();
        }
        
        var i : Int = 0;
        while (i < Array.length){
            // some code here
            trace(Array[i]);i++;
        }
        
        if (
        (
        mBoolVar1 &&
        mBoolVar2 && !mBoolVar3) ||
        
        (
        anObj &&
        mBoolVar3 && !mBoolVar3) ||
        
        (
        mBoolVar1 &&
        mBoolVar2 &&
        mBoolVar3 && mBoolVar4))
        {
            // some code here
            dispatchMessageLoadedSignal();
        }
        
        for (obj/* AS3HX WARNING could not determine type for var: obj exp: EIdent(array) type: null */ in Array){
            trace(obj.specialMethod());
        }var multiLineStringConstruction : String = 
        "This kind of String construction is failing to convert: " +
        strTest.substr(9) + ". ";
        
        // this kind of method calling (or construtor calling) is also failing to convert
        someClass.someStaticMethod(param1,
                param2 +  // this comment should not break conversion  
                value22,  // so does this  
                param3  // or this :) (should not choke on these parantheses)  
                );
        
        var flag : Bool = (Lambda.indexOf(someMonths, "June") != -1);  // indexOf not supported by Haxe array, but Lambda does  
        // when converted, this should insert "using Lambda"
        
        return;
    }
    
    /**
     * Conditionally compiled code with comments
     */
    #if TIVOCONFIG_ASSERT
    public function someFunctionToTestTiVoConfig() : Void
    {
        return;
    }
    #end // TIVOCONFIG_ASSERT
    
    // below are unit tests' methods with annotations
    
    @Test("this will test prime number function")
    public function testPrime(val : Int) : Bool
    {
        return true;
    }
    
    @AsyncTest("Test for missing golden")
    public function testWhole(val : Int) : Bool
    {
        return true;
    }
    
    @DataProvider("trueAndFalse")
    @Test
    public function testBooleanValues(val : Bool) : Bool
    {
        return true;
    }
    
    @Ignore("Memory leak detection is not deterministic")
    @DataProvider("memoryMap")
    @Test
    public function testBooleanValues(val : Bool) : Bool
    {
        return true;
    }
    
    @:meta(Before(order=-1))
    public function firstMostBefore() : Void
    {
        return;
    }
    
    @Before
    public function unorderedBefore() : Void
    {
        return;
    }
    
    @After
    public function tearDown() : Void
    {
        return;
    }
    
    @BeforeClass
    public function preConstruction() : Void
    {
        return;
    }
    
    @AfterClass
    public function onDestroy() : Void
    {
        return;
    }

    public function new()
    {
        super();
    }
}

