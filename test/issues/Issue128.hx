
class Issue128
{
    public function new()
    {
        var b : Bool;
        var n : Float = 1;
        if (b || (n != 0 && !Math.isNaN(n)))
        {
            trace(n);
        }
    }
}
