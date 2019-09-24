#!/bin/sh

(sleep 2; echo L; cat out.hex; echo ""; sleep 2) | microcom -s 115200 -p /dev/arduino_eeprom 
