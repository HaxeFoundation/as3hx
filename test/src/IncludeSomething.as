package {

	import mx.core.mx_internal;

	use namespace mx_internal;

	[ExcludeClass]

	/**
	*  @private
	*/
	public class IncludeSomething
	{
		include "../includes/Version.as";

		public static function doNothing() {
		}
	}

}
