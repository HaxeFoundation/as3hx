class Issue124 {

	private var _eventListeners:haxe.ds.ObjectMap<Dynamic, Dynamic> = new haxe.ds.ObjectMap<Dynamic, Dynamic>();

	public function removeEventListeners(type:String = null):Void {
		if (type != null && _eventListeners != null) {
			_eventListeners.remove(type);
		} else {
			_eventListeners = null;
		}
	}

	public function new() {}

}