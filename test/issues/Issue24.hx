class Issue24 {

	public function new(a:Int, b:Int, c:Int, n:Float) {
		c = a;
		c = AS3.int(a / b);
		c = AS3.int(n);
		c = AS3.int(n - a);
		c = AS3.int(n + a);
		c = AS3.int(n * a);
		c = AS3.int(n) << a;
		c = AS3.int(n) >> a;
		c = AS3.int(n) >>> a;
		c = AS3.int(n) & a;
		c = AS3.int(n) ^ a;
		c = AS3.int(n) | a;
		c = ~AS3.int(n);
		c = AS3.int(n) | AS3.int(n);

		var i:Int = AS3.int(a / b);
		var j:Int = AS3.int(n);
		var k:Int = AS3.int(n - j);
		var k:Int = AS3.int(n + j);
		var k:Int = AS3.int(n * j);
		var k:Int = AS3.int(n << j);
		var k:Int = AS3.int(n >> j);
		var k:Int = AS3.int(n >>> j);
		var k:Int = AS3.int(AS3.int(n) & j);
		var k:Int = AS3.int(j & AS3.int(n));
		var k:Int = AS3.int(n ^ j);
		var k:Int = AS3.int(j ^ n);
		var k:Int = AS3.int(n | j);
		var k:Int = AS3.int(j | n);
		var n2:Float;
		var k:Int = AS3.int(~n2);

		if ((AS3.int(n) & AS3.int(n - 1)) == 0) {}
	}

	public function getInt(n:Float):Int {
		return AS3.int(n + 10);
	}

}