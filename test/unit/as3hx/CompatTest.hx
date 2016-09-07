package as3hx;
import as3hx.Compat;
import massive.munit.Assert;
import org.hamcrest.Matchers.*;

class CompatTest
{
    public function new() {}
    
    @Test
    public function setArrayLength() {
        var a = [1, 2, 3, 4, 5];
        Compat.setArrayLength(a, 10);
        Assert.areEqual(10, a.length);
        Compat.setArrayLength(a, 0);
        assertThat(a, isEmpty());
    }
    
    @Test
    public function arraySplice() {
        var a = [0, 1, 2, 3, 4];
        assertThat([], equalTo(Compat.arraySplice(a, 5, 0, [5, 6, 7, 8, 9])));
        assertThat([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], equalTo(a));
        assertThat([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], equalTo(Compat.arraySplice(a, 0, 10)));
        assertThat(a, isEmpty());
    }
    
    @Test
    public function getFunctionLength() {
        Assert.areEqual(0, Compat.getFunctionLength(getFunctionLength));
        Assert.areEqual(3, Compat.getFunctionLength(Assert.areEqual));
    }
    
    @Test
    public function typeof() {
        Assert.areEqual("object", Compat.typeof({}));
        Assert.areEqual("object", Compat.typeof(null));
        Assert.areEqual("number", Compat.typeof(10.1));
        Assert.areEqual("number", Compat.typeof(-1));
        Assert.areEqual("number", Compat.typeof(1));
        Assert.areEqual("string", Compat.typeof("test"));
        Assert.areEqual("boolean", Compat.typeof(true));
        Assert.areEqual("function", Compat.typeof(typeof));
    }
    
    @Test
    public function regexExec() {
        var ereg = new Regex("(\\w*)sh(\\w*)", "ig");
        var str = "She sells seashells by the seashore";
        var result = ereg.exec(str);
        assertThat(["She", "", "e"], equalTo(result));
    }
    
    @Test
    public function toFixed() {
        Assert.areEqual("7.313", Compat.toFixed(7.31343, 3));
        Assert.areEqual("4.00", Compat.toFixed(4, 2));
    }
}