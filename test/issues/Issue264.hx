import flash.errors.Error;

class Issue264 {

	public function new() {
		var obj:Dynamic = {};
		var message:String;

		// error inside
		if (Std.is(Reflect.field(obj, 'error'), Error)) {
			message = AS3.string(Reflect.field(Reflect.field(obj, 'error'), 'message'));
		}// error event inside
		else if (Std.is(Reflect.field(obj, 'error'), ErrorEvent)) {
			message = AS3.string(Reflect.field(Reflect.field(obj, 'error'), 'text'));
		}// unknown
		else {
			message = Std.string(Std.string(Reflect.field(obj, 'error')));
		}

	}

}