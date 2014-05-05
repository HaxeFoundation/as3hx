default:
	haxe --no-traces as3hx.hxml

debug:
	haxe -debug as3hx.hxml

clean:
	rm -rf run.n test-out/

run-test:
	rm -rf test-out
	neko run.n test/e2e test-out/
