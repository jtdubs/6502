;; Memory Map:
;; 0000 - 00ff:    RAM - Free (Zero Page)
;; 0100 - 01ff:    RAM - Stack
;; 0200 - 0202:    RAM - Display Variables
;; 0203 - 3fff:    RAM - Free
;; 4000 - 5fff:    NOT MAPPED
;; 6000 - 600f:    Peripheral Controller Registers
;; 6010 - 7fff:    NOT MAPPED
;; 8000 - ffff:    ROM


;;
;; zero page definitions
;;

.alias VAR_MESSAGE_PTR  $00


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
on_reset:
    ;; initialize stack pointer
    ldx #$ff
    txs

    ;; initialize hardware
    jsr per_init
    jsr dsp_init

    ;; print message
    lda #<message
    sta VAR_MESSAGE_PTR
    lda #>message
    sta [VAR_MESSAGE_PTR+1]
    jsr print_message

_loop:
    ;; read the button states and dispatch
    ldx IO_A
    jmp _loop
.scend




;;
;; print_message: Print the "messaage" to the dislay
;;
;; Parameters: Y - Zero-page index of message pointer
;;
;; Registers Used: A, Y
;;
.scope
print_message:
    jsr dsp_wait_idle

    ldy #$00 ;; Y is array index

_loop:
    ;; load the character into IO B
    lda (VAR_MESSAGE_PTR),y
    beq _end
    sta IO_B

    ;; set E high
    lda #[CTRL_RS | CTRL_E]
    sta IO_A

    ;; set E low
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
;; DATA SEGMENT starts at end of EEPROM
;;
.advance $f000, $ff

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
