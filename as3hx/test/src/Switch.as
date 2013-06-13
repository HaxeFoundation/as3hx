package {

public class Switches {
        public function test(iconOrLabel:Object):void
        {
		switch(i) {
		case "fallnone":
			iBreak();
			break;
		case "fall2":
			a = 1;
		case "fall1":
			b = 1;
		case "hasbreak":
			c = 1;
			break;
		case "should also have j=5":
			d = 1;
		default:
			j = 5;
                }
        }

        public function test2(iconOrLabel:Object):void
        {
		// comment
		switch(getValue()) {
		default: //comment
			j = 5; // j= 5
		case "fallnone":
			iBreak();
			// comment?
			break;
		case "fall1":
			a = 1;
		case "hasswitchbreak":
			switch(boolval) {
			case true:
				t = 1 /* com */; // true!
				break;
			case false:
				t = 0; // false!
			}
			c = 1;
			break;
		case "should also have j=5":
			d = 1;
                }
        }

	public function test3():void {
		switch(noGarbagePlease) {
		case 1:
		case 2:
		case 3:
			runOnlyOn1to3();
			break;
		}
	}


	public function test4():void {
		switch(style)
		{
			case DARK:
					Style.BACKGROUND = 0x444444;
					Style.LIST_ALTERNATE = 0x393939;
					Style.LIST_SELECTED = 0x666666;
					Style.LIST_ROLLOVER = 0x777777;
					break;
			case LIGHT:
			default:
					Style.BACKGROUND = 0xCCCCCC;
					Style.LIST_SELECTED = 0xCCCCCC;
					Style.LIST_ROLLOVER = 0xDDDDDD;
					break;
		}
	}
}

}

