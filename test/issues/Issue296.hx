class Issue296 {

	public function new() {
		var a:Array<Int> = [1, 2, 3];
		for (i in 0...a.length) {
			trace(a.pop());
		}
		for (i in 0...a.pop()) {
			trace(i);
		}
		for (i in 0...a.pop() + 10) {
			trace(i);
		}
		for (i in 0...a.length) {
			if (i < 3) {
				trace(a.pop());
			} else {
				continue;
			}
		}
		for (i in 0...a.length) {
			trace(a.pop());
			continue;
		}
	}

}