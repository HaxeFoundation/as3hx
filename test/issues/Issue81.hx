import flash.system.Security;

class Issue81
{

    public function new()
    {
    }
    private static var Issue81_static_initializer = {
        Security.allowDomain("*");
        true;
    }

}
