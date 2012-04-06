using StringTools;

import as3hx.Writer;
import neko.FileSystem;
import neko.io.File;
import neko.Sys;

class Run {
	
	static function errorString( e : as3hx.Parser.Error ) {
		return switch(e) {
		case EInvalidChar(c): "Invalid char '" + String.fromCharCode(c)+"' 0x"+StringTools.hex(c,2);
		case EUnexpected(src): "Unexpected " + src;
		case EUnterminatedString: "Unterminated string";
		case EUnterminatedComment: "Unterminated comment";
		case EUnterminatedXML: "Unterminated XML";
		}
	}
	
	static function loop( src: String, dst : String ) {
		var subs = [];
		var writer = new Writer(cfg);
		for( f in neko.FileSystem.readDirectory(src) ) {
			if( f.endsWith(".as") ) {
				var p = new as3hx.Parser();
				var file = src + "/" + f;
				neko.Lib.println(file);
				var content = neko.io.File.getContent(file);
				var program = try p.parseString(content) catch( e : as3hx.Parser.Error ) {
					#if macro
					neko.io.File.stderr().writeString(file+":"+p.line+": "+errorString(e)+"\n");
					#end
					neko.Lib.rethrow("In " + file + "("+p.line+") : " + errorString(e));
				}
				var out = dst + "/" + Writer.properCaseA(program.pack,false).join("/");
				ensureDirectoryExists(out);
				var name = out + "/" + Writer.properCase(f.substr(0, -3),true) + ".hx";
				neko.Lib.println(name);
				var fw = File.write(name, false);
				warnings.set(name, writer.process(program, fw));
				fw.close();
			}
			var sub = src + "/" + f;
			if ( neko.FileSystem.isDirectory(sub) )
			{
				subs.push(sub);
			}
		}
		for ( sub in subs )
			loop(sub, dst);
	}

	static var warnings : Hash<Hash<Bool>> = new Hash();
	static var cfg : as3hx.Config;
	public static function main() {
		cfg = new as3hx.Config();
		loop(cfg.src, cfg.dst);
		neko.Lib.println("");
		Writer.showWarnings(warnings);
		neko.Lib.println("");
	}

	static function ensureDirectoryExists(dir : String)
	{
		var tocreate = [];
		while (!FileSystem.exists(dir) && dir != '')
		{
			var parts = dir.split("/");
			tocreate.unshift(parts.pop());
			dir = parts.join("/");
		}
		for (part in tocreate)
		{
			if (part == '')
				continue;
			dir += "/" + part;
			try {
				FileSystem.createDirectory(dir);
			} catch (e : Dynamic) {
				throw "unable to create dir: " + dir;
			}
		}
	}
	
	static var reabs = ~/^([a-z]:|\\\\|\/)/i;
	public static function directory(dir : String, alt = ".")
	{
		if (null == dir)
			dir = alt;
		if( dir.endsWith("/") || dir.endsWith("\\") )
			dir = dir.substr(0, -1);
		if (!reabs.match(dir))
			dir = Sys.getCwd() + dir;
		dir = StringTools.replace(dir, "\\", "/");
		return dir;
	}
}