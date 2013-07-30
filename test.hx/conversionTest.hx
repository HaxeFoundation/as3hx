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
import my.duplicated.Class;


// Additional implicit imports...
import as3tohx.AnotherClass;
import as3tohx.Frob;
import as3tohx.KeyClass;
import as3tohx.MyClass;
import as3tohx.Nab;
import as3tohx.SomeType;
import as3tohx.TelnetConnection;
import as3tohx.UInt;
import as3tohx.ValueClass;

typedef VideoProviderInfoItemsTypedef = {
    var name : String;
    var imageUrl : String;
    var partnerId : String;
    var uiDestinationId : String;
}

typedef DestinationItemsTypedef = {
    var name : String;
    var uiDestinationId : String;
    var uri : String;
}

typedef CollectionTypedef = {
    var id : String;
    var title : String;
    var type : Dynamic;
    var imageType : Dynamic;
    var imageUrl : String;
    var height : Int;
    var width : Int;
}

typedef ContentTypedef = {
    var id : String;
    var title : String;
    var match : Dynamic;
    var includeInSearch : Bool;
}

typedef OfferTypedef = {
    var id : String;
    var contentId : String;
    var transportType : Dynamic;
    var channelCallSign : String;
    var channelId : String;
    var channelNumber : Int;
    var title : String;
}

typedef PersonTypedef = {
    var id : String;
    var first : String;
    var last : String;
}

