package {
    public class Issue215 {
        private static const regex:RegExp = /sh/gi;
        public function Issue215(string2:String) {
            var string:String = "She sells seashells by the seashore.";
            string = string.replace(regex, "sch");
            string = string2.replace(regex, "sch");
        }
    }
}