class Issue65 {

	public function new() {
		var array:Array<Dynamic>;
		for (i in 0...array.length) {
			var current:Dynamic = array[i];
			if (!AS3.as(current, Bool)) {
				continue;
			}
		}
	}

}