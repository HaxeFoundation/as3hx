package {
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	public class Issue257 {
		public function Issue257() {
			var req:URLRequest = new URLRequest("http://www.adobe.com/");
			navigateToURL(req, "_blank");
		}
	}
}