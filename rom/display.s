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
;; - _dsp_wait_idle     - Wait for display idle
;;
.scope


;;
;; Display Control Lines
;;
.alias _RS $20
.alias _RW $40
.alias _E  $80


;;
;; Functions IDs
;;
.alias _FN_CLEAR           $01
.alias _FN_HOME            $02
.alias _FN_ENTRY_MODE      $04
.alias _FN_DISPLAY_CONTROL $08
.alias _FN_SHIFT           $10
.alias _FN_FUNCTION_SET    $20
.alias _FN_SET_CGRAM_ADDR  $40
.alias _FN_SET_DDRAM_ADDR  $80


;;
;; Function Parameters
;;
.alias _PARAM_ENTRY_MODE_INC   $02
.alias _PARAM_ENTRY_MODE_DEC   $00
.alias _PARAM_ENTRY_MODE_SHIFT $01

.alias _PARAM_DC_DISPLAY_ON    $04
.alias _PARAM_DC_CURSOR_ON     $02
.alias _PARAM_DC_BLINK_ON      $01

.alias _PARAM_SHIFT_SCREEN     $80
.alias _PARAM_SHIFT_CURSOR     $00
.alias _PARAM_SHIFT_RIGHT      $40
.alias _PARAM_SHIFT_LEFT       $00

.alias _PARAM_FN_8BIT          $10
.alias _PARAM_FN_4BIT          $00
.alias _PARAM_FN_2LINE         $08
.alias _PARAM_FN_1LINE         $00
.alias _PARAM_FN_5x10          $04
.alias _PARAM_FN_5x8           $00

.alias _BUSY_FLAG              $80


;;
;; Zero-page Variables
;;

.data zp
.space VAR_DSP_MESSAGE_PTR 2


;;
;; RAM Data
;;

.data
.space _VAR_FUNCTION 1
.space _VAR_CONTROL  1
.space _VAR_MODE     1


;;
;; dsp_init: Initialize the HD44780 Display Controller
;;
;; Parameters: None
;;
;; Registers Used: A, X
;;
.scope
.text
dsp_init:
    ldx #_E

    ;;
    ;; Initialize variables with default values for each function
    ;;

    ;; 8-bit chars, 2 line display, 5x8 font
    lda #[_FN_FUNCTION_SET | _PARAM_FN_8BIT | _PARAM_FN_2LINE | _PARAM_FN_5x8]
    sta _VAR_FUNCTION

    ;; display, cursor & blink on
    lda #[_FN_DISPLAY_CONTROL | _PARAM_DC_DISPLAY_ON]
    sta _VAR_CONTROL

    ;; auto-increment on output
    lda #[_FN_ENTRY_MODE | _PARAM_ENTRY_MODE_INC]
    sta _VAR_MODE


    ;;
    ;; Perform initialization routine based on datasheet
    ;;

    ;; call "Function Set"
    jsr _dsp_wait_idle
    stx REG_IOA
    lda _VAR_FUNCTION
    sta REG_IOB
    stz REG_IOA

    ;; Call "Display Control"
    jsr _dsp_wait_idle
    stx REG_IOA
    lda _VAR_CONTROL
    sta REG_IOB
    stz REG_IOA

    ;; Call "Entry mode Set"
    jsr _dsp_wait_idle
    stx REG_IOA
    lda _VAR_MODE
    sta REG_IOB
    stz REG_IOA

    ;; Call "Clear display"
    jsr _dsp_wait_idle
    stx REG_IOA
    lda #_FN_CLEAR
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_clear:
    jsr _dsp_wait_idle

    ;; Call "Clear"
    lda #_E
    sta REG_IOA
    lda #_FN_CLEAR
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_home:
    jsr _dsp_wait_idle

    ;; Call "Home"
    lda #_E
    sta REG_IOA
    lda #_FN_HOME
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_display_on:
    jsr _dsp_wait_idle

    ;; set Display bit in VAR_DSP_CONTROL
    lda _VAR_CONTROL
    ora #_PARAM_DC_DISPLAY_ON
    sta _VAR_CONTROL

    ;; call "Display Control" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_display_off:
    jsr _dsp_wait_idle

    ;; clear Display bit in VAR_DSP_CONTROL
    lda _VAR_CONTROL
    and #[$FF ^ _PARAM_DC_DISPLAY_ON]
    sta _VAR_CONTROL

    ;; call "Display Control" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_cursor_on:
    jsr _dsp_wait_idle

    ;; set Cursor bit in VAR_DSP_CONTROL
    lda _VAR_CONTROL
    ora #_PARAM_DC_CURSOR_ON
    sta _VAR_CONTROL

    ;; call "Display Control" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_cursor_off:
    jsr _dsp_wait_idle

    ;; clear Cursor bit in VAR_DSP_CONTROL
    lda _VAR_CONTROL
    and #[$FF ^ _PARAM_DC_CURSOR_ON]
    sta _VAR_CONTROL

    ;; call "Display Control" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_blink_on:
    jsr _dsp_wait_idle

    ;; set Blink bit in VAR_DSP_CONTROL
    lda _VAR_CONTROL
    ora #_PARAM_DC_BLINK_ON
    sta _VAR_CONTROL

    ;; call "Display Control" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_blink_off:
    jsr _dsp_wait_idle

    ;; clear Cursor bit in VAR_DSP_CONTROL
    lda _VAR_CONTROL
    and #[$FF ^ _PARAM_DC_BLINK_ON]
    sta _VAR_CONTROL

    ;; call "Display Control" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_scroll_left:
    jsr _dsp_wait_idle

    ;; call "Shift" function
    ldx #_E
    stx REG_IOA
    lda #[_FN_SHIFT | _PARAM_SHIFT_SCREEN | _PARAM_SHIFT_LEFT]
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_scroll_right:
    jsr _dsp_wait_idle

    ;; call "Shift" function
    ldx #_E
    stx REG_IOA
    lda #[_FN_SHIFT | _PARAM_SHIFT_SCREEN | _PARAM_SHIFT_RIGHT]
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_autoscroll_on:
    jsr _dsp_wait_idle

    ;; set Shift bit in VAR_DSP_MODE
    lda _VAR_MODE
    ora #_PARAM_ENTRY_MODE_SHIFT
    sta _VAR_MODE

    ;; call "Entry Mode" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

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
.text
dsp_autoscroll_off:
    jsr _dsp_wait_idle

    ;; clear Shift bit in VAR_DSP_MODE
    lda _VAR_MODE
    and #[$FF ^ _PARAM_ENTRY_MODE_SHIFT]
    sta _VAR_MODE

    ;; call "Entry Mode" function
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    rts
.scend


