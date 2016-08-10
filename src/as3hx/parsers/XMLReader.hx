package as3hx.parsers;

import as3hx.Tokenizer;
import as3hx.Error;

class XMLReader {

    public static function read(tokenizer:Tokenizer) {
        Debug.dbgln("readXML()", tokenizer.line);
        var buf = new StringBuf();
        var input = tokenizer.input;
        buf.addChar("<".code);
        buf.addChar(tokenizer.char);

        //corner case : check wether this is a satndalone CDATA element
        //(not wrapped in XML element)
        var isCDATA = tokenizer.char == "!".code; 
        
        tokenizer.char = 0;
        try {
            var prev = 0;
            while(true) {
                var c = input.readByte();
                if(c == "\n".code) tokenizer.line++;
                buf.addChar(c);
                if( c == ">".code ) break;
                prev = c;
            }
            if( prev == "/".code )
                return buf.toString();
            if (isCDATA)
                return buf.toString();
            while(true) {
                var c = input.readByte();
                if(c == "\n".code) tokenizer.line++;
                if( c == "<".code ) {
                    c = input.readByte();
                    if(c == "\n".code) tokenizer.line++;
                    if( c == "/".code ) {
                        buf.add("</");
                        break;
                    }
                    if (c == "!".code) { // CDATA element
                        buf.add("<");
                    }
                    else {
                        tokenizer.char = c;
                        buf.add(read(tokenizer));
                        continue;
                    }
                }
                buf.addChar(c);
            }
            while(true) {
                var c = input.readByte();
                if(c == "\n".code) tokenizer.line++;
                buf.addChar(c);
                if( c == ">".code ) break;
            }
            return buf.toString();
        } catch( e : haxe.io.Eof ) {
            throw EUnterminatedXML;
        }
    }
}
