package {
    public class Issue261 {
        public function Issue261() {
            var a:Array = [{}];
            a[a.length - 1]["some"] = 10;
        }
    }
}