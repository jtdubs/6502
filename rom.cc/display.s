;;
;; display.s - Driver for the Hitachi HD44780U display controller
;;
;; Exported Functions:
;; - dsp_init           - Initialize the display
;; - dsp_clear          - Clear the display
;; - dsp_home           - Move cursor to home
;; - dsp_display_on     - Turn the display on
;; - dsp_display_off    - Turn the display off
;; - dsp_cursor_on      - Turn the cursor on
;; - dsp_cursor_off     - Turn the cursor off
;; - dsp_blink_on       - Turn cursor blink on
;; - dsp_blink_off      - Turn cursor blink off
;; - dsp_scroll_left    - Scroll left
;; - dsp_scroll_right   - Scroll right
;; - dsp_autoscroll_on  - Turn autoscroll on
;; - dsp_autoscroll_off - Turn autoscroll off
;; - dsp_print_1        - Print a message to the 1st line
;; - dsp_print_2        - Print a message to the 2nd line
;; - dsp_blit           - Blit a buffer to the display
;;
;; Local Functions:
;; - dsp_wait_idle     - Wait for display idle
;;
.pc02


;; Imports from Peripheral Controller
.import REG_IOA, REG_IOB, REG_DDRA, REG_DDRB
.importzp DIR_IN, DIR_OUT

;; Imports from Delay
.import delay_us

;; Exports
.exportzp VAR_DSP_MESSAGE_PTR
.export dsp_init
.export dsp_clear
.export dsp_home
.export dsp_display_on, dsp_display_off
.export dsp_cursor_on, dsp_cursor_off
.export dsp_blink_on, dsp_blink_off
.export dsp_scroll_left, dsp_scroll_right
.export dsp_autoscroll_on, dsp_autoscroll_off
.export dsp_print_1, dsp_print_2
.export dsp_blit


;;
;; Display Control Lines
;;
RS = $20
RW = $40
E  = $80


;;
;; Functions IDs
;;
FN_CLEAR           = $01
FN_HOME            = $02
FN_ENTRY_MODE      = $04
FN_DISPLAY_CONTROL = $08
FN_SHIFT           = $10
FN_FUNCTION_SET    = $20
FN_SET_CGRAM_ADDR  = $40
FN_SET_DDRAM_ADDR  = $80


;;
;; Function Parameters
;;
PARAM_ENTRY_MODE_INC   = $02
PARAM_ENTRY_MODE_DEC   = $00
PARAM_ENTRY_MODE_SHIFT = $01

PARAM_DC_DISPLAY_ON    = $04
PARAM_DC_CURSOR_ON     = $02
PARAM_DC_BLINK_ON      = $01

PARAM_SHIFT_SCREEN     = $80
PARAM_SHIFT_CURSOR     = $00
PARAM_SHIFT_RIGHT      = $40
PARAM_SHIFT_LEFT       = $00

PARAM_FN_8BIT          = $10
PARAM_FN_4BIT          = $00
PARAM_FN_2LINE         = $08
PARAM_FN_1LINE         = $00
PARAM_FN_5x10          = $04
PARAM_FN_5x8           = $00

BUSY_FLAG              = $80


;;
;; Zero-page Variables
;;

.zeropage
VAR_DSP_MESSAGE_PTR: .res 2


;;
;; RAM Data
;;

.data
VAR_FUNCTION: .res 1
VAR_CONTROL:  .res 1
VAR_MODE:     .res 1


