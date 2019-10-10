.PHONY: clean

all:
	ca65 -o obj/delay.o -l obj/delay.lst -v delay.s
	ca65 -o obj/peripheral.o -l obj/peripheral.lst -v peripheral.s
	ca65 -o obj/display.o -l obj/display.lst -v display.s
	ca65 -o obj/main.o -l obj/main.lst -v main.s
	ca65 -o obj/ram.o -l obj/ram.lst -v ram.s
	ca65 -o obj/rng.o -l obj/rng.lst -v rng.s
	ca65 -o obj/game.o -l obj/game.lst -v game.s
	ld65 -C board.map -o bin/rom.bin -m bin/rom.map -v obj/ram.o obj/display.o obj/peripheral.o obj/rng.o obj/delay.o obj/game.o obj/main.o

bin/rom.hex: bin/rom.bin
	xxd -c 64 -g 0 bin/rom.bin | cut -c5-138 | grep -Ev '0{128}' > bin/rom.hex

clean:
	rm -f obj/*
	rm -f bin/*

flash: bin/rom.hex
	-(sleep 2; echo L; cat bin/rom.hex; echo ""; sleep 2) | microcom -s 115200 -p /dev/arduino_eeprom

emulate: bin/rom.bin
	cd bin && java -jar ~/tools/symon/target/symon-1.3.0-SNAPSHOT.jar -- -machine mymachine &
