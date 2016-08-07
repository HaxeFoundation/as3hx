package {
    public class Issue70 {
        public function Issue70(i:int = 10, ...args:Array):void {
            trace(args);
        }
        
        private function test(...args):void {
            trace(args);
        }
    }
}