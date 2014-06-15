/**
 * Tests of assertions in if statements
 **/

package {

public class Ifs {

	public function single(a:Sprite) {
		if(a) {
			a.x = 15;
		}
	}

	public function singleInv(a:Sprite) {
		if(!a) {
			a = new Sprite();
		}
	}

	public function binops(a:Sprite, b:Sprite) {
		if(a && b)
			trace("We have two sprites");
		if(a || b)
			trace("We have at least one sprite");
		if(a && !b)
			trace("a is ok, b is null");
		if(!a && b)
			trace("a is null, b is ok");
	}

	public function aBool(b:Boolean) {
		// should parse to if(b)
		if(b) {
		}
		// should parse to if(!b)
		if(!b) {
		}
		// should be left alone as if(b == null)
		if(b == null) {
		}
	}

	public function maths(a:Int) {
		// should parse to if(a++ != 0)
		if(a++) {
		}
		// should parse to if(a++ == 0)
		if(!a++) {
		}
		// should parse to if(++a++ != 0)
		if(++a++) {
		}
		// should parse to if(++a++ == 0)
		if(!++a++) {
		}
	}
}

}