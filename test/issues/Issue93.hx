
class Issue93
{
    public function new()
    {
        trace([1, 2, 3, 4, 5, 6, 7, 8, 9, 0].join(","));
        var a : Array<Dynamic> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
        trace(a.join(","));
    }
}
