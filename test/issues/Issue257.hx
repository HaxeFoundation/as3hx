import flash.net.URLRequest;

class Issue257
{
    public function new()
    {
        var req : URLRequest = new URLRequest("http://www.adobe.com/");
        flash.Lib.getURL(req, "_blank");
    }
}
