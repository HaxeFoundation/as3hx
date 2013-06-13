package {

public class GetterSetter {
	final function get $visible():Boolean
	{
		return super.visible;
	}
	final function set $visible(value:Boolean):void
	{
		super.visible = value;
	}

	public static function tests() {
            $visible = true;
	    var newValue = false;
	    if (newValue != $visible)
		    $visible = newValue;

	    $addChildAt();
	}

	function $addChildAt():Void { }
}
}
