import flash.display.DisplayObject;

class Issue164
{
    public function new(rootClass : Class<Dynamic>)
    {
        var d : DisplayObject = try cast(Type.createInstance(rootClass, []), DisplayObject) catch(e:Dynamic) null;
    }
}
