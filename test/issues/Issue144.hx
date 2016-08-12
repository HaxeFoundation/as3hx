import flash.events.TouchEvent;

class Issue144
{
    private var multitouchEnabled : Bool;
    private var types : Array<String> = [];
    public function new()
    {
        if (multitouchEnabled)
        {
            types.push(TouchEvent.TOUCH_BEGIN);
            types.push(TouchEvent.TOUCH_MOVE);
            types.push(TouchEvent.TOUCH_END);
            
        }
    }
}
