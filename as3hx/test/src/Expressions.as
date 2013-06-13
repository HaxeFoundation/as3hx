package {

// Found in LayoutManager.as
CONFIG::performanceInstrumentation
{
	import mx.utils.PerfUtil; 
}

// Found in PerfUtil.as
CONFIG::performanceInstrumentation
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

		if ("runtimeDPI" in FlexGlobals.topLevelApplication) {
		}

		for (istr in p_obj) {
			var f : float = 1.0e-9; // - replace '1.0e-9' with '0.000000001'
		}

		for each (var namespaceURL:String in usedMetadatas) {
		}

		// Comment before a namespace block
		CONFIG::debug { assert(obj != null, "Event target is not a DisplayObject"); }

		SystemManagerGlobals.topLevelSystemManagers[0].
			// Comment between a method call
			dispatchEvent(new FocusEvent(FlexEvent.NEW_CHILD_APPLICATION, false, false, this));

		// +1.0e-9 fails
		if (-1.0e-9 < c && c < +1.0e-9) doSomething();

		// Found in ObjectUtil.as
		if (a is ObjectProxy)
			a = ObjectProxy(a).object_proxy::object;

		var dynamic:Boolean = false;

		// Found in StyleProtoChain.as
		return typeHierarchy.object_proxy::getObjectProperty(cssType) != null;
	}

	// from Flex mx/styles/CSSStyleDeclaration.as, and other files for CONFIG::
	public function clearStyle(styleProp:String):void
	{
		public::setStyle(styleProp, undefined);
		CONFIG::debug { assert(obj != null, "Event target is not a DisplayObject"); }
	}
}
}
