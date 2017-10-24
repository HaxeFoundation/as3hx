package {
    public class Issue274 {
        public function Issue274() {
            var a:int = 1;
            var b:int = 1;
            var c:int = 1;
            var e:int = 1;
            e += (a > b || c > b) ? 1 : 0;
        }
    }
}