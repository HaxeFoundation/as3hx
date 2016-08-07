package {
    public class Issue26 {
    }
}

class Foo {
    internal function foo():void {}
    
    protected function some():void {};
}

class Bar extends Foo {
    override internal function foo():void {
        super.foo();
    }
    
    override protected function some():void {
        super.some();
    }
}