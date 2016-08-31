
class Issue226
{
    public function new()
    {
        var dictionary : haxe.ds.ObjectMap<Dynamic, Dynamic> = new haxe.ds.ObjectMap<Dynamic, Dynamic>();
        dictionary.set("key", true);
        dictionary.remove("key");
    }
}
