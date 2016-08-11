
class Issue71
{
    public function new()
    {
        __DOLLAR__test({ });
        var __DOLLAR__localVar : Dynamic = {
            __DOLLAR__key : "value"
        };
    }
    
    private var __DOLLAR__name : String;
    
    private function __DOLLAR__test(__DOLLAR__param : Dynamic) : Void
    {
        trace(__DOLLAR__param);
        trace(__DOLLAR__name);
    }
}
