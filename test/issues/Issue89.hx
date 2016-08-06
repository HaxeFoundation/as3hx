
class Issue89
{
    public function new()
    {
        var n : Float = getNaN();
        var v : Float = Math.NaN;
    }
    
    private var n : Float = Math.NaN;
    
    private function getNaN() : Float
    {
        return Math.NaN;
    }
}
