package {
	public class Casts {
		public static function blah() {
			var _icon = new (iconOrLabel as Class)() as DisplayObject;
			var z = (a); // not a cast
			var a = Number(intParam);
			var b = String(5);
			var c = Int(4.5);
			var d = Int("1.23");
			var e = MyClass(otherObj);
			var f = Static.method(v);
			var g = MyClass(Static.method(v));
			var h = MyClass(object.method(v));
			var i = new OtherClass(g);
			var j = typeof a;
			if(typeof j == "string") {}
			if(typeof j == typeof a) {}

			if (typeof(arguments[i]) == "string" && !AuxFunctions.isInArray(arguments[i], properties)) properties.push(arguments[i]);
		}
	}
}
