package {
	public class GetXmlNS {
		public function GetXmlNS() {
			var updateDescriptor:XML = new XML(<test/>);
			var updateVersion = updateDescriptor.UPDATE_XMLNS_1_0::version;
			var updateDescription = updateDescriptor.UPDATE_XMLNS_1_0::description;
			// var updatePackageURL = updateDescriptor.UPDATE_XMLNS_1_0::urls.UPDATE_XMLNS_1_1::[installerType];
		}
	}
}