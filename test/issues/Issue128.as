package {
    public class Issue128 {
        public function Issue128() {
            var b:Boolean;
            var n:Number = 1;
            if (b || n) {
                trace(n);
            }
        }
    }
}