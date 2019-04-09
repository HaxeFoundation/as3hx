import flash.system.Security;

class Issue81 {

	private static var Issue81_static_initializer = {
		Security.allowDomain('*');
		true;
	}

}