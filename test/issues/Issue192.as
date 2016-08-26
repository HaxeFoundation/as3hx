package {
    public class Issue192 {
        public function Issue192() {
            var f:Function = test;
            test(s);
        }
        
        private function test(s:String) {
            trace(s);
        }
    }
}