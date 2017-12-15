
class Issue296
{
    public function new()
    {
        var some : Int->Bool = function(i : Int) : Bool
        {
            return i < 10;
        }
        var i : Int = 0;
        while (some(i))
        {
            trace(a.pop());
            i++;
        }
    }
}
