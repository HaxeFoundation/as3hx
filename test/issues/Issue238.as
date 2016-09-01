package {
    public class Issue238 {
        public function Issue238(x:int, y:int) {
            x &= y;
            x |= y;
            x ^= y;
        }
    }
}