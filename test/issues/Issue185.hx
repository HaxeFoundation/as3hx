
class Issue185
{
    public function new()
    {
        var a : Array<Dynamic> = [1];
        var i : Int = as3hx.Compat.parseInt(a.splice(0, 1)[0]);
        a.splice(1, 1)[0];
    }
}
