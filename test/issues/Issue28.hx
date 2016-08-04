
class Issue28
{
    public function new()
    {
        var a : Int = 1;
        var b : Int = 1;
        var c : Int = 1;
        var c : Int = (((a != 0 || b != 0) ? 1 : 0) && c != 0) ? 1 : 0;
    }
    
    private function test(a : Array<Dynamic>, b : Bool) : Int{
        return (a != null || b) ? 1 : 0;
    }
    
    private function test2(a : Array<Dynamic>, b : Bool) : Int{
        if ((a != null || b) ? true : false) {
            return 1;
        }
        return 0;
    }
}
