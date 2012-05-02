package
{
	public class DynamicAccess {
		// Found in Singleton.as
		private static var classMap:Object = {};
		public static function getInstance(interfaceName:String):Object
		{
			var c:Class = classMap[interfaceName];
			return c["getInstance"]();
		}
		static public function getClass(interfaceName : String) : Class {
			return classMap[interfaceName];
		}
		static public function assignSomething(f : String, value : String): Void {
			classMap[f] = value;
		}
	}
}
