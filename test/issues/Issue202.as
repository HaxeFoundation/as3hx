package {
    public class Issue202 {
        public function Issue202() {
            var string:String = "She sells seashells by the seashore.";
            string = string.replace(/sh/gi, "sch");
            trace(string);
        }
    }
}