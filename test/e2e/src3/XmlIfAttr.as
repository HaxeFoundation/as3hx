package {
	public class XmlIfAttr {
		// protected static var HAS_UNCOMPRESS:Boolean = describeType(123).factory.method.(@name == "uncompress").parameter.length() > 0;
		protected static var HAS_UNCOMPRESS:Boolean = getUnc();
		public function XmlIfAttr() {
		}
		public static function getUnc():Boolean {
			return describeType(123).factory.method.(@name == "uncompress").parameter.length() > 0;
		}
		public function describeType(v:Number):XML {
			return <test/>;
		}
	}
}