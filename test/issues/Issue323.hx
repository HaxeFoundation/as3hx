
class Issue323
{
    private var friendsList : Array<Dynamic>;
    public function new()
    {
        var i : Int = 0;
        while (i < friendsList.length)
        {
            if (friendsList[i].bSelected)
            {
                true;
            }
            i++;
        }
    }
}
