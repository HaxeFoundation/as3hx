
class Issue296
{
    public function new()
    {
        var a : Array<Dynamic> = [1, 2, 3];
        var i : Int = 0;
        while (i < a.length)
        {
            trace(a.pop());
            i++;
        }
        var i : Int = 0;
        while (i < a.pop())
        {
            trace(i);
            i++;
        }
        var i : Int = 0;
        while (i < a.pop() + 10)
        {
            trace(i);
            i++;
        }
        var i : Int = 0;
        while (i < a.length)
        {
            if (i < 3)
            {
                trace(a.pop());
            }
            else
            {
                i++;
                continue;
            }
            i++;
        }
        var i : Int = 0;
        while (i < a.length)
        {
            trace(a.pop());
            i++;
            continue;
        }
    }
}