;;
;; dsp_print_1: Print a message
;;
;; Registers Used: A, Y
;;
.scope
.text
dsp_print_1:
    jsr _dsp_wait_idle

    ;; set ddram address to 0 (start of line 1)
    lda #[_FN_SET_DDRAM_ADDR | $00]
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr _dsp_wait_idle

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
    lda #[_RS | _E]
    sta REG_IOA
    lda #_RS
    sta REG_IOA

    ;; wait for character to write (40us)
    lda #2
    jsr delay_us

    ;; advance to next character
    iny
    jmp _loop

_end:
    rts
.scend


;;
;; dsp_print_2: Print a message
;;
;; Registers Used: A, Y
;;
.scope
.text
dsp_print_2:
    jsr _dsp_wait_idle

    ;; set ddram address to $40 (start of line 2)
    lda #[_FN_SET_DDRAM_ADDR | $40]
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr _dsp_wait_idle

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
    lda #[_RS | _E]
    sta REG_IOA
    lda #_RS
    sta REG_IOA

    ;; wait for character to write (40us)
    lda #2
    jsr delay_us

    ;; advance to next character
    iny
    jmp _loop

_end:
    rts
.scend


;;
;; dsp_blit: Blit a buffer to the display
;;
;; Registers Used: A, Y
;;
.scope
.text
dsp_blit:
_setup_1:
    jsr _dsp_wait_idle

    ;; set ddram address to 0 (start of line 1)
    lda #[_FN_SET_DDRAM_ADDR | $00]
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr _dsp_wait_idle

    ldy #$00 ;; Y is array index

_loop_1:
    ;; load the character into IO B
    lda (VAR_DSP_MESSAGE_PTR),y
    sta REG_IOB

    ;; pulse E
    lda #[_RS | _E]
    sta REG_IOA
    lda #_RS
    sta REG_IOA

    ;; wait for character to write (40us)
    lda #2
    jsr delay_us

    ;; advance to next character
    iny
    cpy #$10
    bmi _loop_1

_setup_2:
    jsr _dsp_wait_idle

    ;; set ddram address to $40 (start of line 2)
    lda #[_FN_SET_DDRAM_ADDR | $40]
    ldx #_E
    stx REG_IOA
    sta REG_IOB
    stz REG_IOA

    jsr _dsp_wait_idle

    ldy #$40 ;; Y is array index

_loop_2:
    ;; load the character into IO B
    lda (VAR_DSP_MESSAGE_PTR),y
    sta REG_IOB

    ;; pulse E
    lda #[_RS | _E]
    sta REG_IOA
    lda #_RS
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
.scend


;;
;; _dsp_wait_idle: Wait for display idle
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.text
_dsp_wait_idle:
.scope
    ;; set port B to input
    lda #DIR_IN
    sta REG_DDRB

    ;; set flags for reading the instruction register
    lda #[_RW | _E]
    sta REG_IOA

_loop:
    ;; read the instruction register and loop until not busy
    lda REG_IOB
    and #_BUSY_FLAG
    bne _loop

_cleanup:
    ;; set port B back to output
    lda #DIR_OUT
    sta REG_DDRB
    rts
.scend

.scend
