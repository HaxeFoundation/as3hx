package {
import flash.utils.getDefinitionByName;
import flash.display.Sprite;
import includes.Circle;
import includes.FilledCircle;
FilledCircle;
Circle;
Square;


public class Inits extends Sprite {

	function Inits():void {
		
		var filledCircle:Class = getDefinitionByName("includes.FilledCircle") as Class;
		addChild(new filledCircle());

		var circle : Class = getDefinitionByName("includes.Circle") as Class;
		var c : Sprite = new circle() as Sprite;
		addChild(c);
		c.y = 90;
		c.x = 120;

		var sqc : Class = getDefinitionByName("Square") as Class;
		var square : Sprite = new sqc as Sprite;
		addChild(square);
		square.x = 90;
	}
}


}