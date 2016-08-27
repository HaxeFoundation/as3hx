import flash.display.Scene;
import flash.display.Sprite;
import flash.events.DataEvent;

class Issue142
{
    public function new()
    {
        var sceneClass : Class<Dynamic> = Type.getClass(Type.resolveClass("SceneType"));
        var currentScene : Scene = try cast(Type.createInstance(sceneClass, []), Scene) catch(e:Dynamic) null;
        
        var d : Date = Date.now();
        var s : Sprite = new Sprite();
    }
}
