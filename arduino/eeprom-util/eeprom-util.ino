// pin 47 (PL2) didn't check out...

#define ADDR_LOW_OUT PORTA
#define ADDR_LOW_DIR DDRA
#define ADDR_LOW_IN  PINA

#define ADDR_HI_OUT PORTC
#define ADDR_HI_DIR DDRC
#define ADDR_HI_IN  PINC

#define DATA_OUT PORTL
#define DATA_DIR DDRL
#define DATA_IN  PINL

#define DIR_OUT 0xFF
#define DIR_IN  0x00

#define CTRL_OUT PORTB
#define CTRL_DIR DDRB
#define CE_BIT   8
#define OE_BIT   4
#define WE_BIT   1


#define NOP __asm__ __volatile__ ("nop\n\t")

void eeprom_setup() {
    ADDR_LOW_OUT = 0x00;
    ADDR_LOW_DIR = DIR_OUT;
    ADDR_HI_OUT  = 0x00;
    ADDR_HI_DIR  = DIR_OUT;
    DATA_OUT     = 0x00;
    DATA_DIR     = DIR_IN;
    CTRL_OUT     = WE_BIT;
    CTRL_DIR     = DIR_OUT;
}

byte eeprom_read(word addr) {
    // read mode
    DATA_DIR = DIR_IN;
    CTRL_OUT &= ~OE_BIT;

    // assert address
    ADDR_LOW_OUT = addr & 0xFF;
    ADDR_HI_OUT  = addr >> 8;

    // wait for tACC = 250ns
    NOP; NOP; NOP; NOP;

    // read data pins
    return DATA_IN;
}

void eeprom_write_ll(word addr, byte data) {
    // assert address
    ADDR_LOW_OUT = addr & 0xFF;
    ADDR_HI_OUT  = addr >> 8;

    // latch address
    CTRL_OUT &= ~WE_BIT;

    // wait for tAH = 50ns
    NOP;

    // assert data
    DATA_OUT = data;

    // wait for tDS = 50us
    NOP;

    // latch data
    CTRL_OUT |= WE_BIT;

    // wait for tWPH = 50us
    // NOP; // no needed, setup for next write will take atleast this long...
}

bool eeprom_write(word addr, byte data) {
    // write mode
    CTRL_OUT |= OE_BIT;
    DATA_DIR  = DIR_OUT;

    eeprom_write_ll(addr, data);
    
    // read mode
    DATA_DIR = DIR_IN;
    CTRL_OUT &= ~OE_BIT;

    // poll until write completes
    for (int ix=0; ix < 30000; ix++) {
        if (DATA_IN == data) {
            return true;
        }
        delayMicroseconds(10);
    }

    return false;
}

void eeprom_unlock() {
    // write mode
    CTRL_OUT |= OE_BIT;
    DATA_DIR  = DIR_OUT;

    eeprom_write_ll(0x5555, 0xAA);
    eeprom_write_ll(0x2AAA, 0x55);
    eeprom_write_ll(0x5555, 0x80);
    eeprom_write_ll(0x5555, 0xAA);
    eeprom_write_ll(0x2AAA, 0x55);
    eeprom_write_ll(0x5555, 0x20);
    
    // read mode
    DATA_DIR = DIR_IN;
    CTRL_OUT &= ~OE_BIT;
}

void eeprom_lock() {
    // write mode
    CTRL_OUT |= OE_BIT;
    DATA_DIR  = DIR_OUT;

    eeprom_write_ll(0x5555, 0xAA);
    eeprom_write_ll(0x2AAA, 0x55);
    eeprom_write_ll(0x5555, 0xA0);
    
    // read mode
    DATA_DIR = DIR_IN;
    CTRL_OUT &= ~OE_BIT;
}

bool eeprom_page_fill(word pageAddr, byte data) {
    if (pageAddr & 0x3F != 0) {
        return false;
    }

    // write mode
    CTRL_OUT |= OE_BIT;
    DATA_DIR  = DIR_OUT;

    // write the page
    for (int i=0; i<64; i++) {
        eeprom_write_ll(pageAddr++, data);
    }

    // read mode
    DATA_DIR = DIR_IN;
    CTRL_OUT &= ~OE_BIT;

    return true;
}

bool eeprom_page_write(word pageAddr, byte page[]) {
    if (pageAddr & 0x1F != 0) {
        return false;
    }

    // write mode
    CTRL_OUT |= OE_BIT;
    DATA_DIR  = DIR_OUT;

    // write the page
    for (int i=0; i<64; i++) {
        eeprom_write_ll(pageAddr++, page[i]);
    }

    // read mode
    DATA_DIR = DIR_IN;
    CTRL_OUT &= ~OE_BIT;

    return true;
}

void eeprom_dump(word base, word bytes) {
    // read mode
    DATA_DIR = DIR_IN;
    CTRL_OUT &= ~OE_BIT;
    
    word last = base + bytes;
    
    for (; base < last; base += 0x10) {
        byte data[0x10];
        for (int offset = 0; offset < 0x10; offset++) {
            data[offset] = eeprom_read(base + offset);
        }

        char buf[80];
        sprintf(buf, "%04x: %02x %02x %02x %02x %02x %02x %02x %02x    %02x %02x %02x %02x %02x %02x %02x %02x ",
            base,
            data[0x00], data[0x01], data[0x02], data[0x03], data[0x04], data[0x05], data[0x06], data[0x07],
            data[0x08], data[0x09], data[0x0A], data[0x0B], data[0x0C], data[0x0D], data[0x0E], data[0x0F]);

        Serial.println(buf);
    }
}

