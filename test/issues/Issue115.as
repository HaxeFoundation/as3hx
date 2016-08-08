package {
    public class Issue115 {
        public function Issue115() {
            if(true) var i:int = 1;
            
            if(true)
                var i:int = 1;
            
            if(true) var i:int = 1;
            else var i:int = 1;
            
            if(true) var i:int = 1;
            else
                var i:int = 1;
            
            if(true) var i:int = 1;
            else
            {
                var i:int = 1;
            }
        }
    }
}