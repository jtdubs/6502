;;
;; Dependencies
;;
.require "periph.s"


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
.alias PARAM_FN_2LINE         $80
.alias PARAM_FN_1LINE         $00
.alias PARAM_FN_5x10          $40
.alias PARAM_FN_5x8           $00
.alias BUSY_FLAG              $80


;;
;; dsp_init: Initialize the HD44780 Display Controller
;;
;; Registers Used: A, X
;;
.scope
dsp_init:
	ldx #CTRL_E

	jsr dsp_wait_idle

	;; Call "Function set" with Data Length = 8-bit, Display Lines = 2, Font = 5x7
	stx IO_A
	lda #[FN_FUNCTION_SET | PARAM_FN_8BIT | PARAM_FN_2LINE | PARAM_FN_5x8]
	sta IO_B
	stz IO_A
	
	jsr dsp_wait_idle

	;; Call "Display on/off control" with Display on, Cursor on, blink on
	stx IO_A
	lda #[FN_DISPLAY_CONTROL | PARAM_DC_DISPLAY_ON | PARAM_DC_CURSOR_ON | PARAM_DC_BLINK_ON]
	sta IO_B
	stz IO_A

	jsr dsp_wait_idle

	;; Call "Entry mode set" with Auto Increment enabled
	stx IO_A
	lda #[FN_ENTRY_MODE | PARAM_ENTRY_MODE_INC]
	sta IO_B
	stz IO_A

	jsr dsp_wait_idle

	;; Call "Clear display"
	stx IO_A
	lda #FN_CLEAR
	sta IO_B
	stz IO_A

	;; set E back high in prep for next call
	stx IO_A

	rts
.scend


;;
;; dsp_wait_idle: Wait for display idle
;;
;; Registers: A
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
