default:
	haxe --no-traces as3hx.hxml && nekotools boot as3hx.n && mkdir -p bin && mv as3hx as3hx.n bin

debug:
	haxe -debug as3hx.hxml && nekotools boot as3hx.n && mkdir -p bin && mv as3hx as3hx.n bin

clean:
	rm -rf bin

run-test:
	bin/as3hx test/ bin/out
