class Issue214 {

	public function new() {}

	public var test(never, set):Bool;
	private function set_test(v:Bool):Bool {
		if (!v) {
			return v;
		}
		trace(v);
		return v;
	}

}