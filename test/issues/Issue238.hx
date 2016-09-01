
class Issue238
{
    public function new(x : Int, y : Int)
    {
        x = x & y;
        x = x | y;
        x = x ^ y;
    }
}
