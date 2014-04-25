default:
	haxe --no-traces as3hx.hxml && nekotools boot as3hx.n && mkdir -p bin && cp as3hx bin

debug:
	haxe -debug as3hx.hxml && nekotools boot as3hx.n && mkdir -p bin && cp as3hx bin

clean:
	rm -rf bin
