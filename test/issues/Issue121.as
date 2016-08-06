package {
    public class Issue121 {
        public function Issue121() {
            var o:Object = {};
            if ("some" in o)
                delete o["some"];
            else
                o = null;
                
            if (1 in o) delete o[1];
        }
        
        private var _eventListeners:Object = {};
        public function removeEventListeners(type:String=null):void {
            if (type && _eventListeners)
                delete _eventListeners[type];
            else
                _eventListeners = null;
        }
    }
}