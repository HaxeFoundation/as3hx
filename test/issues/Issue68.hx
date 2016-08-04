
class Issue68
{
    public function new()
    {
        var a : Array<Dynamic> = [];
        var b : Array<Dynamic> = a.copy();
        var c : Array<Dynamic> = a.slice(0, 1);
        var d : Array<Int> = [];
        var e : Array<Int> = d.copy();
        var f : Array<Int> = d.slice(0, 1);
    }
}
