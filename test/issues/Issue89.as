package {
    public class Issue89 {
        public function Issue89() {
            var n:Number = getNaN();
            var v:Number = NaN;
        }
        
        private var n:Number = NaN;
        
        private function getNaN():Number {
            return NaN;
        }
    }
}