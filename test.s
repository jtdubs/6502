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

.advance $8000, $ff

reset:

	;; setup the peripheral controller
setup_per:
	;; set buttons to inputs (low 5 pins of port A), and high three to outputs
    ldx #$E0
    stx PER_DDR_A

	;; initialize the display
dsp_init:
	;; set port B to input
    ldx #$00
    stx PER_DDR_B

	;; read the instruction register
	ldx #$C0 ;; RW | E
	stx PER_IO_A

	;; wait for display initialization 
dsp_init_loop:
	lda PER_IO_B
	and #$80 ;; busy flag
	bne dsp_init_loop

	;; set port B to output
    ldx #$FF
    stx PER_DDR_B

	ldx #$80 ;; E

	stx PER_IO_A
	lda #$38 ;; set to 8-bit, 2-line, 5x7 chars
	sta PER_IO_B
	stz PER_IO_A

	stx PER_IO_A
	lda #$0F ;; set display on, cursor on, blink on
	sta PER_IO_B
	stz PER_IO_A

	stx PER_IO_A
	lda #$06 ;; set to auto-increment
	sta PER_IO_B
	stz PER_IO_A

	ldx #$A0 ;; E | RS
	ldy #$20 ;; RS

print_message:
	ldx #$00

print_loop:
	lda message,x
	beq main_loop
	ldy #$A0
	sty PER_IO_A
	sta PER_IO_B
	ldy #$20
	sty PER_IO_A
	inx
	jmp print_loop

main_loop:
	; read the button states and dispatch
	ldx PER_IO_A
    txa
	and #$01
	beq on_btn
    txa
	and #$02
	beq on_up
    txa
	and #$04
	beq on_down
    txa
	and #$08
	beq on_left
    txa
	and #$10
	beq on_right
    jmp main_loop

on_btn:
    nop
    nop
    jmp main_loop

on_up:
    nop
    nop
    jmp main_loop

on_down:
    nop
    nop
    jmp main_loop

on_left:
    nop
    nop
    jmp main_loop

on_right:
    nop
    nop
    jmp main_loop

.advance $9000, $ff
message:
.byte "Hello, world!",0

.advance $fff4, $ff
vector_table:
.word $0000 ; cop
.word $0000 ; --
.word $0000 ; abort
.word $0000 ; nmi
.word $8000 ; reset
.word $0000 ; irq / brk
