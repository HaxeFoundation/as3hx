package {

	import mx.core.mx_internal;

	use namespace mx_internal;

	[ExcludeClass]

	include "../includes/BasicInheritingStyles.as";

	/**
	*  @private
	*/
	public class IncludeSomething
	{
		include "../includes/Version.as";

		import flash.display.LoaderInfo;
		public static function doNothing() {
		}
	}

}
