/**
 * This is a header comment with 1 line space before the package
 **/

package {
	public class Test extends Sprite {
		static public var t : String = "eorw";

		static var _s : Int;
		private static var _position:int = 0;


		static public function get s() : Int {
			return _s;
		}

		var a : String = "must be in constructor"; // the a var

		/**
		 * Constructor
		 **/
		public function Test(nDefault:boolean, yes:string="f") { // comment at the start of Test
			super();
			var v = x as something; // x as something comment
			var w = x as int;
			var z = x as array;
		}

		/**
		 * Docs for black
		 */
		public function get black() : uint {
			var v = true ? true : false;
			if(s is int) {}
			if(a != b) return 5;
			if(a !== undefined) return 8;
			return 2;
			var u : uint = 5;
		}

		function get myField() {
			return 8;
		}

		function addHandler(f:Function):void {
			var rDelay:Number = (isNaN(p_obj.delay) ? 0 : p_obj.delay); // Real delay
			return;
		}

		public function set myname(v:String):void {
			_myname = v;
		}

		// Class trailing comments
	}

	interface Interf extends Another implements SomethingElse, AndMore {
		public function get black();
		public function set blue(v:string);
	}


	public class MoreTests {
		public function MoreTests(f:Function) {
			if(true) {
				for(var i:uint = 0; i < 7; i++)
					val += "0";				
			} else {
				for(i = 0; i < 8; i++)
					val += "0";
			}

			for(var i:uint = 0; i < 7; i++)
				val += "0";
			for(i = 0; i < 8; i++)
				val += "0";

			var b = new PushButton(Lib.current, 10, 10, "Hello\nfrom haxe", click);
		}

		public function get dreams():String {
			return _dreams;
		}

		public function set dreams(v:String) {
			_dreams = v;
		}

		public function get object() : Object  {
			// this has to return {} in output
			return _obj;
		}
	}
}
