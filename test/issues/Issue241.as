package {
    import flash.utils.Dictionary;
    public class Issue241 {
        public function Issue241() {
            var d:Dictionary = new Dictionary();
            trace(d is Dictionary);
        }
    }
}