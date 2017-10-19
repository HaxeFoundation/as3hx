as3 code for example:
```actionscript
package {
    public class Issue {
        public function Issue() {
            //code here...
        }
    }
}
```
expected result
```haxe

class Issue
{
    public function new()
    {
        //code here...
    }
}

```
actual result
```haxe

class Issue
{
    public function new()
    {
        //code here...
    }
}

```
