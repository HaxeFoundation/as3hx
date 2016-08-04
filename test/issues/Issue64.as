package {
    import flash.events.Event;
    public class Issue64 {
        public function Issue64() {
            var skeleton:Object;
            var timelines:Vector.<Timeline>;
            var lastTime:Number;
            var time:Number;
            var events:Vector.<Event>;
            for (var i:int = 0, n:int = timelines.length; i < n; i++) {
                timelienes[i].apply(skeleton, lastTime, time, events, 1);
            }
        }
    }
}

import flash.events.Event;
class Timeline {
    public function apply(object:Object, lastTime:Number, time:Number, events:Vector.<Event>, number:Number):void {
    }
}