;;
;; entry.s - Main entry point for 6502 code
;;

.require "util.s"
.require "periph.s"
.require "display.s"


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
.data ram
.space VAR_MESSAGE_IDX  1
.space VAR_BUTTON_STATE 1

.text
messages:
    .word message1
    .word message2
    .word message3
    .word message4
    .word 0
message1: .byte "Justin Dubs",0
message2: .byte "Leslie Dubs",0
message3: .byte "Anya Dubs",0
message4: .byte "Miles Dubs",0

.text
on_reset:
    ;; initialize stack pointer
    ldx #$ff
    txs

    ;; initialize hardware
    jsr ram_init
    jsr per_init
    jsr dsp_init
    jsr rng_init

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

    ;; wait 10ms
    lda #10
    jsr delay_ms

    ;; re-sample and 'or' with previous result to de-bounce
    lda VAR_BUTTON_STATE
    ora IO_A
    tax

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
