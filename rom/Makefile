.PHONY: dirs clean flash emulate

SOURCES = $(wildcard *.s)
OBJECTS = $(addprefix obj/, $(SOURCES:.s=.o))

all: dirs bin/rom.bin

bin/rom.bin: $(OBJECTS)
	ld65 -C board.map -o bin/rom.bin -m bin/rom.map -v $(OBJECTS)

bin/rom.hex: bin/rom.bin
	xxd -c 64 -g 0 bin/rom.bin | cut -c5-138 | grep -Ev '0{128}' > bin/rom.hex

clean:
	rm -f obj/*
	rm -f bin/*

flash: bin/rom.hex
	-(sleep 2; echo L; cat bin/rom.hex; echo ""; sleep 2) | microcom -s 115200 -p /dev/arduino_eeprom

emulate: bin/rom.bin
	cd bin && java -jar ~/tools/symon/target/symon-1.3.0-SNAPSHOT.jar -- -machine mymachine &

dirs:
	mkdir -p obj/
	mkdir -p bin/

obj/%.o : %.s
	ca65 -o $@ -l obj/$*.lst -v $<
