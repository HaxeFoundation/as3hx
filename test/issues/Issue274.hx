
class Issue274
{
    public function new()
    {
        var a : Int = 1;
        var b : Int = 1;
        var c : Int = 1;
        var e : Int = 1;
        e += ((a > b || c > b)) ? 1 : 0;
    }
}