int serial_readline(char* buffer, int len) {
    for (int ix = 0; ix < len; ix++) {
        buffer[ix] = 0;
    }

    // read serial data until linebreak or buffer is full
    char c = ' ';
    int ix = 0;
    do {
        if (Serial.available()) {
            c = Serial.read();
            if ((c == '\b') && (ix > 0)) {
                // Backspace, forget last character
                --ix;
            }
            buffer[ix++] = c;
            Serial.write(c); // echo
        }
    } while ((c != '\n') && (c != '\r') && (ix < len));

    buffer[ix - 1] = 0;
    return ix - 1;
}

void setup() {
    Serial.begin(115200);
    Serial.println("Setting up EEPROM default pin states...");
    eeprom_setup();
}

void loop() {
    char buffer[160] = { 0 };
    word addr = 0, len = 0;
    byte data = 0, page[64] = { 0 };
    
    Serial.print("> ");
    int line_len = serial_readline(buffer, 160);

    if (strncasecmp(buffer, "LOCK", 4) == 0) {
        eeprom_lock();
        Serial.println("locked.");
    } else if (strncasecmp(buffer, "UNLOCK", 6) == 0) {
        eeprom_unlock();
        Serial.println("unlocked.");
    } else if (strncasecmp(buffer, "CLEAR", 5) == 0) {
        Serial.print("Erasing... ");
        for (addr=0x0000; addr<0x8000; addr+=0x40) {
            eeprom_page_fill(addr, 0xFF);
            delay(10);
        }
        Serial.println("done.");
    } else if (strncasecmp(buffer, "DUMP", 4) == 0) {
        eeprom_dump(0x0000, 0x8000);
    } else if (strncasecmp(buffer, "R ", 2) == 0) {
        sscanf(buffer+2, "%04x", &addr);
        data = eeprom_read(addr);
        sprintf(buffer, "[%04x] = %02x", addr, data);
        Serial.println(buffer);
    } else if (strncasecmp(buffer, "W ", 2) == 0) {
        sscanf(buffer+2, "%04x %02x", &addr, &data);
        if (eeprom_write(addr, data)) {
            Serial.println("ok");
        } else {
            Serial.println("failed!");
        }
    } else if (strncasecmp(buffer, "Z ", 2) == 0) {
        sscanf(buffer+2, "%04x", &addr);
        if (eeprom_page_fill(addr, 0x00)) {
            Serial.println("ok.");
        } else {
            Serial.println("failed!");
        }
    } else if (strncasecmp(buffer, "F ", 2) == 0) {
        sscanf(buffer+2, "%04x %02x", &addr, &data);
        if (eeprom_page_fill(addr, data)) {
            Serial.println("ok.");
        } else {
            Serial.println("failed!");
        }
    } else if (strncasecmp(buffer, "P ", 2) == 0) {
        sscanf(buffer+2, "%04x", &addr);
        for (int i=0; i<64; i++) {
            sscanf(buffer + 7 + (2 * i), "%02x", &page[i]);
        }
        if (eeprom_page_write(addr, page)) {
            Serial.println("ok.");
        } else {
            Serial.println("failed!");
        }
    } else if (strncasecmp(buffer, "L", 1) == 0) {
        while (true) {
            Serial.print("* ");
            if (serial_readline(buffer, 160) == 0) {
                break;
            }
            sscanf(buffer, "%04x", &addr);
            for (int i=0; i<64; i++) {
                sscanf(buffer + 6 + (2 * i), "%02x", &page[i]);
            }
            eeprom_page_write(addr, page);
        }
    } else if (strncasecmp(buffer, "D", 1) == 0) {
        Serial.println(buffer);
        sscanf(buffer+2, "%04x %04x", &addr, &len);
        sprintf(buffer, "DUMP %04x %04x", addr, len);
        Serial.println(buffer);
        eeprom_dump(addr, len);
    } else if (strncasecmp(buffer, "H", 1) == 0 || buffer[0] == '?') {
        Serial.println("Commands:");
        Serial.println("-----------------------------------------------------------");
        Serial.println("LOCK               - write-lock EEPROM");
        Serial.println("UNLOCK             - write-unlock EEPROM");
        Serial.println("CLEAR              - clear EEPROM");
        Serial.println("DUMP               - dump EEPROM");
        Serial.println("-----------------------------------------------------------");
        Serial.println("R hhll             - read byte at address hhll");
        Serial.println("W hhll dd          - write byte dd to address hhll");
        Serial.println("-----------------------------------------------------------");
        Serial.println("Z hhll             - zero page at hhll");
        Serial.println("F hhll dd          - fill page at hhll with dd");
        Serial.println("P hhll d0d1d2..d63 - page write at hhll with d0..d63");
        Serial.println("L                  - load pages of data until empty line");
        Serial.println("-----------------------------------------------------------");
        Serial.println("D hhll nnnn         - dump nn bytes starting at address hhll");
    }
}
