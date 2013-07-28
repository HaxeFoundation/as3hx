package {

import flash.display.Sprite;

public class Square extends Sprite {

	function Square():void {
		graphics.beginFill(0xFFFFFF);
		graphics.lineStyle(2, 0x990000, .75);
		graphics.drawRect(0, 0, 100, 100);
		graphics.endFill();
	}
}

}
