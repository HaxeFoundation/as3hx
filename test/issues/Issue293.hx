
class Issue293
{
    public function new()
    {
        var i : Int = as3hx.Compat.setTimeout(function(args : Array<Dynamic> = null)
                {
                    trace(args);
                }, (1 + 1) * 1000, [1, 2, 3]);
    }
}
