package {
    import flash.system.Capabilities;
    public class Issue119 {
        public function Issue119() {
            var sPlatform:String = Capabilities.version.substr(0, 3);
            var sDesktop:Boolean = /(WIN|MAC|LNX)/.exec(sPlatform) != null;
        }
    }
}