import flash.errors.Error;

class Issue134
{
    public function new()
    {
        throw new Error();
    }
    
    private function test() : Void
    {
        trace("Issue134");
    }
    
    private function test2() : Void
    {
        for (i in 0...10)
        {
            trace("Issue134");
        }
    }
}
