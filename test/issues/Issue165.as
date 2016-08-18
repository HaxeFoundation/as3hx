package {
    public class Issue165 {
        public function Issue165() {
            var a:Array = [];
            var b:Array = a.splice(0);
            var c:Array = a.splice(0, 0, 1, 2, 3, 4, 5);
            var d:Array = a.splice(0, 1);
        }
    }
}