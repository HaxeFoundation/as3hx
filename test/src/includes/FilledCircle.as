package includes {

import flash.display.Sprite;

public class FilledCircle extends Sprite {

	function FilledCircle():void {
		graphics.beginFill(0xFF794B);
		graphics.drawCircle(50, 50, 30);
		graphics.endFill();
	}
}
}