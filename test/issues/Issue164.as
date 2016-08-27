package {
    import flash.display.DisplayObject;
    public class Issue164 {
        public function Issue164(rootClass:Class) {
            var d:DisplayObject = new rootClass() as DisplayObject;
        }
    }
}