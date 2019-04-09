class Issue121 {

	public function new() {
		var o:Dynamic = {};
		if (Reflect.hasField(o, 'some')) {
			Reflect.deleteField(o, 'some');
		} else {
			o = null;
		}

		if (Reflect.hasField(o, Std.string(1))) {
			Reflect.deleteField(o, '1');
		}
	}

	private var _eventListeners:Dynamic = {};

	public function removeEventListeners(type:String = null):Void {
		if (type != null && AS3.as(_eventListeners, Bool)) {
			Reflect.deleteField(_eventListeners, type);
		} else {
			_eventListeners = null;
		}
	}

}