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

package as3tohx
{
    //converter should remove duplicates
    import my.duplicated.class;
    import my.duplicated.class;

    /**
     * Most commonly failing interface use case.
     */
    interface IAnotherInterface
    {
        function oneMethod():Date; 

        // missing semi-colon in AS3 code is Valid
        function twoMethod():Date 

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
                             arg3:Float):Void 
    }

    /**
     * Standalone function at package level with no class.
     * 
     * @return always false
     */
    public function standaloneFunc(object:Object):Boolean
    {
        TIVOCONFIG::COVERAGE {
            trace("blah");
        }

        // another way of using TIVOCONFIG 
        if (TIVOCONFIG::UNSAFE_PRIVACY) {
            trace("roar");
        }

        TIVOCONFIG::ASSERT {
            if (object) {
                TIVOCONFIG::DEBUG_PRINT {
                    trace(object.value);
                }
            }
            else {
                trace("blah");
            }
        }

        // consistently failing in this example, with error message:
        // 'unexpected else'
        if (TIVOCONFIG::UNSAFE_PRIVACY)
        {
          Logger.get().log(LogLevel.INFO,
           "No ContentView definition is available for this mix: " + mix.mixId +
            " used the default view");
        }
        else // No IDs in production logs, for privacy.
        {
           Logger.get().log(LogLevel.INFO,
            "No ContentView definition is available for a mix; used the default view");
        }

        return false;
    }

    /**
     * This interface is implemented by classes that want to receive
     * ICE commands. 
     */
    public interface ISomeInterface
    {
        /**
         * Send a command to the ICE server.
         */
        function sendCommand(args:String):void;
    }    

    /**
     *  This class is marked with final and
     *  should be converted to the Haxe "@:final"
     */
    public final class Main extends myClass implements ISomeInterface
    {
        /**
         * assert fires an AssertionFailedEvent of this type.
         */
        public static const ASSERTION_FAILED:String =
            "assertion failed";

        static public var someMonths  : Array = [ "January", "February", "March" ];

        // apparently, if there is an extra comma (,) after the last value in an array/vector
        // declaration (or creating when passing as a param to function) is allowed in AS3
        // there were several places such as these in code hence, need to handle it.
        static public var someDay     : Array = [ "January", 1, 1970, "AD", ]; 

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

        private static const VIDEO_PROVIDER_INFO_ITEMS:Array = [
            { name: "Amazon", imageUrl: "images/providers/Source_Amazon_icon_sm.png", partnerId: "Amazon-Id", 
                uiDestinationId:"Amazon-Des-Id" },
            { name: "Netflix", imageUrl: "images/providers/Source_Netflix_icon_sm.png", partnerId: "Netflix-Id", 
                uiDestinationId:"Netflix-Des-Id" },
        ];

        // --- more examples --- I know this is too many examples... you don't have to code for all these
        // just code for the one above ... these are just additional test data for validation :)

        private static const DESTINATION_ITEMS:Array = [
            {name:"amazon", uiDestinationId: "Amazon-Des-Id", uri:"Amazon-transition-uri"},
            {name:"netflix", uiDestinationId: "Netflix-Des-Id", uri:"Netflix-transition-uri"},
            ];
        
        private static const COLLECTION:Array           = [
            { id: "1", title: "Collection1", type: CollectionType.SERIES, 
                imageType: ImageType.TV_SHOW_SERIES_LOGO, imageUrl: "images/discovery/flyout6.jpg", 
                height: 150, width: 200 },
            { id: "2", title: "Collection2", type: CollectionType.SERIES, 
                imageType: ImageType.TV_SHOW_SERIES_LOGO, imageUrl: "images/discovery/flyout7.jpg", 
                height: 150, width: 200 },
        ];

        private static const CONTENT:Array     = [
            { id: "1", title: "Content1", match: MatchedField.TITLE, includeInSearch: true },
            { id: "2", title: "Content2", match: MatchedField.TITLE, includeInSearch: true },
        ];
        
        private static const OFFER:Array    = [
            { id: "1", contentId: "1", transportType: OfferTransportType.STREAM, channelCallSign: "CBS", channelId: "5", channelNumber: 5, title: "Some title" },
            { id: "2", contentId: "2", transportType: OfferTransportType.STREAM, channelCallSign: "CBS", channelId: "6", channelNumber: 6, title: "Some title" },
        ];

        private static const PERSON:Array = [
            { id: "1", first: "First1", last: "Last1" },
            { id: "2", first: "First2", last: "Last2" },
        ];

        static private const ROLE_PRIORITY : int = 99; 

        private var mIntKeyMap:Dictionary/*.<Int, ValueClass>*/ = null;
        private var mStringKeyMap:Dictionary/*.<String, ValueClass>*/ = null;
        private var mObjectKeyMap:Dictionary/*.<KeyClass, ValueClass>*/ = null;
        private var mMapOfArray:Dictionary/*.<Int, Vector.<AnotherClass>>*/ = null;
        private var mMapOfMap:Dictionary/*.<Int, Dictionary.<String, AnotherClass>>*/ = null;
        private var mDynamicKeyMap:Dictionary/*.<Object, String>*/ = null;

        public final function get intKeyMap():Dictionary/*.<Int, ValueClass>*/
        {
            if (mIntKeyMap == null) {
                mIntKeyMap = new Dictionary/*.<Int, ValueClass>*/();
            }
            return mIntKeyMap;
        }

        public final function get stringKeyMap():Dictionary/*.<String, ValueClass>*/
        {
            if (mStringKeyMap == null) {
                mStringKeyMap = new Dictionary/*.<String, ValueClass>*/();
            }
            return mStringKeyMap;
        }

        public final function get objectKeyMap():Dictionary/*.<KeyClass, ValueClass>*/
        {
            if (mObjectKeyMap == null) {
                mObjectKeyMap = new Dictionary/*.<KeyClass, ValueClass>*/();
            }
            return mObjectKeyMap;
        }

        public final function get mapOfArray():Dictionary/*.<Int, Vector.<AnotherClass>>*/
        {
            if (mMapOfArray == null) {
                mMapOfArray = new Dictionary/*.<Int, Vector.<AnotherClass>>*/();
            }
            return mMapOfArray;
        }

        public final function get mapOfMap():Dictionary/*.<Int, Dictionary.<String, AnotherClass>>*/
        {
            if (mMapOfMap == null) {
                mMapOfMap = new Dictionary/*.<Int, Dictionary.<String, AnotherClass>>*/();
            }
            return mMapOfMap;
        }

        public final function get dynamicKeyMap():Dictionary/*.<Object, String>*/
        {
            if (mDynamicKeyMap == null) {
                mDynamicKeyMap = new Dictionary/*.<Object, String>*/();
            }
            return mDynamicKeyMap;
        }

        var isResult1: Boolean = true;
        var isResult2: Boolean = true;
        var isResult3: Boolean = true;
        var isResult4: Boolean = true;

        // the line below is to test assigning a value
        // during variable declaration
        var intVal: int = 6;

        private var _sampleProperty:Object;

        /**
         * GETTER & SETTER STATEMENTS
         * This section tests to make property set / get methods private
         * and make them named with set_ get_
         */

        public function get sampleProperty(): Object
        {
            return _sampleProperty;
        }

        public function set sampleProperty(value: Object):void
        {
            _sampleProperty = value;
        }

        public function testPublicMethod():void
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
            funcA( paramA, paramB, paramC, paramD);

            //
            // Function call: Each parameter on a
            // seperate line with no comments but
            // with white space
            //
            funcB( paramA,
                    paramB,
                    paramC,
                    paramD);

            /**
             * Function call: Each parameter on a
             * seperate line with comments and
             * white space to preserve
             */
            funcC( paramA,    // comment on paramA
                    paramB,    /* comment describing paramB */
                    paramC,
                    paramD);   // one more comment


            /**
             * Function call: Parameters across different
             * lines, with comments interspersed and
             * white space
             */
            retValue = funcD(paramA,    // comment on paramA
                    paramB, paramC,    /* comment describing paramB */
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
                    break;
                case value2:
                    trace("expression value is value1");
                    break;
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
                    break;
                case value2:
                    trace("expression value is value1");
                    break;
            }

            /** I couldn't do haxe code for this, I'm pretty sure you can figure how this is in haxe */
            // need to be able to convert these anonymous callback function definitions
            someAsyncEventRegisterMethod(
                "listener description or name",
                // anonymous call back function
                function():SomeType
                {
                    return aValueOfSomeType; // could be another function call 
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
            retValue = funcE(valueA + valueB + valueC +    // comment on paramA, B, C
                    valueD + valueE + valueF,     // comment on paramD, E, F
                    paramA, paramB, /* comment */ paramC,    /* comment describing paramC */
                    // last comment
                    paramD);

            // this should not fail
            someObject.
            methodIsOnNextLine(); 

            // this should not be failing either
            (someObject
            as SomeClass).someMethod(new<Int>[5], new<int>[10]); // <int> & <Int> should both be allowed for <Int>,
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
            if (expression1 /* some comment */ && class.Method() /* returns boolean */ && anObjetc is classType)
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
                    value = map.hasOwnProperty(myClass);
                }
                else if (isResult4)
                {
                    // Testing that "hasAnyProperties(map)" is
                    // replaced with "map.keys().hasNext()"
                    value = hasAnyProperties(map);
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
             * Below are couple of simple ways ... variants ...
             * of coding switch statements in our AS3 code.
             * These seem to spread all over the code and
             * developers coming on board expressed that as3tohx
             * converter tool should handle this.
             */

            // I did not provide corresponding haxe golden code --- hopefully, that's simple.

            switch(something)
            {
                case 1:
                {
                    a = 3;
                }
                break;
            
                case 2:
                {
                    a = 4;
                }
                return;
            }
            
            switch(something)
            {
                case 1:
                {
                    a = 3;
                    break;
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
            var value: int;

            switch(param)
            {
                case 0:
                {
                    value = 1;
                }
                break;
                // comment line
                case funcT(param): // comment explaining function
                {
                    // The if statement below tests that
                    // 'if (obj)' is converted into 'if (obj != null)'

                    var obj : Object = {};
                    if (obj)
                    {
                        trace("trace line");
                    }

                    value = 2;
                }
                break;

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
                break;

                default:
                     value = 0;
            }
            return true;
        }

        public function sendReport(msg:String):void
        {
            TIVOCONFIG::DEBUG_PRINT {
                // Make sure msg is newline terminated...
                if (msg.charAt(msg.length - 1) != '\n')
                {
                    msg = msg + '\n';
                }

                // Now send it to each connection...
                for (var obj:Object in mConnections)
                {
                    const conn:TelnetConnection = obj as TelnetConnection;
                    conn.write(msg);
                }
            }


            if (mNoChangeCount > MAX_NO_CHANGE_COUNT ||
                ++mTimeoutCount > (MAX_IDLE_LOG_TIME / TIMEOUT))
            {
                mTimer.stop();
                mTimeoutCount = 0;
                mNoChangeCount = 0;
            }

            var obj:Object;
            var foo:Dictionary.<frob, nab> = Dictionary.<frob, nab>(obj);

            someFunc(param1, /* this is so as it is so so */
                param2 /* this is because that reason */
                /* not passing 3rd param as it default to blah */); 
        }
        
        // I do not have a converted golden version for this next one !
        // I trust you to figure this :)
        
        // this is basically like earlier tip about passing values as-is when enclosed in {...} within a function call
        // here, this is CDATA / XML / JSON string ... need not always be inside quotes... so we should pass as-is
        
        public final function someWrapperMethod():String {
                    return someUtilClass.buildCustomObjFromThisJsonStringHere(<![CDATA[
                        {
                        "conflicts": {
                        "type": "subscriptionConflicts",
                        "willClip": [
                        {
                        "requestWinning": true,
                        "winningOffer": [
                        {
                        "subtitle": "Family Business",
                        "title": "Dog the Bounty Hunter",
                        "startTime": "2011-03-14 15:00:00",
                        "duration": 3600,
                        "type": "offer",
                        "channel": {
                        "isReceived": true,
                        "name": "A & E Network",
                        "isKidZone": false,
                        "isBlocked": false,
                        "channelId": "tivo:ch.489",
                        "callSign": "AETV",
                        "isDigital": false,
                        "stationId": "tivo:st.335",
                        "channelNumber": "27",
                        "logoIndex": 65548,
                        "sourceType": "cable",
                        "type": "channel",
                        "levelOfDetail": "low"
                        },
                        "levelOfDetail": "low"
                        },
                        {
                        "subtitle": "Wines and Misdemeanors",
                        "title": "Las Vegas",
                        "startTime": "2011-03-14 16:00:00",
                        "duration": 3600,
                        "type": "offer",
                        "channel": {
                        "isReceived": true,
                        "name": "Turner Network TV",
                        "isKidZone": false,
                        "isBlocked": false,
                        "channelId": "tivo:ch.9",
                        "callSign": "TNT",
                        "isDigital": false,
                        "stationId": "tivo:st.984",
                        "channelNumber": "26",
                        "logoIndex": 65542,
                        "sourceType": "cable",
                        "type": "channel",
                        "levelOfDetail": "low"
                        },
                        "levelOfDetail": "low"
                        }
                        ],
                        "losingRecording": [
                        {
                        "state": "scheduled",
                        "bodyId": "tsn:7D8000190307708",
                        "scheduledStartTime": "2011-03-14 16:00:00",
                        "scheduledEndTime": "2011-03-14 17:02:00",
                        "type": "recording",
                        "expectedDeletion": "2011-03-16 16:00:00"
                        }
                        ],
                        "reason": "startTimeClipped",
                        "type": "conflict",
                        "losingOffer": [
                        {
                        "subtitle": "Offense",
                        "title": "Law & Order: Criminal Intent",
                        "startTime": "2011-03-14 16:00:00",
                        "duration": 3600,
                        "type": "offer",
                        "channel": {
                        "isReceived": true,
                        "name": "USA Network",
                        "isKidZone": false,
                        "isBlocked": false,
                        "channelId": "tivo:ch.9",
                        "callSign": "USA",
                        "isDigital": false,
                        "stationId": "tivo:st.988",
                        "channelNumber": "25",
                        "logoIndex": 66054,
                        "sourceType": "cable",
                        "type": "channel",
                        "levelOfDetail": "low"
                        },
                        "levelOfDetail": "low"
                        }
                        ]
                        }
                        ],
                        "willGet": [
                        {
                        "subtitle": "Family Business",
                        "title": "Dog the Bounty Hunter",
                        "startTime": "2011-03-14 15:00:00",
                        "duration": 3600,
                        "type": "offer",
                        "channel": {
                        "isReceived": true,
                        "name": "A & E Network",
                        "isKidZone": false,
                        "isBlocked": false,
                        "channelId": "tivo:ch.489",
                        "callSign": "AETV",
                        "isDigital": false,
                        "stationId": "tivo:st.335",
                        "channelNumber": "27",
                        "logoIndex": 65548,
                        "sourceType": "cable",
                        "type": "channel",
                        "levelOfDetail": "low"
                        },
                        "levelOfDetail": "low"
                        }
                        ]
                        },
                        "type": "subscribeResult"
                        }
                                                ]]>);
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
        public final function testPublicMethod3(var1: Bool, // comment line 1
                var2: String,    var3: UInt, /* comment line 2 */
                func4: Function, var5: Array): Boolean  // comment line 3
        {
            return true;
        }

        /**
        * All function arguments are on individual lines
        * with comments inbetween
        */
        public function testPublicMethod5(var1: Bool,
                var2: String,
                // comment line here
                var3: UInt,
                /* comment line there before 2 white space line above*/
                func4: Function,
                /* comment line there before white space*/
                var5: Array): Boolean
        {
            return true;
        }

        /**
         * This is how we receive a command from the ICE Server.
         */
        public function sendCommand(args:String, anObj:Object):void
        {
            var nowTheTimeIs : Date = new Date(); 

            var array : Vector.<SomeType> = new Vector.<SomeType>(); 

            var strTest : String = "Hello World is Just a String";

            var x : String = StringUtil.trim ( strTest.slice(9) );

            var y : String = (anObj) ? anObj.toString() : "";

            var f : Float = 0.0; 
            if (anObj is SomeType) {
                f = (anObj as SomeType).specialMethod(); 
            }

            for ( var i : int = 0; i < array.length; i++ ) {
                // some code here
                trace (array[i]);
            }

            var newX:int = int(x + (x < 0 ? -0.5 : 0.5));         // should result in cast
            var newY:int = int(xyzObj.getString("YCoordinate"));  // should result in Std.parseInt

            if( ( mBoolVar1
                && mBoolVar2
                && ! mBoolVar3)
                ||
                (anObj
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

            for each (var obj:SomeType in array) {
                trace (obj.specialMethod()); 
            } 

            // this is failing
            for (var obj:String in array)
            {
                trace (obj); 
            }

            // this is failing too 
            for (var obj:Object in array)
            {
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

            var flag : Boolean = (someMonths.indexOf("June") != -1);   // indexOf not supported by Haxe array, but Lambda does
                                                                       // when converted, this should insert "using Lambda"

            return;
        }

        private function configGc(configuration:XML):void
        {
            if (configuration != null)
            {
                var xmlList:XMLList = configuration.child("enableGcHack");
                var item:XML;
                if (xmlList.length() > 0)
                {
                    item = xmlList[0];
                    if (item.name() == "enableGcHack")
                    {
                       mEnableGcHack = Boolean(item.valueOf().toString()=="true");
                    }
                }

                xmlList = configuration.child("gcInterval");
                if (xmlList.length() > 0)
                {
                    item = xmlList[0];
                    if (item.name() == "gcInterval")
                    {
                        var gcInterval:int = int(item.valueOf());
                        if (gcInterval > 0)
                        {
                            // some code 
                        }
                    }
                }
            }
        }

        /**
         * Conditionally compiled code with comments
         */
        TIVOCONFIG::ASSERT
        public function someFunctionToTestTiVoConfig():void
        {
            return; 
        }

        // below are unit tests' methods with annotations
        
        [Test(description="this will test prime number function")]
        public function testPrime(val:Int):Boolean
        {
            return true;
        }

        [Test(async, order=12, description="Test for missing golden")]
        public function testWhole(val:Int):Boolean
        {
            return true;
        }

        [Test(order=24, dataProvider="trueAndFalse")]
        public function testBooleanValues(val:Boolean):Boolean
        {
            return true;
        }

        [Ignore("Memory leak detection is not deterministic")]
        [Test(order=24, dataProvider="memoryMap")]
        public function testBooleanValues(val:Boolean):Boolean
        {
            return true;
        }

        [Before(order=-1)]
        public function firstMostBefore():void
        {
            return;
        }

        [Before]
        public function unorderedBefore():void
        {
            return;
        }

        [After]
        public function tearDown():void
        {
            return;
        }

        [BeforeClass]
        public function preConstruction():void
        {
            return;
        }

        [AfterClass]
        public function onDestroy():void
        {
            return;
        }
    }
}

// last way left , for using TIVOCONFIG ... at top level of the file,
// i.e. not inside a package or class or method scope but, at file scope
TIVOCONFIG::DEBUG {
    interface IGlobalInterface
    {
        function summerMethod():Int;
    }
}

