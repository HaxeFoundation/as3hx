package {
    public class Issue296 {
        public function Issue296() {
            var a:Array = [1, 2, 3];
            for(var i:int = 0; i < a.length; i++) {
                trace(a.pop());
            }
            for(var i:int = 0; i < a.pop(); i++) {
                trace(i);
            }
            for(var i:int = 0; i < a.pop() + 10; i++) {
                trace(i);
            }
            for(var i:int = 0; i < a.length; i++) {
                if(i < 3) trace(a.pop());
                else continue;
            }
            for(var i:int = 0; i < a.length; i++) {
                trace(a.pop());
                continue;
            }
        }
    }
}