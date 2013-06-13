package {

import flash.utils.getTimer;
import flash.utils.getDefinitionByName;
import __AS3__.vec.Vector;
import mx.utils.object_proxy;

public class FlashInternals {
	// should be flash.xml.QName
	private static var fakeMouseX:QName = new QName(mx_internal, "_mouseX");

	// should be flash.xml.XMLList
	private function nodeSeqEqual(x:XMLList, y:XMLList):Boolean { }

	// should convert to Type.getClassName
	protected function createInFontContext(classObj:Class):Object 
	{
		var className:String = getQualifiedClassName(classObj);
		var className:String = getQualifiedSuperClassName(classObj);
	}

	public function markTime(name:String):void
	{
		var time:int = getTimer();
	}

	public static function getInstance():void {
		Class(getDefinitionByName("mx.resources::ResourceManagerImpl"));
	}
}
}