//converter should remove duplicates



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
        
        
        // another way of using TIVOCONFIG
        #if TIVOCONFIG_UNSAFE_PRIVACY
        {            
            trace("roar");
        }
        #end // TIVOCONFIG_UNSAFE_PRIVACY
        
        
        
        {            
            if (object != null){
                
                {                    
                    trace(object.value);
                }
                
                
            }
            else {
                trace("blah");
            }
        }
        
        
        
        // consistently failing in this example, with error message:
        // 'unexpected else'
        #if TIVOCONFIG_UNSAFE_PRIVACY        
        {
            Logger.get().log(LogLevel.INFO,
                    "No ContentView definition is available for this mix: " + mix.mixId +
                    " used the default view");
        }
        #else          // No IDs in production logs, for privacy.  
        {
            Logger.get().log(LogLevel.INFO,
                    "No ContentView definition is available for a mix; used the default view");
        }
        #end // TIVOCONFIG_UNSAFE_PRIVACY
        
        
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
    public var dynamicKeyMap(get_dynamicKeyMap, never) : Map<Dynamic, String>;
    public var sampleProperty(get_sampleProperty, set_sampleProperty) : Dynamic;

    /**
     * assert fires an AssertionFailedEvent of this type.
     */
    public static inline var ASSERTION_FAILED : String = 
        "assertion failed";
    
    public static var someMonths : Array<Dynamic> = ["January", "February", "March"];
    
    // apparently, if there is an extra comma (,) after the last value in an array/vector
    // declaration (or creating when passing as a param to function) is allowed in AS3
    // there were several places such as these in code hence, need to handle it.
    public static var someDay : Array<Dynamic> = ["January", 1, 1970, "AD"];
    
    //---------- this is the most commonly occurring type of data declarations that we missed -
    //---------- yes, we are done :)
    
    /** IMP: when converting to haxe ... these result in TWO (2) Parts
     *       1. a typedef declaration on top
     *       2. this data definition in haxe
     *
     *       Typedef declaration will derive field names from here, e.g. "name", "imageUrl".
     *       Data-types for those type declarations will be based on data values here.
     *       i.e. if it is quoted - String type, it is a number... Int (ignore Floats, everything is Int),
     *            if it is true/false - Bool, everything else (unknown types) are Dynamic type.
     *
     *       This typedef name will be same as data definition e.g. ABC_DEF converted to AbcDefTypedef.
     *
     *       i.e.   ABC_DEF : Array will become ABC_DEF : Array<AbcDefTypedef>.
     */
    
    private static inline var VIDEO_PROVIDER_INFO_ITEMS : Array<VideoProviderInfoItems> = [
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

        }];
    
    // --- more examples --- I know this is too many examples... you don't have to code for all these
    // just code for the one above ... these are just additional test data for validation :)
    
    private static inline var DESTINATION_ITEMS : Array<DestinationItems> = [
        {
            name : "amazon",
            uiDestinationId : "Amazon-Des-Id",
            uri : "Amazon-transition-uri",

        }, 
        {
            name : "netflix",
            uiDestinationId : "Netflix-Des-Id",
            uri : "Netflix-transition-uri",

        }];
    
    private static inline var COLLECTION : Array<Collection> = [
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

        }];
    
    private static inline var CONTENT : Array<Content> = [
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

        }];
    
    private static inline var OFFER : Array<Offer> = [
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

        }];
    
    private static inline var PERSON : Array<Person> = [
        {
            id : "1",
            first : "First1",
            last : "Last1",

        }, 
        {
            id : "2",
            first : "First2",
            last : "Last2",

        }];
    
    private static inline var ROLE_PRIORITY : Int = 99;
    
    private var mIntKeyMap : Map<Int, ValueClass> = null;
    private var mStringKeyMap : Map<String, ValueClass> = null;
    private var mObjectKeyMap : Map<KeyClass, ValueClass> = null;
    private var mMapOfArray : Map<Int, Array<AnotherClass>> = null;
    private var mMapOfMap : Map<Int, Map<String, AnotherClass>> = null;
    private var mDynamicKeyMap : Map<Dynamic, String> = null;
    
    private @:final function get_intKeyMap() : Map<Int, ValueClass>
    {
        if (mIntKeyMap == null){
            mIntKeyMap = new Map<Int, ValueClass>();
        }
        return mIntKeyMap;
    }
    
    private @:final function get_stringKeyMap() : Map<String, ValueClass>
    {
        if (mStringKeyMap == null){
            mStringKeyMap = new Map<String, ValueClass>();
        }
        return mStringKeyMap;
    }
    
    private @:final function get_objectKeyMap() : Map<KeyClass, ValueClass>
    {
        if (mObjectKeyMap == null){
            mObjectKeyMap = new Map<KeyClass, ValueClass>();
        }
        return mObjectKeyMap;
    }
    
    private @:final function get_mapOfArray() : Map<Int, Array<AnotherClass>>
    {
        if (mMapOfArray == null){
            mMapOfArray = new Map<Int, Array<AnotherClass>>();
        }
        return mMapOfArray;
    }
    
    private @:final function get_mapOfMap() : Map<Int, Map<String, AnotherClass>>
    {
        if (mMapOfMap == null){
            mMapOfMap = new Map<Int, Map<String, AnotherClass>>();
        }
        return mMapOfMap;
    }
    
    private @:final function get_dynamicKeyMap() : Map<Dynamic, String>
    {
        if (mDynamicKeyMap == null){
            mDynamicKeyMap = new Map<Dynamic, String>();
        }
        return mDynamicKeyMap;
    }
    
    private var isResult1 : Bool = true;
    private var isResult2 : Bool = true;
    private var isResult3 : Bool = true;
    private var isResult4 : Bool = true;
    
    // the line below is to test assigning a value
    // during variable declaration
    private var intVal : Int = 6;
    
    private var _sampleProperty : Dynamic;
    
    /**
     * GETTER & SETTER STATEMENTS
     * This section tests to make property set / get methods private
     * and make them named with set_ get_
     */
    
    private function get_sampleProperty() : Dynamic
    {
        return _sampleProperty;
    }
    
    private function set_sampleProperty(value : Dynamic) : Dynamic
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
                templateFactory.templateForC()  // abraca'dabra magic :)  
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
                "String Literal"  // abraca'dabra magic :)  
                );
        
        a++;  // this is working correct i.e. if comment is here, switch begins in next line  
        switch (expression)
        {
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
        switch (expression)
        {
            case value1:
                trace("expression value is value1");
            case value2:
                trace("expression value is value1");
        }
        
        /** I couldn't do haxe code for this, I'm pretty sure you can figure how this is in haxe */
        // need to be able to convert these anonymous callback function definitions
        someAsyncEventRegisterMethod(
                "listener description or name",
                // anonymous call back function
                function() : SomeType
                {
                    return aValueOfSomeType;
                }
                );
        
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
                        paramA, paramB,  /* comment */  paramC,  /* comment describing paramC */  
                        // last comment
                        paramD);
        
        // this should not fail
        someObject.methodIsOnNextLine();
        
        // this should not be failing either
        (try cast(someObject, SomeClass) catch(e:Dynamic) null).someMethod(cast [5], cast [10]);  // <int> & <Int> should both be allowed for <Int>,  
        // whether it is here or in Dictionary declaration
        
        // this is tricky...whenever you see { ... } inside a method call, don't try to convert it
        // pass it as-is into haxe
        someFunction(param1,
                {
                    season : "Winter",
                    wish : "Snow",
                    intent : "Skiing, Exercise, Loose Weight",
                    offered : "Hot Chocolate",
                    result : "Gained Weight",

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
        if (expression1 &&class.Method() && Std.is(anObjetc, classType)  /* returns boolean */    /* some comment */  )
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
                value = map.keys().hasNext();
            }
        }
        /* comment line */
        else if (isResult3)  // coment at the end of the line  
        {
            // one nested if
            if (!isResult1)
                trace("trace line");
        }
        
        /**
         * Below are couple of simple ways ... variants ...
         * of coding switch statements in our AS3 code.
         * These seem to spread all over the code and
         * developers coming on board expressed that as3tohx
         * converter tool should handle this.
         */
        
        // I did not provide corresponding haxe golden code --- hopefully, that's simple.
        
        switch (something)
        {
            case 1:
            {
                a = 3;
            }
            
            case 2:
            {
                a = 4;
            }
            return;
        }
        
        switch (something)
        {
            case 1:
            {
                a = 3;
            }
            
            case 2:
            {
                a = 4;
                return;
            }
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
            case funcT(param):  // comment explaining function  
            {
                // The if statement below tests that
                // 'if (obj)' is converted into 'if (obj != null)'
                
                var obj : Dynamic = { };
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
        }
        return true;
    }
    
    public function sendReport(msg : String) : Void
    {
        
        {            
            // Make sure msg is newline terminated...
            if (msg.charAt(msg.length - 1) != "\n")
            {
                msg = msg + "\n";
            }            
            
            // Now send it to each connection...
            for (obj in Reflect.fields(mConnections))
            {
                var conn : TelnetConnection = try cast(obj, TelnetConnection) catch(e:Dynamic) null;
                conn.write(msg);
            }
        }
        
        
        
        var obj : Dynamic;
        var foo : Map<Frob, Nab> = cast obj;
        
        someFunc(param1,  /* this is so as it is so so */  
                param2  /* this is because that reason */  
                /* not passing 3rd param as it default to blah */);
    }
    
    // I do not have a converted golden version for this next one !
    // I trust you to figure this :)
    
    // this is basically like earlier tip about passing values as-is when enclosed in {...} within a function call
    // here, this is CDATA / XML / JSON string ... need not always be inside quotes... so we should pass as-is
    
    public @:final function someWrapperMethod() : String{
        return someUtilClass.buildCustomObjFromThisJsonStringHere(FastXML.parse("<![CDATA[
                        {
                        \"conflicts\": {
                        \"type\": \"subscriptionConflicts\",
                        \"willClip\": [
                        {
                        \"requestWinning\": true,
                        \"winningOffer\": [
                        {
                        \"subtitle\": \"Family Business\",
                        \"title\": \"Dog the Bounty Hunter\",
                        \"startTime\": \"2011-03-14 15:00:00\",
                        \"duration\": 3600,
                        \"type\": \"offer\",
                        \"channel\": {
                        \"isReceived\": true,
                        \"name\": \"A & E Network\",
                        \"isKidZone\": false,
                        \"isBlocked\": false,
                        \"channelId\": \"tivo:ch.489\",
                        \"callSign\": \"AETV\",
                        \"isDigital\": false,
                        \"stationId\": \"tivo:st.335\",
                        \"channelNumber\": \"27\",
                        \"logoIndex\": 65548,
                        \"sourceType\": \"cable\",
                        \"type\": \"channel\",
                        \"levelOfDetail\": \"low\"
                        },
                        \"levelOfDetail\": \"low\"
                        },
                        {
                        \"subtitle\": \"Wines and Misdemeanors\",
                        \"title\": \"Las Vegas\",
                        \"startTime\": \"2011-03-14 16:00:00\",
                        \"duration\": 3600,
                        \"type\": \"offer\",
                        \"channel\": {
                        \"isReceived\": true,
                        \"name\": \"Turner Network TV\",
                        \"isKidZone\": false,
                        \"isBlocked\": false,
                        \"channelId\": \"tivo:ch.9\",
                        \"callSign\": \"TNT\",
                        \"isDigital\": false,
                        \"stationId\": \"tivo:st.984\",
                        \"channelNumber\": \"26\",
                        \"logoIndex\": 65542,
                        \"sourceType\": \"cable\",
                        \"type\": \"channel\",
                        \"levelOfDetail\": \"low\"
                        },
                        \"levelOfDetail\": \"low\"
                        }
                        ],
                        \"losingRecording\": [
                        {
                        \"state\": \"scheduled\",
                        \"bodyId\": \"tsn:7D8000190307708\",
                        \"scheduledStartTime\": \"2011-03-14 16:00:00\",
                        \"scheduledEndTime\": \"2011-03-14 17:02:00\",
                        \"type\": \"recording\",
                        \"expectedDeletion\": \"2011-03-16 16:00:00\"
                        }
                        ],
                        \"reason\": \"startTimeClipped\",
                        \"type\": \"conflict\",
                        \"losingOffer\": [
                        {
                        \"subtitle\": \"Offense\",
                        \"title\": \"Law & Order: Criminal Intent\",
                        \"startTime\": \"2011-03-14 16:00:00\",
                        \"duration\": 3600,
                        \"type\": \"offer\",
                        \"channel\": {
                        \"isReceived\": true,
                        \"name\": \"USA Network\",
                        \"isKidZone\": false,
                        \"isBlocked\": false,
                        \"channelId\": \"tivo:ch.9\",
                        \"callSign\": \"USA\",
                        \"isDigital\": false,
                        \"stationId\": \"tivo:st.988\",
                        \"channelNumber\": \"25\",
                        \"logoIndex\": 66054,
                        \"sourceType\": \"cable\",
                        \"type\": \"channel\",
                        \"levelOfDetail\": \"low\"
                        },
                        \"levelOfDetail\": \"low\"
                        }
                        ]
                        }
                        ],
                        \"willGet\": [
                        {
                        \"subtitle\": \"Family Business\",
                        \"title\": \"Dog the Bounty Hunter\",
                        \"startTime\": \"2011-03-14 15:00:00\",
                        \"duration\": 3600,
                        \"type\": \"offer\",
                        \"channel\": {
                        \"isReceived\": true,
                        \"name\": \"A & E Network\",
                        \"isKidZone\": false,
                        \"isBlocked\": false,
                        \"channelId\": \"tivo:ch.489\",
                        \"callSign\": \"AETV\",
                        \"isDigital\": false,
                        \"stationId\": \"tivo:st.335\",
                        \"channelNumber\": \"27\",
                        \"logoIndex\": 65548,
                        \"sourceType\": \"cable\",
                        \"type\": \"channel\",
                        \"levelOfDetail\": \"low\"
                        },
                        \"levelOfDetail\": \"low\"
                        }
                        ]
                        },
                        \"type\": \"subscribeResult\"
                        }
                                                ]]>"));
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
            var2 : String, var3 : UInt,  /* comment line 2 */  
            func4 : Function, var5 : Array<Dynamic>) : Bool  // comment line 3  
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
            func4 : Function,
            /* comment line there before white space*/
            var5 : Array<Dynamic>) : Bool
    {
        return true;
    }
    
    /**
     * This is how we receive a command from the ICE Server.
     */
    public function sendCommand(args : String, anObj : Dynamic) : Void
    {
        var nowTheTimeIs : Date = Date.now();
        
        var Array : Array<SomeType> = new Array<SomeType>();
        
        var strTest : String = "Hello World is Just a String";
        
        var x : String = StringTools.trim(strTest.substr(9));
        
        var y : String = ((anObj != null)) ? Std.string(anObj) : "";
        
        var f : Float = 0.0;
        if (Std.is(anObj, SomeType)){
            f = (try cast(anObj, SomeType) catch(e:Dynamic) null).specialMethod();
        }
        
        for (i in 0...Array.length){
            // some code here
            trace(Array[i]);
        }
        
        var newX : Int = Std.parseInt(Std.string(x + (x < (0) ? -0.5 : 0.5)));  // should result in cast  
        var newY : Int = Std.parseInt(Std.string(xyzObj.getString("YCoordinate")));  // should result in Std.parseInt  
        
        if ((mBoolVar1
        && mBoolVar2
        && !mBoolVar3)
        ||
        (anObj != null
        && mBoolVar3
        && !mBoolVar3)
        ||
        (mBoolVar1
        && mBoolVar2
        && mBoolVar3
        && mBoolVar4))
        {
            // some code here
            dispatchMessageLoadedSignal();
        }
        
        for (obj/* AS3HX WARNING could not determine type for var: obj exp: EIdent(array) type: null */ in Array){
            trace(obj.specialMethod());
        }
        
        // this is failing
        for (obj in Reflect.fields(Array))
        {
            trace(obj);
        }
        
        // this is failing too
        for (obj in Reflect.fields(Array))
        {
            trace(obj);
        }
        
        var multiLineStringConstruction : String = "This kind of String construction is failing to convert: "
        + strTest.substr(9)
        + ". ";
        
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
    
    private function configGc(configuration : Xml) : Void
    {
        if (configuration != null)
        {
            var xmlList : Iterator<Xml> = configuration.child("enableGcHack");
            var item : Xml;
            if (xmlList.length() > 0)
            {
                item = xmlList[0];
                if (item.name() == "enableGcHack")
                {
                    mEnableGcHack = cast(Std.string(item.valueOf()) == "true", Bool);
                }
            }
            
            xmlList = configuration.child("gcInterval");
            if (xmlList.length() > 0)
            {
                item = xmlList[0];
                if (item.name() == "gcInterval")
                {
                    var gcInterval : Int = Std.parseInt(Std.string(item.valueOf()));
                    if (gcInterval > 0)
                    {
                    }
                }
            }
        }
    }
    
    /**
     * Conditionally compiled code with comments
     */
    
    public function someFunctionToTestTiVoConfig() : Void
    {
        return;
    }
    
    
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
    
    // order=-1
    @Before
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


// last way left , for using TIVOCONFIG ... at top level of the file,
// i.e. not inside a package or class or method scope but, at file scope
#if TIVOCONFIG_DEBUG
interface IGlobalInterface
{
    function summerMethod() : Int;
}
#end // TIVOCONFIG_DEBUG


