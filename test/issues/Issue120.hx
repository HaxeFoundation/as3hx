import haxe.Constraints.Function;

class Issue120
{
    public function new()
    {
        var call : Function = trace;
        var args : Array<Dynamic> = [];
        Reflect.callMethod(null, call, args);
        Reflect.callMethod(null, call, [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
    }
}
