package {
    public class Issue296 {
        public function Issue296() {
            function some(i:int):Boolean { return i < 10; }
            for(var i:int = 0; some(i); i++) {
                trace(a.pop());
            }
        }
    }
}