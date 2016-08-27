package {
    public class Issue24 {
        
        public function Issue24(a:int, b:int, c:int, n:Number) {
            c = a
            c = a / b;
            c = n;
            c = n - a;
            c = n + a;
            c = n * a;
            
            var i:int = a / b;
            var j:int = n;
            var k:int = n - j;
            var k:int = n + j;
            var k:int = n * j;
        }
    }
}