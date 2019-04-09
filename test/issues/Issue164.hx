import flash.display.DisplayObject;

class Issue164 {

	public function new(rootClass:Class<Dynamic>) {
		var d:DisplayObject = AS3.as(Type.createInstance(rootClass, []), DisplayObject);
	}

}