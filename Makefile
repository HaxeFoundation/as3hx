default:
	haxe --no-traces as3hx.hxml

debug:
	haxe -debug as3hx.hxml

clean:
	rm -rf run.n test-out/

e2e-test:
	rm -rf test-out
	neko run.n -verifyGeneratedFiles test/e2e test-out/ 

unit-test:
	haxelib run munit test -neko
