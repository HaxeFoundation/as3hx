
class Issue29
{
    public function new()
    {
        var stuff : Array<Dynamic> = [];
        var i : Int = 0;
        while (i < 10 || stuff[i] != null)
        {
            trace(i);
            i++;
        }
    }
}
