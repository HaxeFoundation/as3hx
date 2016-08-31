package {
    public class Issue24 {
        public function Issue24(a:int, b:int, c:int, n:Number) {
            c = a
            c = a / b;
            c = n;
            c = n - a;
            c = n + a;
            c = n * a;
            c = n << a;
            c = n >> a;
            c = n >>> a;
            c = n & a;
            c = n ^ a;
            c = n | a;
            c = ~n;
            c = n | n;
            
            var i:int = a / b;
            var j:int = n;
            var k:int = n - j;
            var k:int = n + j;
            var k:int = n * j;
            var k:int = n << j;
            var k:int = n >> j;
            var k:int = n >>> j;
            var k:int = n & j;
            var k:int = j & n;
            var k:int = n ^ j;
            var k:int = j ^ n;
            var k:int = n | j;
            var k:int = j | n;
            var n2:Number;
            var k:int = ~n2;
            
            if((n & (n - 1)) == 0) {
            }
        }
        
        public function getInt(n:Number):int {
            return n + 10;
        }
    }
}