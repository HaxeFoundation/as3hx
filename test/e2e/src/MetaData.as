package {

[Event(name="resize", type="flash.events.Event")]
[Event(name="draw", type="flash.events.Event")]
[IconFile("Tree.png")]
[RequiresDataBinding(true)]

public class MetaData {

	public function MetaData() {
	}

	[Bindable("move")]
	public function set y(value:Number):void
	{
			super.y = 0;
	}
}

}


