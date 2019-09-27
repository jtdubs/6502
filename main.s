;;
;; CODE SEGMENT starts at 0x8000 which is the beginnnig of the EEPROM
;;

.advance $8000, $ff

.require "util.s"
.require "periph.s"
.require "display.s"


;;
;; on_reset: Main Entry Point
;;
.scope
    ;; initialize stack pointer
    ldx #$ff
    txs

on_reset:
    ;; initialize hardware
    jsr per_init
    jsr dsp_init

    ;; print the welcome message
    jsr print_message

_loop:
    ;; read the button states and dispatch
    ldx IO_A
    jmp _loop
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

    lda #[CTRL_RS | CTRL_E]
    sta IO_A
    sty IO_B
    lda #CTRL_RS
    sta IO_A

    lda #3
    jsr delay_us

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
