
class Issue261
{
    public function new()
    {
        var a : Array<Dynamic> = [{ }];
        Reflect.setField(a[a.length - 1], "some", 10);
    }
}
