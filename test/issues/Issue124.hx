import flash.utils.Dictionary;

class Issue124
{
    private var _eventListeners : Dictionary = new Dictionary();
    public function removeEventListeners(type : String = null) : Void
    {
        if (type != null && _eventListeners != null)
        {
            This is an intentional compilation error. See the README for handling the delete keyword
            delete _eventListeners[type];
        }
        else
        {
            _eventListeners = null;
        }
    }

    public function new()
    {
    }
}
