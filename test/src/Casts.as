package {
	public class Casts {
		public static function blah(iconOrLabel:Object, a:Object, intParam:int, strParam:String, numParam:Number, otherObj:Object, v:Object, object:Method, value:String, properties:Array):void {
			var _icon:DisplayObject2 = new (iconOrLabel as Class)() as DisplayObject2;
			var z:Object = (a); // not a cast
			var a:Object = Number(intParam);
			var k:Object = Number(strParam);
			var l:Object = Number(numParam);
			var b:String = String(5);
			var c:int = int(4.5);
			var d:int = int("1.23");
			var e:MyClass = MyClass(otherObj);
			var f:Number = Static.method(v);
			var g:MyClass = MyClass(Static.method(v));
			var h:MyClass = MyClass(object.method(v));
			var i:OtherClass = new OtherClass(g);
			var j:Object = typeof a;
			if(typeof j == "string") {}
			if(typeof j == typeof a) {}
			var type:String = typeof(value);

			if (typeof(arguments[i]) == "string" && !AuxFunctions.isInArray(arguments[i], properties)) properties.push(arguments[i]);
		}
	}
}
class DisplayObject2 {}
class MyClass { }
class Static {
	public static function method(x:Object):Number { return 0;  }
}
class Method extends MyClass {
	public function method(x:Object):Method { return this; }
}
class OtherClass {
	public function OtherClass (param:MyClass) {}
}

