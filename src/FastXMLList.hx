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

    public function descendants(name:String = "*") :FastXMLList {
        var a = new Array<FastXML>();
        for(fx in l) {
            for(e in fx.x.elements()) {
                if(e.nodeName == name || name == "*") {
                    a.push(new FastXML(e));
                } else {
                    var fx2 = new FastXML(e);
                    a = a.concat(fx2.descendants(name).getArray());
                }
            }
        }
        return new FastXMLList(a);
    }

    public function get(i:Int) : FastXML {
        return l[i];
    }

    public function getArray() : Array<FastXML> {
        return l;
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

    public function toString() : String {
        var s = "";
        var first = true;
        for(i in l) {
            if(!first)
                s += "\r\n";
            first = false;
            s = s + i.toString();
        }
        return s;
    }
}