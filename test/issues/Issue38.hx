class Issue38 {

	public function new() {
		var a:String = '';
		switch (a) {
			case 'a', 'c':
				trace('a');
			case _:
				trace('b');
		}
	}

}