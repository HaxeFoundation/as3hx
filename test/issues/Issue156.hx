package test;

import flash.events.EventDispatcher;
import flash.display.Sprite;

/** Dispatched when a fatal error is encountered. The 'data' property contains an error string. */
@:meta(Event(name="fatalError",type="starling.events.Event"))

class Issue156 extends EventDispatcher
{
    public function new()
    {
        super();
    }
}


class PrivateClass extends Sprite
{

    public function new()
    {
        super();
    }
}