package {
    import flash.display.Scene;
    import flash.display.Sprite;
    import flash.events.DataEvent;
    import flash.utils.getDefinitionByName;
    public class Issue142 {
        public function Issue142() {
            var sceneClass:Class = getDefinitionByName("SceneType") as Class;
            var currentScene:Scene = new sceneClass() as Scene;
            
            var d:Date = new Date();
            var s:Sprite = new Sprite();
        }
    }
}