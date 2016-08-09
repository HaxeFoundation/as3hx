
import flash.system.Capabilities;
class Issue119
{
    public function new()
    {
        var sPlatform : String = Capabilities.version.substr(0, 3);
        var sDesktop : Bool = new as3hx.compat.FlashRegExp('(WIN|MAC|LNX)', '').exec(sPlatform) != null;
    }
}
