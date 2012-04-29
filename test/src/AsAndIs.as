package {
	public class AsAndIs {
		private var _icon:DisplayObject;
		private var _bg:DisplayObject;
		private var _iconHolder:DisplayObject;
		private var _iconRadius:Number;
		private var _arc:Number;
		public function setIcon(iconOrLabel:Object):int
		{
			if(iconOrLabel is Class)
			{
				_icon = new (iconOrLabel as Class)() as DisplayObject;
			}
			else if(iconOrLabel is DisplayObject)
			{
				_icon = iconOrLabel as DisplayObject;
			}
			else if(iconOrLabel is String)
			{
				_icon = new Label(null, 0, 0, iconOrLabel as String) as DisplayObject;
				(_icon as Label).draw();
				// TODO: put mx.geom.Transform in its own file/package
				//(_icon as mx.geom.Transform).rotate();
			}
			if(_icon != null)
			{
				var angle:Number = _bg.rotation * Math.PI / 180;
				_icon.x = Math.round(-_icon.width / 2);
				_icon.y = Math.round(-_icon.height / 2);
				_iconHolder.addChild(_icon);
				_iconHolder.x = Math.round(Math.cos(angle + _arc / 2) * _iconRadius);
				_iconHolder.y = Math.round(Math.sin(angle + _arc / 2) * _iconRadius);
			}

			if(iconOrLabel == null) {}
			if(iconOrLabel == null) return 5;
			while (_iconHolder.numChildren > 0) _iconHolder.removeChildAt(0);
			return 0;
		}
	}
}
class DisplayObject {
	public var x:Number;
	public var y:Number;
	public var rotation:Number;
	public var width:Number;
	public var height:Number;
	public var numChildren:Number;
	public function draw ():void { }
	public function addChild (arg:DisplayObject):void { }
	public function removeChildAt (arg:Number):void { }
}
class Label extends DisplayObject {
	public function Label(title:String, x:Number, y:Number, label:String) {
	}
}
