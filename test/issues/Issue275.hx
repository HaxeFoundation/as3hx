
class Issue275
{
    public function new()
    {
        var a : Int = 1;
        var b : Int = 1;
        var c : Int = 1;
        var d : Int = 1;
        d += (a > b || c != 0) ? 1 : 0;
    }
}
