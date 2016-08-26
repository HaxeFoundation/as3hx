import haxe.Constraints.Function;

class Issue176
{
    public function new()
    {
        var call : Function = trace;
        Reflect.callMethod(null, call, [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
    }
}
