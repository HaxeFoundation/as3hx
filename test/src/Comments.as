package {
  public class Comments {
    /** Some comments in this function will be dropped **/
    public static function blah(a:String/*yeah*/="hey", f:String = "hicky", g:String = "blue"):void {
      var b:MyClass = new MyClass(
        /* comment 1 */ a,
        f, // isOk
        g
      );
      var object:Object = {
        f : /*hmm*/g, // my comment
        /* more */ i: new MyObject(),
        nocom : 3,
        tailcom : 5 // comment
      };
      // expect this one to drop
    }
  }
}

class MyClass {
  public function MyClass (a:String, f:String, g:String) {}
}

class MyObject {
}
