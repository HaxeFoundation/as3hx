package {
    public class Issue87 {
        public function Issue87() {
            cast("");
            new PrivateClass().cast("");
            var cast:int = int(10.0);
        }
        
        private var cast:int = int(10.0);
        
        private function cast(o:Object):String {
            return String(o);
        }
    }
}

class PrivateClass {
    public function PrivateClass(cast:int) {
        super();
    }
    
    public function cast(o:Object):String {
        return String(o);
    }
}