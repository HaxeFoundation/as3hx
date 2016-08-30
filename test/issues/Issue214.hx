
class Issue214
{
    public var test(never, set) : Bool;

    public function new()
    {
    }
    
    private function set_test(v : Bool) : Bool
    {
        if (!v)
        {
            return v;
        }
        trace(v);
        return v;
    }
}
