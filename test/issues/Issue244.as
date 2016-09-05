package {
    public class Issue244 {
        public function Issue244(c:Object) {
            var a:Object = {};
            var b:Object = a[10] ||= new Object;
            c = a[10] ||= new Object;
        }
    }
}