;;
;; dsp_init: Initialize the HD44780 Display Controller
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_init
    ldx #E

    ;;
    ;; Initialize variables with default values for each function
    ;;

    ;; 8-bit chars, 2 line display, 5x8 font
    lda #(FN_FUNCTION_SET | PARAM_FN_8BIT | PARAM_FN_2LINE | PARAM_FN_5x8)
    sta VAR_FUNCTION

    ;; display, cursor & blink on
    lda #(FN_DISPLAY_CONTROL | PARAM_DC_DISPLAY_ON)
    sta VAR_CONTROL

    ;; auto-increment on output
    lda #(FN_ENTRY_MODE | PARAM_ENTRY_MODE_INC)
    sta VAR_MODE


    ;;
    ;; Perform initialization routine based on datasheet
    ;;

    ;; call "Function Set"
    jsr dsp_wait_idle
    stx REG_IOA
    lda VAR_FUNCTION
    sta REG_IOB
    stz REG_IOA

    ;; Call "Display Control"
    jsr dsp_wait_idle
    stx REG_IOA
    lda VAR_CONTROL
    sta REG_IOB
    stz REG_IOA

    ;; Call "Entry mode Set"
    jsr dsp_wait_idle
    stx REG_IOA
    lda VAR_MODE
    sta REG_IOB
    stz REG_IOA

    ;; Call "Clear display"
    jsr dsp_wait_idle
    stx REG_IOA
    lda #FN_CLEAR
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_clear: Clear the display
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.code
.proc dsp_clear
    jsr dsp_wait_idle

    ;; Call "Clear"
    lda #E
    sta REG_IOA
    lda #FN_CLEAR
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_home: Moves display back to home position
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.code
.proc dsp_home
    jsr dsp_wait_idle

    ;; Call "Home"
    lda #E
    sta REG_IOA
    lda #FN_HOME
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_display_on: Turn on the display
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_display_on
    jsr dsp_wait_idle

    ;; set Display bit in VAR_DSP_CONTROL
    lda VAR_CONTROL
    ora #PARAM_DC_DISPLAY_ON
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_display_off: Turn off the display
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_display_off
    jsr dsp_wait_idle

    ;; clear Display bit in VAR_DSP_CONTROL
    lda VAR_CONTROL
    and #($FF ^ PARAM_DC_DISPLAY_ON)
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_cursor_on: Turn on the cursor
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_cursor_on
    jsr dsp_wait_idle

    ;; set Cursor bit in VAR_DSP_CONTROL
    lda VAR_CONTROL
    ora #PARAM_DC_CURSOR_ON
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_cursor_off: Turn off the cursor
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_cursor_off
    jsr dsp_wait_idle

    ;; clear Cursor bit in VAR_DSP_CONTROL
    lda VAR_CONTROL
    and #($FF ^ PARAM_DC_CURSOR_ON)
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_blink_on: Turn on cursor blink
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_blink_on
    jsr dsp_wait_idle

    ;; set Blink bit in VAR_DSP_CONTROL
    lda VAR_CONTROL
    ora #PARAM_DC_BLINK_ON
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_blink_off: Turn off the blink
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_blink_off
    jsr dsp_wait_idle

    ;; clear Cursor bit in VAR_DSP_CONTROL
    lda VAR_CONTROL
    and #($FF ^ PARAM_DC_BLINK_ON)
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_scroll_left: Scroll the display one character left
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_scroll_left
    jsr dsp_wait_idle

    ;; call "Shift" function
    ldx #E
    stx REG_IOA
    lda #(FN_SHIFT | PARAM_SHIFT_SCREEN | PARAM_SHIFT_LEFT)
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_scroll_right: Scroll the display one character right
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_scroll_right
    jsr dsp_wait_idle

    ;; call "Shift" function
    ldx #E
    stx REG_IOA
    lda #(FN_SHIFT | PARAM_SHIFT_SCREEN | PARAM_SHIFT_RIGHT)
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_autoscroll_on: Enable autoscroll
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_autoscroll_on
    jsr dsp_wait_idle

    ;; set Shift bit in VAR_DSP_MODE
    lda VAR_MODE
    ora #PARAM_ENTRY_MODE_SHIFT
    sta VAR_MODE

    ;; call "Entry Mode" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_autoscroll_off: Disable autoscroll
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.code
.proc dsp_autoscroll_off
    jsr dsp_wait_idle

    ;; clear Shift bit in VAR_DSP_MODE
    lda VAR_MODE
    and #($FF ^ PARAM_ENTRY_MODE_SHIFT)
    sta VAR_MODE

    ;; call "Entry Mode" function
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.endproc


