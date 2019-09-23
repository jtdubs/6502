#!/bin/sh

(sleep 5; echo L; cat out.hex; echo ""; sleep 5) | microcom -s 115200 -p /dev/arduino_eeprom 
