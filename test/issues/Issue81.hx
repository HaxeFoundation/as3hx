import flash.system.Security;

class Issue81
{

    public function new()
    {
    }
    private static var init = {
        Security.allowDomain("*");
    }

}
