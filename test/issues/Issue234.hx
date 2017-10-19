import flash.display3D.Context3D;

class Issue234
{
    public function new()
    {
        var supportsVideoTexture : Bool = Reflect.field(Context3D, "supportsVideoTexture");
    }
}
