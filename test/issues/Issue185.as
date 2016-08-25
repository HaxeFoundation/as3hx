package {
    public class Issue185 {
        public function Issue185() {
            var a:Array = [1];
            var i:int = int(a.removeAt(0));
            a.splice(1, 1)[0];
        }
    }
}