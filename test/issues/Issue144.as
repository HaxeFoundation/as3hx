package {
    import flash.events.TouchEvent;
    public class Issue144 {
        private var multitouchEnabled:Boolean;
        private var types:Vector.<String> = new <String>[];
        public function Issue144() {
            if (multitouchEnabled)
                types.push(TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END);
        }
    }
}