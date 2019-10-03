.PHONY: clean flash emulate

all: out/rom.bin

out/rom.bin: *.s
	ophis -c -v -o out/rom.bin -m out/rom.map -l out/rom.lst main.s

out/rom.hex: out/rom.bin
	xxd -c 64 -g 0 out/rom.bin | cut -c5-138 | grep -Ev 'f{128}' > out/rom.hex


clean:
	rm -f out/*

flash: out/rom.hex
	-(sleep 2; echo L; cat out/rom.hex; echo ""; sleep 2) | microcom -s 115200 -p /dev/arduino_eeprom

emulate: out/rom.bin
	cd out && java -jar ~/tools/symon/target/symon-1.3.0-SNAPSHOT.jar -- -machine mymachine &
