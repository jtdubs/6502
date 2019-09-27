;;
;; display.s - Driver for the HD4770 display peripheral
;;
;; Functions:
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
;; - dsp_print          - Print a message
;;


;;
;; Dependencies
;;
.require "periph.s"


;;
;; Zero Page Variables
;;
.alias VAR_MESSAGE_PTR  $00


;;
;; Variables
;;
.alias VAR_FUNCTION $0200
.alias VAR_CONTROL  $0201
.alias VAR_MODE     $0202


;;
;; Display Control Lines
;;
.alias CTRL_RS $20
.alias CTRL_RW $40
.alias CTRL_E  $80


;;
;; Functions IDs
;;
.alias FN_CLEAR           $01
.alias FN_HOME            $02
.alias FN_ENTRY_MODE      $04
.alias FN_DISPLAY_CONTROL $08
.alias FN_SHIFT           $10
.alias FN_FUNCTION_SET    $20
.alias FN_SET_CGRAM_ADDR  $40
.alias FN_SET_DDRAM_ADDR  $80


;;
;; Function Parameters
;;
.alias PARAM_ENTRY_MODE_INC   $02
.alias PARAM_ENTRY_MODE_DEC   $00
.alias PARAM_ENTRY_MODE_SHIFT $01

.alias PARAM_DC_DISPLAY_ON    $04
.alias PARAM_DC_CURSOR_ON     $02
.alias PARAM_DC_BLINK_ON      $01

.alias PARAM_SHIFT_SCREEN     $80
.alias PARAM_SHIFT_CURSOR     $00
.alias PARAM_SHIFT_RIGHT      $40
.alias PARAM_SHIFT_LEFT       $00

.alias PARAM_FN_8BIT          $10
.alias PARAM_FN_4BIT          $00
.alias PARAM_FN_2LINE         $08
.alias PARAM_FN_1LINE         $00
.alias PARAM_FN_5x10          $04
.alias PARAM_FN_5x8           $00

.alias BUSY_FLAG              $80


