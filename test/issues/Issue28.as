package {
    public class Issue28 {
        public function Issue28() {
            var a:int = 1;
            var b:int = 1;
            var c:int = 1;
            var c:int = (a || b ? 1 : 0) && c ? 1 : 0;
        }
        
        private function test(a:Array, b:Boolean):int {
            return a || b ? 1 : 0;
        }
        
        private function test2(a:Array, b:Boolean):int {
            if(a || b ? true : false) {
                return 1;
            }
            return 0;
        }
    }
}