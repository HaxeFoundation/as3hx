package {
public class Expressions {

	public static function tests() {
//		var b = 1== 2 && 3;

		if(a && b) {}
		if(a && b.method()) {}
		if(a.method() && b) {}
		if(a.method() && b.method()) {}
		if(a.method() && b.method() && c) {}
		if(a.method() && b.method() && c.method()) {}
		if(a.method() && b.method() && (c < 9)) {}


		if(type==1 && a>0) {
		}
		if(type=="M" && a>0) {
		}
		if((type=="N") && b>0) {
		}
		if(type=="O" &&c>0) { // comment
		}

		while(a && b) {}
		while(a && b.method()) {}
		while(a.method() && b) {}
		while(a.method() && b.method()) {}

		switch(a==1 && s>1) {
		case true:
		case false:
		}
	}
}
}
