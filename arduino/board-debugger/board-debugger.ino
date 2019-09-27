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

#define CLK_PIN    38
#define RW_PIN     40
#define RAM_CS_PIN 39
#define ROM_CS_PIN 41
#define RESET_PIN  51
#define PER_CS_PIN 50

void board_setup() {
    ADDR_LOW_OUT = 0x00;
    ADDR_LOW_DIR = DIR_IN;
    ADDR_HI_OUT  = 0x00;
    ADDR_HI_DIR  = DIR_IN;
    DATA_OUT     = 0x00;
    DATA_DIR     = DIR_IN;

    digitalWrite(CLK_PIN, LOW);
    pinMode(CLK_PIN, OUTPUT);

    digitalWrite(RESET_PIN, HIGH);
    pinMode(RESET_PIN, OUTPUT);
  
    pinMode(RW_PIN,     INPUT);
    pinMode(RAM_CS_PIN, INPUT);
    pinMode(ROM_CS_PIN, INPUT);
    pinMode(PER_CS_PIN, INPUT);
}

void board_reset() {
    digitalWrite(RESET_PIN, LOW);
    board_step();
    board_step();
    digitalWrite(RESET_PIN, HIGH);
}

void board_step() {
    digitalWrite(CLK_PIN, LOW);
    delayMicroseconds(1);
    digitalWrite(CLK_PIN, HIGH);
    delayMicroseconds(1);
}

void board_show() {
    char buffer[128] = { 0 };

    word addr = (ADDR_HI_IN << 8) | ADDR_LOW_IN;
    byte data = DATA_IN;

    bool clock_state  = digitalRead(CLK_PIN);
    bool rw_state     = digitalRead(RW_PIN);
    bool ram_cs_state = digitalRead(RAM_CS_PIN);
    bool rom_cs_state = digitalRead(ROM_CS_PIN);
    bool per_cs_state = digitalRead(PER_CS_PIN);

    sprintf(
        buffer,
        "%s BUS[A: %04x; D: %02x] CPU[%c] RAM[%s %s %s] ROM[%s OE we] PER[%s %s %s]",
        clock_state ? "CLK" : "clk",
        addr,
        data,
        rw_state ? 'R' : 'W',
        ram_cs_state ? "cs" : "CS",
        (addr & 0x4000 == 0x4000)  ? "oe" : "OE",
        rw_state ? "we" : "WE",
        rom_cs_state ? "cs" : "CS",
        (addr & 0x2000 == 0x2000) ? "CS1" : "cs1",
        per_cs_state ? "cs2" : "CS2",
        rw_state ? "R" : "W"
        );

    Serial.println(buffer);
}

int serial_readline(char* buffer, int len, bool echo) {
    for (int ix = 0; (ix < len); ix++) {
        buffer[ix] = 0;
    }

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
            if (echo) {
                Serial.write(c);
            }
        }
    } while ((c != '\n') && (c != '\r') && (ix < len));

    buffer[ix - 1] = 0;
    return ix - 1;
}

void setup() {
    Serial.begin(115200);
    Serial.println("Initializing board...");
    board_setup();
    Serial.println("Resetting CPU...");
    board_reset();
}

void loop() {
    char buffer[8];

    board_show();
    serial_readline(buffer, 8, false);
    //delayMicroseconds(10);
    board_step();
}
