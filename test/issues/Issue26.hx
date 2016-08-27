
class Issue26
{

    public function new()
    {
    }
}


class Foo
{
    @:allow()
    private function foo() : Void
    {
    }
    
    private function some() : Void
    {
    }

    public function new()
    {
    }
}

class Bar extends Foo
{
    @:allow()
    override private function foo() : Void
    {
        super.foo();
    }
    
    override private function some() : Void
    {
        super.some();
    }

    public function new()
    {
        super();
    }
}