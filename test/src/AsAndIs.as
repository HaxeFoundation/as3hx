package {

public class AsAndIs {
        public function setIcon(iconOrLabel:Object):void
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
                        _icon = new Label(null, 0, 0, iconOrLabel as String);
                        (_icon as Label).draw();
						(_icon as mx.geom.Transform).rotate();
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
                if(iconOrLabel == null) return;
                while(_iconHolder.numChildren > 0) _iconHolder.removeChildAt(0);
        }
}
}

