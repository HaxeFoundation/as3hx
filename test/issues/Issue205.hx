import haxe.Constraints.Function;

class Issue205
{
    public function new()
    {
        var f : Function = test;
        if (as3hx.Compat.getFunctionLength(f) == 1)
        {
            f(1);
        }
    }
    
    private function test(s : String) : Void
    {
        trace(s);
    }
}
