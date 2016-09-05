package {
    public class Issue246 {
        public function Issue246() {
        }
        
        private var _steps:uint = 8;
        public function set steps(val:uint):void
        {
            if (_steps == val)
                return;
        }
    }
}