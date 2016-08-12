package test {
    import flash.events.EventDispatcher;
    
    /** Dispatched when a fatal error is encountered. The 'data' property contains an error string. */
    [Event(name="fatalError", type="starling.events.Event")]
    
    public class Issue156 extends EventDispatcher {
        public function Issue156() {
            
        }
    }
}

import flash.display.Sprite;
class PrivateClass extends Sprite {
}