
class Issue32
{
    public function new()
    {
        var a : Array<Dynamic> = [];
        var b : Array<Dynamic> = a.copy();
        var c : Array<Dynamic> = a.concat([1, 2, 3, 4]);
        var d : Array<Int> = [];
        var e : Array<Int> = d.copy();
        var f : Array<Int> = d.concat([1, 2, 3, 4]);
    }
}
