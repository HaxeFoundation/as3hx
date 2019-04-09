class Issue87 {

	public function new() {
		__DOLLAR__cast('');
		new PrivateClass().__DOLLAR__cast('');
		var __DOLLAR__cast:Int = AS3.int(10.0);
	}

	private var __DOLLAR__cast:Int = AS3.int(10.0);

	private function __DOLLAR__cast(o:Dynamic):String {
		return Std.string(o);
	}

}

class PrivateClass {

	public function new(__DOLLAR__cast:Int) {

	}

	public function __DOLLAR__cast(o:Dynamic):String {
		return Std.string(o);
	}

}