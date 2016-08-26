package {
    public class Issue66 {
        public function Issue66() {
            var a:int = (int)(1);
            var b:int = (int)(10.5);
            var c:int = (int)(a / b);
            var b:Number;
            var d:int = (int)(b);
        }
    }
}