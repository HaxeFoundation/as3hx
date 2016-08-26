import haxe.Constraints.Function;

class Issue192
{
    public function new()
    {
        var f : Function = test;
        test(s);
    }
    
    private function test(s : String)
    {
        trace(s);
    }
}
