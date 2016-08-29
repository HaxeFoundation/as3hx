import flash.errors.Error;

class Issue208
{
    public function new()
    {
        try
        {
            var s : String = "";
        }
        catch (e : Error)
        {
            trace(e);
        }
        
        try
        {
            var s : String = "";
        }
        catch (e : Error)
        {
        }
        
        try
        {
            var s : String = "";
        }
        catch (e : Error)
        {
        }
    }
}
