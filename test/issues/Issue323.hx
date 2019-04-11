class Issue323 {

	private var friendsList:Array<Dynamic>;

	public function new() {
		for (i in 0...friendsList.length) {
			if (AS3.as(Reflect.field(friendsList[i], 'bSelected'), Bool)) {
			}
		}
	}

}