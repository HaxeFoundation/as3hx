class FastXMLList {
	
	var l : Array<FastXML>;

	public function new(?a:Array<FastXML>) {
		l = (a != null ? a : new Array());
	}

	/**
	 * Makes a copy of the FastXMLList
	 **/
	public function copy() : FastXMLList {
		return new FastXMLList(l.slice(0));
	}

	public function descendants(name:String) : FastXMLList {
		throw "Incomplete";
		return null;
	}

	public function get(i:Int) : FastXML {
		return l[i];
	}

	public function iterator() : Iterator<FastXML> {
		return l.iterator();
	}
	
	public function length() : Int {
		return l.length;
	}

	/**
	 * 
	public function set(i:Int, v:FastXML) : FastXML {
		l[i] = v;
		return v;
	}
	*/

}