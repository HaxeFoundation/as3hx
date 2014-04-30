package as3hx;

class Debug {

    static var lvl : Int = 0;

    public static function printDebug(s : String) : Void {
        Sys.stderr().write(haxe.io.Bytes.ofString(s));
    }

    public static function openDebug(s:String, line:Int, newline:Bool=false,?p:haxe.PosInfos) {
        #if debug
        var o = indent() + "(" + line + ") " + s  + " [Parser " + p.lineNumber + "]";
        if(newline)
            o = o + "\r\n";
        printDebug(o);
        lvl++;
        #end
    }

    public static function closeDebug(s:String, line:Int, ?p:haxe.PosInfos) {
        #if debug
        lvl--;
        Debug.printDebug(indent() + "(" + line + ") " + s + " [Parser " + p.lineNumber + "]\r\n");
        #end
    }

    public static function dbg(s:String, line:Int, ind:Bool=true,?p:haxe.PosInfos) {
        #if debug
        var o = ind ? indent() : "";
        o += "(" + line + ") " + s + " [Parser " + p.lineNumber + "]";
        Debug.printDebug(o);
        #end
    }

    public static function dbgln(s:String, line:Int=0, ind:Bool=true,?p:haxe.PosInfos) {
        #if debug
        var o = ind ? indent() : "";
        o += "(" + line + ") " + s + " [Parser " + p.lineNumber + "]\r\n";
        Debug.printDebug(o);
        #end
    }

    private static function indent() {
        var b = [];
        for (i in 0...lvl)
            b.push("\t");
        return b.join("");
    }


}
