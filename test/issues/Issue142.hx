import flash.display.Scene;
import flash.display.Sprite;
import flash.events.DataEvent;

class Issue142 {

	public function new() {
		var sceneClass:Class<Dynamic> = as3hx.Compat.castClass(Type.resolveClass('SceneType'));
		var currentScene:Scene = AS3.as(Type.createInstance(sceneClass, []), Scene);

		var d:Date = Date.now();
		var s:Sprite = new Sprite();
	}

}