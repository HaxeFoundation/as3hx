package {
    public class Issue133 {
        public function Issue133() {
            var max:int = int.MAX_VALUE;
            if (max > int.MAX_VALUE) {
                max = int.MAX_VALUE;
            }
            
            var min:int = int.MIN_VALUE;
            if (min < int.MIN_VALUE) {
                min = int.MIN_VALUE;
            }
        }
    }
}