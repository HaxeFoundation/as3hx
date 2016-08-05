package {
    import flash.utils.clearInterval;
    import flash.utils.clearTimeout;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;
    public class Issue112 {
        public function Issue112() {
            var timeoutId:uint = setTimeout(function(s:String):void {}, 1000, "string");
            clearTimeout(timeoutId);
            var intervalId:uint = setInterval(function(s:String):void{}, 1000, "string");
            clearInterval(intervalId);
        }
    }
}