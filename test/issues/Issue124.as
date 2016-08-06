package {
    import flash.utils.Dictionary;
    public class Issue124 {
        private var _eventListeners:Dictionary = new Dictionary();
        public function removeEventListeners(type:String = null):void
        {
            if (type && _eventListeners)
            {
                delete _eventListeners[type];
            }
            else
                _eventListeners = null;
        }
    }
}