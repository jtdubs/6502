;; Memory Map:
;; 0000 - 0001:    RAM - Zero Page - VAR_MESSAGE_PTR
;; 0002 - 0003:    RAM - Zero Page - VAR_RAM_PTR
;; 0004 - 00ff:    RAM - Zero Page - FREE
;; 0100 - 01ff:    RAM - Stack
;; 0200 - 0202:    RAM - Display Variables
;; 0203 - 0204:    RAM - Main Variables
;; 0205 - 3fff:    RAM - FREE
;; 4000 - 5fff:    NOT MAPPED
;; 6000 - 600f:    Peripheral Controller Registers
;; 6010 - 7fff:    NOT MAPPED
;; 8000 - ffff:    ROM


;;
;; CODE SEGMENT starts at 0x8000 which is the beginnnig of the EEPROM
;;

.advance $8000, $ff

.require "util.s"
.require "periph.s"
.require "display.s"

;;
;; Variables
;;
.alias VAR_MESSAGE_IDX  $0203
.alias VAR_BUTTON_STATE $0204


;;
;; Buttons
;;
.alias BTN_TRIGGER  $01
.alias BTN_UP       $02
.alias BTN_DOWN     $04
.alias BTN_LEFT     $08
.alias BTN_RIGHT    $10


;;
;; on_reset: Main Entry Point
;;
.scope
on_reset:
    ;; initialize stack pointer
    ldx #$ff
    txs

    ;; initialize hardware
_hw_init:
    jsr zero_ram
    jsr per_init
    jsr dsp_init

    ;; initial message index and button state are 0
    stz VAR_MESSAGE_IDX
    stz VAR_BUTTON_STATE

    ;; print message
    lda VAR_MESSAGE_IDX
    asl
    tax
    lda messages,x
    sta VAR_MESSAGE_PTR
    inx
    lda messages,x
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print

_loop:
    ;; read the button state
    ldx IO_A

    ;; if button state hasn't changed, keep looping
    txa
    cmp VAR_BUTTON_STATE
    beq _loop
    sta VAR_BUTTON_STATE

    ;; call button events
    and #BTN_UP
    beq _on_up
    txa
    and #BTN_DOWN
    beq _on_down
    jmp _loop

_on_up:
    ;; on UP button, increment message index, up to 3
    lda VAR_MESSAGE_IDX
    cmp #03
    beq _loop
    inc
    sta VAR_MESSAGE_IDX
    jmp _refresh

_on_down:
    ;; on DOWN button, decrement message index, down to 0
    lda VAR_MESSAGE_IDX
    cmp #00
    beq _loop
    dec
    sta VAR_MESSAGE_IDX
    jmp _refresh

_refresh:
    ;; refresh the display based on new message index
    asl
    tax
    lda messages,x
    sta VAR_MESSAGE_PTR
    inx
    lda messages,x
    sta [VAR_MESSAGE_PTR+1]

    jsr dsp_clear
    jsr dsp_print

    jmp _loop
.scend


;;
;; DATA SEGMENT starts at end of EEPROM
;;

.advance $f000, $ff

messages:
    .word message1
    .word message2
    .word message3
    .word message4
    .word 0

message1: .byte "Hello, world!",0
message2: .byte "Goodbye, world!",0
message3: .byte "OMG WTF BBQ",0
message4: .byte ".............",0


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
