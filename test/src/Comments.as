package {
	public class Comments {
		/** Some comments in this function will be dropped **/
		public static function blah(a:string/*yeah*/="hey") {
			var b = new MyClass(
				/* comment 1 */ a,
				f, // isOk
				g
			);
			var object = {
				f : /*hmm*/g, // my comment
				/* more */ i: new MyObject(),
				nocom : 3,
				tailcom : 5 // comment
			};
			// expect this one to drop
		}
	}
}
