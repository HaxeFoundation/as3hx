class Issue185 {

	public function new() {
		var a:Array<Int> = [1];
		var i:Int = AS3.int(a.splice(0, 1)[0]);
		a.splice(1, 1)[0];
	}

}