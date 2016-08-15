import flash.utils.ByteArray;

class Issue63
{
    public function new()
    {
        var a : Array<Float> = new Array<Float>();
        as3hx.Compat.setArrayLength(a, 10);
        var bytes : ByteArray = new ByteArray();
        bytes.length = 0;
    }
}
