package {
    public class Issue244 {
        public function Issue244() {
            var a:Object = {};
            var b:Object = a[10] ||= new Object;
        }
    }
}