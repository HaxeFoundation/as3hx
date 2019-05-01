class CommentedXML {

	private function new() {
		var libXML:FastXMLList = p.assetLibrary;
		libXML.descendants('child').set(0, FastXML.parse('<empty/>'));
		libXML.descendants('child').set(1, FastXML.parse('<! <empty/> -->'));
		libXML.descendants('child').set(2, FastXML.parse('<!DATA[ <empty/> ]]>'));
		project.appendChild(libXML);
	}

}