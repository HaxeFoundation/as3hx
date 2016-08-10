package {
    public class Issue139 {
        public function Issue139() {
            var max:Number = Number.MAX_VALUE;
            if (max > Number.MAX_VALUE) {
                max = Number.MAX_VALUE;
            }
            
            var min:Number = Number.MIN_VALUE;
            if (min < Number.MIN_VALUE) {
                min = Number.MIN_VALUE;
            }
        }
    }
}