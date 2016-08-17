import flash.geom.Point;

class Issue167
{
    public function new(p : Point = null)
    {
        p = (p != null) ? p : new Point();
        
        var n : Float;
        n = ((n != 0 && !Math.isNaN(n))) ? n : 1;
        
        var i : Int;
        i = (i != 0) ? i : 1;
        
        var s : String;
        s = (s != null) ? s : "string";
        
        var b : Bool;
        b = (b) ? b : true;
    }
}
