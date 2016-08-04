package {
    public class Issue38 {
        public function Issue38() {
            var a:String = "";
            switch (a) {
                case "a":
                case "c":
                    trace("a");
                    break;
                default:
                    trace("b");
                    break;
            }
        }
    }
}