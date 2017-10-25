package {
    public class Issue275 {
        public function Issue275() {
            var a:int = 1;
            var b:int = 1;
            var c:int = 1;
            var d:int  = 1;
            d += a > b || c != 0;
        }
    }
}