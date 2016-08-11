package {
    public class Issue15 {
        
        public function Issue15() {
            var i:int = 0;
            if(i) {
                trace(i);
            }
            ++i;
            
            if(true) trace("");
            else {
                trace("");
            }
            ++i;
            
            for (var j:int = 0; j < 10; j++) {
                trace("");
            }
            ++i;
            
            for (var j:int = 0; j < 10; j++)
            {
                trace("");
            }
            ++i;
            
            for (var name:String in {}) {
                trace("");
            }
            ++i;
            
            for (var name:String in {})
            {
                trace("");
            }
            ++i;
            
            for each (var item:* in {}) {
                trace("");
            }
            ++i;
            
            for each (var item:* in {})
            {
                trace("");
            }
            ++i;
            
            while (true) {
                trace("");
            }
            ++i;
            
            while (true)
            {
                trace("");
            }
            ++i;
            
            do {
                trace("")
            } while (true);
            ++i;
            
            do
            {
                trace("")
            } while (true);
            ++i;
            
            do
            {
                trace("")
            }
            while (true);
            ++i;
            
            switch (i) {
                case 1:
                    trace("");
                    break;
                default:
            }
            ++i;
            
            switch (i)
            {
                case 1:
                    trace("");
                    break;
                default:
            }
            ++i;
        }
    }
}