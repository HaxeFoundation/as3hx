class Issue66 {

	public function new() {
		var a:Int = AS3.int(1);
		var b:Int = AS3.int(AS3.int(10.5));
		var c:Int = AS3.int(AS3.int(a / b));
		var b:Float;
		var d:Int = AS3.int(AS3.int(b));
	}

}