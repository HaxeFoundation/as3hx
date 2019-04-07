import flash.display3D.Context3D;

class Issue234 {

	public function new() {
		var supportsVideoTexture:Bool = Reflect.getProperty(Context3D, 'supportsVideoTexture') != null;
	}

}