#!/bin/sh
cd ../ && ./build_debug && cd test && as3tohx src3 && cat out/Comments.hx
