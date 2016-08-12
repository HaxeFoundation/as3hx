import flash.system.Capabilities;

class Issue119
{
    public function new()
    {
        var sPlatform : String = Capabilities.version.substr(0, 3);
        var sDesktop : Bool = new as3hx.Compat.Regex('(WIN|MAC|LNX)', "").exec(sPlatform) != null;
        
        var ereg : as3hx.Compat.Regex = new as3hx.Compat.Regex('(WIN|MAC|LNX)', "");
        var sDesktop2 : Bool = ereg.exec(sPlatform) != null;
    }
}
