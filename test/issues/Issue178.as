package {
    public class Issue178 {
        public function Issue178() {
            for (var i:int = 0; i < 10; i+=1) {
                trace(i);
            }
            for (var i:int = 0; i < 10; i++) {
                trace(i);
            }
            for (var i:int = 0; i < 10; ++i) {
                trace(i);
            }
            for (var i:int = 0; i < 10; i--) {
                trace(i);
            }
            for (var i:int = 0; i < 10; --i) {
                trace(i);
            }
        }
    }
}