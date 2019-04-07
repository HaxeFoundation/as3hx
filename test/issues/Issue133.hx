class Issue133 {

	public function new() {
		var max:Int = AS3.int(as3hx.Compat.INT_MAX);
		if (max > as3hx.Compat.INT_MAX) {
			max = AS3.int(as3hx.Compat.INT_MAX);
		}

		var min:Int = AS3.int(as3hx.Compat.INT_MIN);
		if (min < as3hx.Compat.INT_MIN) {
			min = AS3.int(as3hx.Compat.INT_MIN);
		}
	}

}