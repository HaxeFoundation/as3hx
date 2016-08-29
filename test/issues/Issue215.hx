
class Issue215
{
    private static var regex : as3hx.Compat.Regex = new as3hx.Compat.Regex('sh', "gi");
    public function new(string2 : String)
    {
        var string : String = "She sells seashells by the seashore.";
        string = regex.replace(string, "sch");
        string = regex.replace(string2, "sch");
    }
}
