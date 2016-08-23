package {
    public class Issue176 {
        public function Issue176() {
            var call:Function = trace;
            call.call(null, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0);
        }
    }
}