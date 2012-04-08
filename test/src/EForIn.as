package {

import flash.display.Sprite;
import flash.utils.Dictionary;

public class EForIn {

	public static function tests() {
		var advanceStyleClientChildren:Dictionary = new Dictionary();

            	for (var styleClient:Object in advanceStyleClientChildren) {
			var iAdvanceStyleClientChild:Sprite = styleClient as Sprite;
            	}
	}
}
}

