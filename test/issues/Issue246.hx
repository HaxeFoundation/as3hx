
class Issue246
{
    public var steps(never, set) : Int;

    public function new()
    {
    }
    
    private var _steps : Int = 8;
    private function set_steps(val : Int) : Int
    {
        if (_steps == val)
        {
            return val;
        }
        return val;
    }
}
