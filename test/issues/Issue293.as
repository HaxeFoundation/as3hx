package {
    import flash.utils.setTimeout;
    public class Issue293 {
        public function Issue293() {
            var i:int = setTimeout(function(...args) {
                trace(args);
            }, (1 + 1) * 1000, 1, 2, 3);
        }
    }
}