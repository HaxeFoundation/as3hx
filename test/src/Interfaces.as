package {

	public interface A {
        var x : Int;
	}

	public interface B {
        function joy() : Void;
	}

	public interface C extends A, B {
        function duh() : Void;
	}
}
