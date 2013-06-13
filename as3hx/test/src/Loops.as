package {

public class Loops {
        public function setIcon(iconOrLabel:Object):void
        {
		for(var i:int = 0; i < _numButtons; i++)
                {
                	var btn:ArcButton = new ArcButton();
                        btn.id = i;
			if(btn.name != null) continue;
			trace(i);
                }

		var advanceStyleClientChildren:Dictionary = new Dictionary();

            	for (var styleClient:Object in advanceStyleClientChildren) {
			var iAdvanceStyleClientChild:Sprite = styleClient as Sprite;
            	}
        }
}
}

