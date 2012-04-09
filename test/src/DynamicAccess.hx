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
     	static public function getClass(interfaceName : String) : Class<Dynamic> {
		return classMap[interfaceName];
	}
}
}
