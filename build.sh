#!/bin/sh

# ../assembler_1.1b/assemble test.s -oout.bin
asmx -C 65C02 -b 0-65536 -o out.bin test.s

xxd -c 64 -g 0 out.bin | cut -c5-138 | grep -Ev 'f{128}' > out.hex