;;
;; dsp_print_1: Print a message
;;
;; Registers Used: A, Y
;;
.code
.proc dsp_print_1
    jsr dsp_wait_idle

    ;; set ddram address to 0 (start of line 1)
    lda #(FN_SET_DDRAM_ADDR | $00)
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr dsp_wait_idle

    ldy #$00 ;; Y is array index

_loop:
    ;; stop on 16 chars, or null
    lda (VAR_DSP_MESSAGE_PTR),y
    beq _end
    cpy #$10
    beq _end

    ;; load the character into IO B
    sta REG_IOB

    ;; pulse E
    lda #(RS | E)
    sta REG_IOA
    lda #RS
    sta REG_IOA

    ;; wait for character to write (40us)
    lda #2
    jsr delay_us

    ;; advance to next character
    iny
    jmp _loop

_end:
    rts
.endproc


;;
;; dsp_print_2: Print a message
;;
;; Registers Used: A, Y
;;
.code
.proc dsp_print_2
    jsr dsp_wait_idle

    ;; set ddram address to $40 (start of line 2)
    lda #(FN_SET_DDRAM_ADDR | $40)
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr dsp_wait_idle

    ldy #$00 ;; Y is array index

_loop:
    ;; stop on 16 chars, or null
    lda (VAR_DSP_MESSAGE_PTR),y
    beq _end
    cpy #$10
    beq _end

    ;; load the character into IO B
    sta REG_IOB

    ;; pulse E
    lda #(RS | E)
    sta REG_IOA
    lda #RS
    sta REG_IOA

    ;; wait for character to write (40us)
    lda #2
    jsr delay_us

    ;; advance to next character
    iny
    jmp _loop

_end:
    rts
.endproc


;;
;; dsp_blit: Blit a buffer to the display
;;
;; Registers Used: A, Y
;;
.code
.proc dsp_blit
_setup_1:
    jsr dsp_wait_idle

    ;; set ddram address to 0 (start of line 1)
    lda #(FN_SET_DDRAM_ADDR | $00)
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr dsp_wait_idle

    ldy #$00 ;; Y is array index

_loop_1:
    ;; load the character into IO B
    lda (VAR_DSP_MESSAGE_PTR),y
    sta REG_IOB

    ;; pulse E
    lda #(RS | E)
    sta REG_IOA
    lda #RS
    sta REG_IOA

    ;; wait for character to write (40us)
    lda #2
    jsr delay_us

    ;; advance to next character
    iny
    cpy #$10
    bmi _loop_1

_setup_2:
    jsr dsp_wait_idle

    ;; set ddram address to $40 (start of line 2)
    lda #(FN_SET_DDRAM_ADDR | $40)
    ldx #E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr dsp_wait_idle

    ldy #$40 ;; Y is array index

_loop_2:
    ;; load the character into IO B
    lda (VAR_DSP_MESSAGE_PTR),y
    sta REG_IOB

    ;; pulse E
    lda #(RS | E)
    sta REG_IOA
    lda #RS
    sta REG_IOA

    ;; wait for character to write (40us)
    lda #2
    jsr delay_us

    ;; advance to next character
    iny
    cpy #$50
    bmi _loop_2

_end:
    rts
.endproc


;;
;; dsp_wait_idle: Wait for display idle
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.code
.proc dsp_wait_idle
    ;; set port B to input
    lda #<DIR_IN
    sta REG_DDRB

    ;; set flags for reading the instruction register
    lda #(RW | E)
    sta REG_IOA

_loop:
    ;; read the instruction register and loop until not busy
    lda REG_IOB
    and #BUSY_FLAG
    bne _loop

_cleanup:
    ;; set port B back to output
    lda #<DIR_OUT
    sta REG_DDRB
    rts
.endproc
