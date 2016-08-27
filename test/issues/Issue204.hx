import haxe.Constraints.Function;

class Issue204
{
    public function new()
    {
        var i : Int;
        var j : Int;
        var test : Int->Float->Void = function(i : Int, n : Float) : Void
        {
            trace(i + n);
        }
        var f : Function = function() : Void
        {
        }
        var i : Int = 10;
        var n : Float = 0.1;
        test(i, n);
    }
}


