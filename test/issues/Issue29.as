package {
    public class Issue29 {
        public function Issue29() {
            var stuff:Array = [];
            for (var i:int = 0; i < 10 || stuff[i] != null; i++) {
                trace(i);
            }
        }
    }
}