int serial_readline(char* buffer, int len) {
    for (int ix = 0; (ix < len); ix++) {
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
}

void loop() {
    char buffer[160] = { 0 };
    int pin;
    char state;

    Serial.print("> ");
    int len = serial_readline(buffer, 160);

    if (strncasecmp(buffer, "H", 1) == 0 || buffer[0] == '?') {
        Serial.println("Commands:");
        Serial.println("-----------------------------------------------------------");
        Serial.println("nn H - set pin nn high");
        Serial.println("nn L - set pin nn low");
        Serial.println("-----------------------------------------------------------");
    } else if (sscanf(buffer, "%i %c", &pin, &state) == 2) {
        pinMode(pin, OUTPUT);
        digitalWrite(pin, state == 'L' ? LOW : HIGH);
    }
}
