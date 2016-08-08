package {
    public class Issue134 {
        public function Issue134() { throw new Error(); }
        
        private function test():void {trace("Issue134"); }
        
        private function test2():void { for (var i:int = 0; i < 10; i++) {trace("Issue134"); } }
    }
}