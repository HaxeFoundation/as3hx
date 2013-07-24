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

using Lambda;

// typedef declarations

typedef VideoProviderInfoItemsTypedef = {
    var name                : String; 
    var imageUrl            : String; 
    var partnerId           : String; 
    var uiDestinationId     : String;  
}

typedef DestinationItemsTypedef = {
    var name                : String; 
    var uiDestinationId     : String;  
    var uri                 : String; 
}

typedef CollectionTypedef = {
    var id                : String; 
    var title             : String; 
    var type              : Dynamic; 
    var imageType         : Dynamic;  
    var imageUrl          : String;  
    var height            : Int;  
    var width             : Int;  
}

typedef ContentTypedef = {
    var id                : String; 
    var title             : String; 
    var match             : Dynamic; 
    var includeInSearch   : Bool;  
} 

typedef OfferTypedef = {
    var id                : String; 
    var contentId         : String; 
    var transportType     : Dynamic; 
    var channelCallSign   : String;  
    var channelId         : String;  
    var channelNumber     : Int;  
    var title             : String;  
} 

typedef PersonTypedef = {
    var id                : String; 
    var first             : String; 
    var last              : String;  
}


/**
 * Most commonly failing interface use case.
 */
interface ISomeInterface
{
    function oneMethod():Date; 

    // missing semi-colon in AS3 code is Valid
    function twoMethod():Date; 

    /**
     * Function comments
     */
    function fiveCommand(arg1:String,
                         arg2:Int,
                         arg3:Float):Void; 

    function fourMethod():Date;

