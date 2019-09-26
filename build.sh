#!/bin/sh

ophis -c -v -o out.bin -m out.map -l out.lst main.s

xxd -c 64 -g 0 out.bin | cut -c5-138 | grep -Ev 'f{128}' > out.hex
xxd -o-0x8000 out.bin | tail -2048 | xxd -r > rom.bin
