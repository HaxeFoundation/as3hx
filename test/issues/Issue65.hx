
class Issue65
{
    public function new()
    {
        var array : Array<Dynamic>;
        var i : Int = 0;
        while (i < array.length)
        {
            var current : Dynamic = array[i];
            if (current == null)
            {
                i++;
                continue;
            }
            i++;
        }
    }
}