    // missing semi-colon in AS3 code is Valid
    function keepCommand(arg1:String,
                         arg2:Int,    // parameter comments 
                         arg3:Float):Void; 
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
    public function standaloneFunc(object:Dynamic):Bool
    {
        #if TIVOCONFIG_COVERAGE
            trace("blah");
        #end // TIVOCONFIG_COVERAGE

        // another way of using TIVOCONFIG 
        #if TIVOCONFIG_UNSAFE_PRIVACY
            trace("roar");
        #end // TIVOCONFIG_UNSAFE_PRIVACY

        #if TIVOCONFIG_ASSERT 
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

    // apparently, if there is an extra comma (,) after the last value in an array/vector
    // declaration (or creating when passing as a param to function) is allowed in AS3
    // there were several places such as these in code hence, need to handle it.
    static public var someDay : Array<Dynamic>= [ "January", 1, 1970, "AD" ]; 

    //---------- this is the most commonly occurring type of data declarations that we missed -
    //---------- yes, we are done :)

    static var VIDEO_PROVIDER_INFO_ITEMS : Array<VideoProviderInfoItemsTypedef> = [
           {
             name : "Amazon",
             imageUrl : "images/providers/Source_Amazon_icon_sm.png",
             partnerId : "Amazon-Id",
             uiDestinationId : "Amazon-Des-Id",
           },
           {
             name : "Netflix",
             imageUrl : "images/providers/Source_Netflix_icon_sm.png",
             partnerId : "Netflix-Id",
             uiDestinationId : "Netflix-Des-Id",
           }
    ];

    // --- more examples --- I know this is too many examples... you don't have to code for all these
    // just code for the one above ... these are just additional test data for validation :)

    // here is another example of the above type
    static var DESTINATION_ITEMS : Array<DestinationItemsTypedef> = [
           {
             name : "amazon",
             uiDestinationId : "Amazon-Des-Id",
             uri : "Amazon-transition-uri",
           },
           {
             name : "netflix",
             uiDestinationId : "Netflix-Des-Id",
             uri : "Netflix-transition-uri",
           }
    ];

    static var COLLECTION : Array<CollectionTypedef> = [
           {
             id : "1",
             title : "Collection1",
             type : CollectionType.SERIES,
             imageType : ImageType.TV_SHOW_SERIES_LOGO,
             imageUrl : "images/discovery/flyout6.jpg",
             height : 150,
             width : 200,
           },
           {
             id : "2",
             title : "Collection2",
             type : CollectionType.SERIES,
             imageType : ImageType.TV_SHOW_SERIES_LOGO,
             imageUrl : "images/discovery/flyout7.jpg",
             height : 150,
             width : 200,
           }
    ];

    static var CONTENT : Array<ContentTypedef> = [
           {
             id : "1",
             title : "Content1",
             match : MatchedField.TITLE,
             includeInSearch : true,
           },
           {
             id : "2",
             title : "Content2",
             match : MatchedField.TITLE,
             includeInSearch : true,
           }
    ];

    static var OFFER : Array<OfferTypedef> = [
           {
             id : "1",
             contentId : "1",
             transportType : OfferTransportType.STREAM,
             channelCallSign : "CBS",
             channelId : "5",
             channelNumber : 5,
             title : "Some title",
           },
           {
             id : "2",
             contentId : "2",
             transportType : OfferTransportType.STREAM,
             channelCallSign : "CBS",
             channelId : "6",
             channelNumber : 6,
             title : "Some title",
           }
    ];

    static var PERSON : Array<PersonTypedef> = [
           {
             id : "1",
             first : "First1",
             last : "Last1",
           },
           {
             id : "2",
             first : "First2",
             last : "Last2",
           }
    ];

    static private inline ROLE_PRIORITY : Int = 99; 

    var mIntKeyMap : Map<Int, ValueClass>;
    var mStringKeyMap : Map<String, ValueClass>;
    var mObjectKeyMap : Map<KeyClass, ValueClass>;
    var mMapOfArray : Map<Int, Array<AnotherClass>>;
    var mMapOfMap : Map<Int, Map<String, AnotherClass>>;
    var mDynamicKeyMap : Map<Dynamic, String>;

    public var intKeyMap (get_intKeyMap, never) : Map<Int, ValueClass>;
    public var stringKeyMap (get_stringKeyMap, never) : Map<String, ValueClass>;
    public var objectKeyMap (get_objectKeyMap, never) : Map<KeyClass, ValueClass>;
    public var mapOfArray (get_mapOfArray, never) : Map<Int, Array<AnotherClass>>;
    public var mapOfMap (get_mapOfMap, never) : Map<Int, Map<String, AnotherClass>>;
    public var dynamicKeyMap (get_dynamicKeyMap, never) : Map<Dynamic, String>;

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

    public function get_dynamicKeyMap() : Map<Dynamic, String>
    {
       if (mDynamicKeyMap == null) 
       {
          mDynamicKeyMap = new Map<Dynamic, String>();
       }
       return mDynamicKeyMap;
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

         // this is failing 
         anotherObjType.templateArray.push(
                 templateFactory.templateForA(),
                 templateFactory.templateForB(),
                 templateFactory.templateForC()
         );

         // this is a variation of above, and should not fail
         anotherObjType.templateArray.push(
                 templateFactory.templateForA(),
                 templateFactory.templateForB(),
                 templateFactory.templateForC() // abraca'dabra magic :) 
         );

         // also failing 
         anotherObjType.templateArray.push(
                 templateFactory.templateForA(),
                 templateFactory.templateForB(),
                 movieDataStructure.FIELD_IS_ADULT_NUM
         );

         // also failing 
         anotherObjType.templateArray.push(
                 templateFactory.templateForA(),
                 templateFactory.templateForB(),
                 "String Literal"
         );

         // this is a variation of above, and should not fail
         anotherObjType.templateArray.push(
                 templateFactory.templateForA(),
                 templateFactory.templateForB(),
                 "String Literal" // abraca'dabra magic :) 
         );

         a++; // this is working correct i.e. if comment is here, switch begins in next line
         switch (expression) {
             case value1:
                 trace("expression value is value1");
             case value2:
                 trace("expression value is value1");
         }

         // this is a variation of above
         // this one is incorrectly indenting i.e. if there's no comment on the line above switch,
         // switch statement is starting right after previous statement i.e. as follows:
         // a++;    switch (expression) {
         // it is not resulting in compiler error though
         a++; 
         switch (expression) {
             case value1:
                 trace("expression value is value1");
             case value2:
                 trace("expression value is value1");
         }

         // making sure this succeeds
         functionGHIJ(
         param1,
         param2
         );

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

        // this should not fail
        someObject.
         methodIsOnNextLine(); 

        // this should not be failing either
        (cast(someObject, 
         SomeClass)).someMethod(new<Int>[5], new<Int>[10]); // <int> & <Int> should both be allowed for <Int>,
                                                              // whether it is here or in Dictionary declaration

         // this is tricky...whenever you see { ... } inside a method call, don't try to convert it
         // pass it as-is into haxe  
         someFunction( param1,
                      {season:"Winter",
                       wish:"Snow",
                       intent:"Skiing, Exercise, Loose Weight", 
                       offered:"Hot Chocolate",
                       result:"Gained Weight",
                       }, param3
         );

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

        // this should not be failing
        if (expression1 /* some comment */ && class.Method() /* returns boolean */ && Std.is(Type.typeof(anObjetc), classType))
        {
            isResult112 = true;
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
                value = map.keys().hasNext();  // which is more efficient: map.keys().hasNext() or map.iterator().hasNext()
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
    public function sendCommand(args: String, anObj: Dynamic):Void
    {
        var nowTheTimeIs : Date = Date.now(); 

        var array : Array<SomeType> = new Array<SomeType>(); 

        var strTest : String = "Hello World is Just a String";

        var x : String = StringTools.trim(strTest.substr(9));

        var y : String = (anObj != null) ? Std.string( anObj ) : "";

        var f : Float = 0.0;
        if (Std.is(Type.typeof(anObj), SomeType))
        {
            f = cast(anObj, SomeType).specialMethod(); 
        }

        var i : Int = 0; 
        while ( i < array.length )
        {
            // some code here
            trace (array[i]);
            
            i++; 
        }

        if( ( mBoolVar1
            && mBoolVar2
            && ! mBoolVar3)
            ||
            ((anObj != null)
                && mBoolVar3
                && ! mBoolVar3)
            ||
            (mBoolVar1
                && mBoolVar2
                && mBoolVar3
                && mBoolVar4)
        )
        {
            // some code here
            dispatchMessageLoadedSignal();
        }

        for (obj /* inferred type: SomeType */ in array) {
            trace (obj.specialMethod()); 
        } 

        for (obj /* inferred type: String */ in array) {
                trace (obj); 
        } 

        for (obj /* inferred type: Dynamic */ in array) {
                trace (obj); 
        } 

        var multiLineStringConstruction : String = "This kind of String construction is failing to convert: "
                                            + strTest.slice(9)
                                            + ". "; 

        // this kind of method calling (or construtor calling) is also failing to convert
        someClass.someStaticMethod(param1,
                                   param2 + // this comment should not break conversion 
                                   value22, // so does this 
                                   param3   // or this :) (should not choke on these parantheses)
                                  );

        var flag : Bool = (someMonths.indexOf("June") != -1);  // indexOf not supported by Haxe array, but Lambda does
                                                               // when converted, this should insert "using Lambda"

        return; 
    }

    function configGc(configuration : Xml) : Void
    {
        if (configuration != null) 
        {
            var xmlList : Iterator<Xml>;

            xmlList = configuration.elementsNamed("enableGcHack");
            if (xmlList.hasNext())
            {
                mEnableGcHack = xmlList.next().nodeValue == "true";
            }

            xmlList = configuration.elementsNamed("gcInterval");
            if (xmlList.hasNext())
            {
                var gcInterval : Int = Std.parseInt(xmlList.next().nodeValue);
                if (gcInterval > 0) 
                {
                    // some code 
                }
            }
        }
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
    
    // all the unit test annotations are being enclosed in meta
    // to make it easy for converter, I removed meta
    // we should not have any @meta
    
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

    // order=value parts can be moved to top of the annotations (in comments)
    // see below... note: order should not be in any annotation itself
    // order=-1
    @Before
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



// last way left , for using TIVOCONFIG ... at top level of the file,
// i.e. not inside a package or class or method scope but, at file scope
#if TIVOCONFIG_DEBUG
{
    interface IGlobalInterface
    {
        function summerMethod():Int;
    }
}
#end // TIVOCONFIG_DEBUG

