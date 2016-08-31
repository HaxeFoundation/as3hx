
class Issue24
{
    public function new(a : Int, b : Int, c : Int, n : Float)
    {
        c = a;
        c = as3hx.Compat.parseInt(a / b);
        c = as3hx.Compat.parseInt(n);
        c = as3hx.Compat.parseInt(n - a);
        c = as3hx.Compat.parseInt(n + a);
        c = as3hx.Compat.parseInt(n * a);
        c = as3hx.Compat.parseInt(n) << a;
        c = as3hx.Compat.parseInt(n) >> a;
        c = as3hx.Compat.parseInt(n) >>> a;
        c = as3hx.Compat.parseInt(n) & a;
        c = as3hx.Compat.parseInt(n) ^ a;
        c = as3hx.Compat.parseInt(n) | a;
        c = ~as3hx.Compat.parseInt(n);
        c = as3hx.Compat.parseInt(n) | as3hx.Compat.parseInt(n);
        
        var i : Int = as3hx.Compat.parseInt(a / b);
        var j : Int = as3hx.Compat.parseInt(n);
        var k : Int = as3hx.Compat.parseInt(n - j);
        var k : Int = as3hx.Compat.parseInt(n + j);
        var k : Int = as3hx.Compat.parseInt(n * j);
        var k : Int = as3hx.Compat.parseInt(n) << j;
        var k : Int = as3hx.Compat.parseInt(n) >> j;
        var k : Int = as3hx.Compat.parseInt(n) >>> j;
        var k : Int = as3hx.Compat.parseInt(n) & j;
        var k : Int = j & as3hx.Compat.parseInt(n);
        var k : Int = as3hx.Compat.parseInt(n) ^ j;
        var k : Int = j ^ as3hx.Compat.parseInt(n);
        var k : Int = as3hx.Compat.parseInt(n) | j;
        var k : Int = j | as3hx.Compat.parseInt(n);
        var n2 : Float;
        var k : Int = ~as3hx.Compat.parseInt(n2);
        
        if ((as3hx.Compat.parseInt(n) & as3hx.Compat.parseInt(n - 1)) == 0)
        {
        }
    }
    
    public function getInt(n : Float) : Int
    {
        return as3hx.Compat.parseInt(n + 10);
    }
}
