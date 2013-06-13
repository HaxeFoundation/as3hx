package includes {

import flash.display.Sprite;

public class Circle extends Sprite {

	function Circle():void {
		graphics.beginFill(0xFFFFFF);
		graphics.lineStyle(2, 0x990000, .75);
		graphics.drawCircle(50, 50, 30);
		graphics.endFill();
	}
}
}