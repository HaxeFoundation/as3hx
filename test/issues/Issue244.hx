
class Issue244
{
    public function new(c : Dynamic)
    {
        var a : Dynamic = { };
        if (Reflect.field(a, Std.string(10)) == null) {
            Reflect.setField(a, Std.string(10), {});
        }
        var b : Dynamic = Reflect.field(a, Std.string(10));
        if (Reflect.field(a, Std.string(10)) == null) {
            Reflect.setField(a, Std.string(10), {});
        }
        c = Reflect.field(a, Std.string(10));
    }
}
