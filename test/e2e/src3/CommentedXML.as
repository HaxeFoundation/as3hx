package {

public class CommentedXML {

	function CommentedXML():void
	{
		var libXML:XMLList = p.assetLibrary;
		libXML.child[0] = new XML(<empty/>);
		libXML.child[1] = new XML(<!-- <empty/> -->);
		libXML.child[2] = new XML(<![CDATA[ <empty/> ]]>);
		project.appendChild(libXML);
	}
	
}

}