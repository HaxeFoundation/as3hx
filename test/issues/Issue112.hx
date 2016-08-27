
class Issue112
{
    public function new()
    {
        var timeoutId : Int = as3hx.Compat.setTimeout(function(s : String) : Void
                {
                }, 1000, ["string"]);
        as3hx.Compat.clearTimeout(timeoutId);
        var intervalId : Int = as3hx.Compat.setInterval(function(s : String) : Void
                {
                }, 1000, ["string"]);
        as3hx.Compat.clearInterval(intervalId);
    }
}
