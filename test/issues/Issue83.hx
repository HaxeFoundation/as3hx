class Issue83 {

	public function new() {
		var o:Dynamic = haxe.Json.parse('');
		var s:String = Std.string(haxe.Json.stringify({}));
	}

}