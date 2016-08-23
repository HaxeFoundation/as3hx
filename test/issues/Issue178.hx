
class Issue178
{
    public function new()
    {
        var i : Int = 0;
        while (i < 10)
        {
            trace(i);
            i += 1;
        }
        for (i in 0...10)
        {
            trace(i);
        }
        for (i in 0...10)
        {
            trace(i);
        }
        var i : Int = 0;
        while (i < 10)
        {
            trace(i);
            i--;
        }
        var i : Int = 0;
        while (i < 10)
        {
            trace(i);
            --i;
        }
    }
}
