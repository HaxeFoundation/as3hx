
class Issue218
{
    public function new(sub : String, sub2 : Dynamic)
    {
        var string : String = "She sells seashells by the seashore.";
        string = StringTools.replace(string, "sh", "sch");
        string = StringTools.replace(string, sub, "sch");
        string = StringTools.replace(string, Std.string(sub2), "sch");
    }
}
