package {
    public class Issue218 {
        public function Issue218(sub:String, sub2:Object) {
            var string:String = "She sells seashells by the seashore.";
            string = string.replace("sh", "sch");
            string = string.replace(sub, "sch");
            string = string.replace(String(sub2), "sch");
        }
    }
}