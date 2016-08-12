import flash.system.Capabilities;

class Issue119
{
    public function new()
    {
        var sPlatform : String = Capabilities.version.substr(0, 3);
        var sDesktop : Bool = new flash.utils.RegExp('(WIN|MAC|LNX)', "").exec(sPlatform) != null;
        
        var ereg : flash.utils.RegExp = new flash.utils.RegExp('(WIN|MAC|LNX)', "");
        var sDesktop2 : Bool = ereg.exec(sPlatform) != null;
    }
}
