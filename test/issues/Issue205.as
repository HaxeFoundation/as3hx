package {
    public class Issue205 {
        public function Issue205() {
            var f:Function = test;
            if(f.length == 1) {
                f(1);
            }
        }
        
        private function test(s:String):void {
            trace(s);
        }
    }
}