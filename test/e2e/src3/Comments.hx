/**
Package Comment
**/

/**
 * Class Comment
 **/
class Comments {

	/** Function comment **/
	public static function blah():Void {
		var a:Int = 1;// line comment
	}

	/** Second **/
	public function memberFunc() {}

	private var i(get, set):Dynamic;
	private function get_i():Dynamic {
		return _i;
	}

	private function set_i(v:Dynamic):Dynamic {
		_i = v;
		return v;
	}

	private var j(get, set):Int;
	private function get_j():Int {
		return AS3.int(_j);
	}

	private function set_j(v:Int):Int {
		_i = v;
		return v;
	}

	public function new() {}

}

/**
 * Trailing package comment
 **/