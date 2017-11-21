
class Issue314
{
    public function new()
    {
    }
    public function hide1(param1 : Dynamic) : Dynamic
    {
        Reflect.setField(this, Std.string(param1), false);
        Reflect.field(this, Std.string(param1)).visible = false;
    }
    public function hide2(param1 : Dynamic) : Dynamic
    {
        Reflect.setField(this, Std.string(param1), "nothing");
        Reflect.field(this, Std.string(param1)).collision.currentObject = "nothing";
    }
}
