import flash.events.Event;


class Issue64
{
    public function new()
    {
        var skeleton : Dynamic;
        var timelines : Array<Timeline>;
        var lastTime : Float;
        var time : Float;
        var events : Array<Event>;
        var i : Int = 0;
        var n : Int = timelines.length;
        while (i < n)
        {
            timelienes[i].apply(skeleton, lastTime, time, events, 1);
            i++;
        }
    }
}


class Timeline
{
    public function apply(object : Dynamic, lastTime : Float, time : Float, events : Array<Event>, number : Float) : Void
    {
    }

    public function new()
    {
    }
}