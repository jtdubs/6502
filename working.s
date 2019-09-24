.alias PER_IO_A  $600F
.alias PER_IO_B  $6000
.alias PER_DDR_A $6003
.alias PER_DDR_B $6002
.alias PER_AUX   $600B

.alias PER_A_BTN    $01
.alias PER_A_BTN_U  $02
.alias PER_A_BTN_D  $04
.alias PER_A_BTN_L  $08
.alias PER_A_BTN_R  $10
.alias PER_A_DSP_RS $20
.alias PER_A_DSP_RW $40
.alias PER_A_DSP_E  $80

;;
;; CODE SEGMENT starts at 0x8000 which is the beginnnig of the EEPROM
;;

.advance $8000, $ff

;;
;; on_reset: Main entry point
;;
.scope
on_reset:
	jsr per_init
	jsr dsp_init
	jsr print_message

_loop:
	; read the button states and dispatch
	ldx PER_IO_A
    jmp _loop
.scend


;;
;; per_init: Initialize the peripheral controller
;;
;; Registers: A
;;
.scope
per_init:
	;; set buttons to inputs (low 5 pins of port A), and high three to outputs
    lda #$E0
    sta PER_DDR_A
	rts
.scend


;;
;; dsp_init: Initialize the display
;;
;; Registers: A, X
;;
;; Side Effects:
;; - Port A:E bit set
;;
.scope
dsp_init:
	ldx #$80 ;; E

	jsr dsp_wait_idle

	;; Call "Function set" with Data Length = 8-bit, Display Lines = 2, Font = 5x7
	stx PER_IO_A
	lda #$38
	sta PER_IO_B
	stz PER_IO_A
	
	jsr dsp_wait_idle

	;; Call "Display on/off control" with Display on, Cursor on, blink on
	stx PER_IO_A
	lda #$0F
	sta PER_IO_B
	stz PER_IO_A

	jsr dsp_wait_idle

	;; Call "Entry mode set" with Auto Increment enabled
	stx PER_IO_A
	lda #$06
	sta PER_IO_B
	stz PER_IO_A

	jsr dsp_wait_idle

	;; Call "Clear display"
	stx PER_IO_A
	lda #$01
	sta PER_IO_B
	stz PER_IO_A

	;; set E back high in prep for next call
	stx PER_IO_A

	rts
.scend


;;
;; dsp_wait_idle: Wait for display idle
;;
;; Registers: A
;;
;; Side Effects:
;; - PER_IO_B set to OUTPUT
;; - PER_IO_A RW & E flags set
;;
.scope
dsp_wait_idle:
	;; set port B to input
    lda #$00
    sta PER_DDR_B
	;; set flags for reading the instruction register
	lda #$C0 ;; RW | E
	sta PER_IO_A
_loop:
	;; read the instruction register and loop until not busy
	lda PER_IO_B
	and #$80 ;; busy flag
	bne _loop
_cleanup:
	;; set port B back to output
    lda #$FF
    sta PER_DDR_B
	rts
.scend


;;
;; delay: Delay by A NOPs (1 NOP = 2us)
;;
.scope
delay:
	dec
	bne delay
	rts
.scend


;;
;; delay_long: Delay by A * 255 NOPs (1 NOP = 2us)
;;
.scope
delay_long:
	ldx #255
_loop:
	dex
	bne _loop
	dec
	bne delay_long
	rts
.scend


;;
;; print_message: Print the "messaage" to the dislay
;;
.scope
print_message:
	jsr dsp_wait_idle

	;; array index
	ldx #$00

_loop:
	ldy message,x
	beq _end

	lda #$A0 ;; RS | E
	sta PER_IO_A
	sty PER_IO_B
	lda #$20 ;; RS
	sta PER_IO_A

	lda #20
	jsr delay

	inx
	jmp _loop

_end:
	rts
.scend


;;
;; DATA SEGMENT starts at 0x9000 which is at offset 0x1000 on the EEPROM
;;
.advance $9000, $ff

message: .byte "Hello, world!",0


;;
;; VECTOR TABLEs start at 0xFFF4, which is at the end of the EEPROM
;;
.advance $fff4, $ff

vector_table:
	.word $0000 ; cop
	.word $0000 ; --
	.word $0000 ; abort
	.word $0000 ; nmi
	.word on_reset
	.word $0000 ; irq / brk