;;
;; dsp_init: Initialize the HD44780 Display Controller
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_init:
    ldx #CTRL_E

    ;;
    ;; Initialize variables with default values for each function
    ;;

    ;; 8-bit chars, 2 line display, 5x8 font
    lda #[FN_FUNCTION_SET | PARAM_FN_8BIT | PARAM_FN_2LINE | PARAM_FN_5x8]
    sta VAR_FUNCTION

    ;; display, cursor & blink on
    lda #[FN_DISPLAY_CONTROL | PARAM_DC_DISPLAY_ON]
    sta VAR_CONTROL

    ;; auto-increment on output
    lda #[FN_ENTRY_MODE | PARAM_ENTRY_MODE_INC]
    sta VAR_MODE


    ;;
    ;; Perform initialization routine based on datasheet
    ;;

    ;; call "Function Set"
    jsr dsp_wait_idle
    stx IO_A
    lda VAR_FUNCTION
    sta IO_B
    stz IO_A

    ;; Call "Display Control"
    jsr dsp_wait_idle
    stx IO_A
    lda VAR_CONTROL
    sta IO_B
    stz IO_A

    ;; Call "Entry mode Set"
    jsr dsp_wait_idle
    stx IO_A
    lda VAR_MODE
    sta IO_B
    stz IO_A

    ;; Call "Clear display"
    jsr dsp_wait_idle
    stx IO_A
    lda #FN_CLEAR
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_clear: Clear the display
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.scope
dsp_clear:
    jsr dsp_wait_idle

    ;; Call "Clear"
    lda #CTRL_E
    sta IO_A
    lda #FN_CLEAR
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_home: Moves display back to home position
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.scope
dsp_home:
    jsr dsp_wait_idle

    ;; Call "Home"
    lda #CTRL_E
    sta IO_A
    lda #FN_HOME
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_display_on: Turn on the display
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_display_on:
    jsr dsp_wait_idle

    ;; set Display bit in VAR_CONTROL
    lda VAR_CONTROL
    ora #PARAM_DC_DISPLAY_ON
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_display_off: Turn off the display
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_display_off:
    jsr dsp_wait_idle

    ;; clear Display bit in VAR_CONTROL
    lda VAR_CONTROL
    and #[$FF ^ PARAM_DC_DISPLAY_ON]
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_cursor_on: Turn on the cursor
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_cursor_on:
    jsr dsp_wait_idle

    ;; set Cursor bit in VAR_CONTROL
    lda VAR_CONTROL
    ora #PARAM_DC_CURSOR_ON
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_cursor_off: Turn off the cursor
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_cursor_off:
    jsr dsp_wait_idle

    ;; clear Cursor bit in VAR_CONTROL
    lda VAR_CONTROL
    and #[$FF ^ PARAM_DC_CURSOR_ON]
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_blink_on: Turn on cursor blink
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_blink_on:
    jsr dsp_wait_idle

    ;; set Blink bit in VAR_CONTROL
    lda VAR_CONTROL
    ora #PARAM_DC_BLINK_ON
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_blink_off: Turn off the blink
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_blink_off:
    jsr dsp_wait_idle

    ;; clear Cursor bit in VAR_CONTROL
    lda VAR_CONTROL
    and #[$FF ^ PARAM_DC_BLINK_ON]
    sta VAR_CONTROL

    ;; call "Display Control" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_scroll_left: Scroll the display one character left
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_scroll_left:
    jsr dsp_wait_idle

    ;; call "Shift" function
    ldx #CTRL_E
    stx IO_A
    lda #[FN_SHIFT | PARAM_SHIFT_SCREEN | PARAM_SHIFT_LEFT]
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_scroll_right: Scroll the display one character right
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_scroll_right:
    jsr dsp_wait_idle

    ;; call "Shift" function
    ldx #CTRL_E
    stx IO_A
    lda #[FN_SHIFT | PARAM_SHIFT_SCREEN | PARAM_SHIFT_RIGHT]
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_autoscroll_on: Enable autoscroll
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_autoscroll_on:
    jsr dsp_wait_idle

    ;; set Shift bit in VAR_MODE
    lda VAR_MODE
    ora #PARAM_ENTRY_MODE_SHIFT
    sta VAR_MODE

    ;; call "Entry Mode" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_autoscroll_off: Disable autoscroll
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
dsp_autoscroll_off:
    jsr dsp_wait_idle

    ;; clear Shift bit in VAR_MODE
    lda VAR_MODE
    and #[$FF ^ PARAM_ENTRY_MODE_SHIFT]
    sta VAR_MODE

    ;; call "Entry Mode" function
    ldx #CTRL_E
    stx IO_A
    sta IO_B
    stz IO_A

    rts
.scend


;;
;; dsp_print: Print a message
;;
;; Parameters: VAR_MESSAGE_PTR
;;
;; Registers Used: A, Y
;;
.scope
dsp_print:
    jsr dsp_wait_idle

    ldy #$00 ;; Y is array index

_loop:
    ;; load the character into IO B
    lda (VAR_MESSAGE_PTR),y
    beq _end
    sta IO_B

    ;; pulse E
    lda #[CTRL_RS | CTRL_E]
    sta IO_A
    lda #CTRL_RS
    sta IO_A

    ;; wait for character to write (40us)
    lda #3
    jsr delay_us

    ;; advance to next character
    iny
    jmp _loop

_end:
    rts
.scend


;;
;; dsp_wait_idle: Wait for display idle
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.scope
dsp_wait_idle:
    ;; set port B to input
    lda #DIR_IN
    sta DDR_B

    ;; set flags for reading the instruction register
    lda #[CTRL_RW | CTRL_E]
    sta IO_A

_loop:
    ;; read the instruction register and loop until not busy
    lda IO_B
    and #BUSY_FLAG
    bne _loop

_cleanup:
    ;; set port B back to output
    lda #DIR_OUT
    sta DDR_B
    rts
.scend