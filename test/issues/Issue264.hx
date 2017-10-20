
class Issue264
{
    public function new()
    {
        var obj : Dynamic = {};
        var message : String;
        
        // error inside
        if (Std.is(obj.error, Error))
        {
            message = obj.error.message;
        }
        // error event inside
        else if (Std.is(obj.error, ErrorEvent))
        {
            message = obj.error.text;
        }
        // unknown
        else
        {
            message = Std.string(obj.error);
        }
    }
}
