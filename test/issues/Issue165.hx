
class Issue165
{
    public function new()
    {
        var a : Array<Dynamic> = [];
        var b : Array<Dynamic> = a.splice(0, a.length);
        var c : Array<Dynamic> = as3hx.Compat.arraySplice(a, 0, 0, [1, 2, 3, 4, 5]);
        var d : Array<Dynamic> = a.splice(0, 1);
    }
}
