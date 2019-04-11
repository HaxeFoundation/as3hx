class Issue246 {

	public function new() {}

	private var _steps:Int = 8;

	public var steps(never, set):Int;
	private function set_steps(val:Int):Int {
		if (_steps == val) {
			return val;
		}
		return val;
	}

}