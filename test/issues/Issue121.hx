
class Issue121
{
    public function new()
    {
        var o : Dynamic = { };
        if (Lambda.has(o, "some"))
        {
            Reflect.deleteField(o, "some");
        }
        else
        {
            o = null;
        }
        
        if (Lambda.has(o, 1))
        {
            Reflect.deleteField(o, "1");
        }
    }
    
    private var _eventListeners : Dynamic = { };
    public function removeEventListeners(type : String = null) : Void
    {
        if (type != null && _eventListeners != null)
        {
            Reflect.deleteField(_eventListeners, type);
        }
        else
        {
            _eventListeners = null;
        }
    }
}
