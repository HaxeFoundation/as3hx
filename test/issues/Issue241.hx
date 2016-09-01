
class Issue241
{
    public function new()
    {
        var d : haxe.ds.ObjectMap<Dynamic, Dynamic> = new haxe.ds.ObjectMap<Dynamic, Dynamic>();
        trace(Std.is(d, haxe.ds.ObjectMap));
    }
}
