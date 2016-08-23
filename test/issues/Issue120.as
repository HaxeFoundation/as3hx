package {
    public class Issue120 {
        public function Issue120() {
            var call:Function = trace;
            var args:Array = [];
            call.apply(null, args);
            call.apply(null, [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
        }
    }
}