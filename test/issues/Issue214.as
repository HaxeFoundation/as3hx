package {
    public class Issue214 {
        public function Issue214() {
        }
        
        public function set test(v:Boolean):void {
            if(!v) return;
            trace(v);
        }
    }
}