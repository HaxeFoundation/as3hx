
class Issue202
{
    public function new()
    {
        var string : String = "She sells seashells by the seashore.";
        string = new as3hx.Compat.Regex('sh', "gi").replace(string, "sch");
        trace(string);
    }
}
