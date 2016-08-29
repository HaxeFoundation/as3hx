package {
    public class Issue208 {
        public function Issue208() {
            try {var s:String = ""}
            catch(e:Error) { trace(e); }
            
            try {
                var s:String = "";
            } catch(e:Error) {}
            
            try {
                var s:String = "";
            }
            catch(e:Error)
            {
                
            }
        }
    }
}