;;
;; entry.s - Main entry point for 6502 code
;;

.require "ram.s"
.require "rng.s"
.require "delay.s"
.require "display.s"
.require "peripheral.s"


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
.space VAR_ADVANCE      1

.text
messages:
    .word message1
    .word message2
    .word message3
    .word message4
    .word 0
message1: .byte "Justin Dubs     ",0
message2: .byte "Leslie Dubs     ",0
message3: .byte "Anya Dubs       ",0
message4: .byte "Miles Dubs      ",0

.text
on_reset:
    ;; initialize stack pointer
    ldx #$ff
    txs

    ;; initialize hardware
    jsr per_init
    jsr dsp_init
    jsr rng_init

    ;; initialize variables
    stz VAR_IRQ_COUNTER
    stz VAR_MESSAGE_IDX
    stz VAR_ADVANCE

    ;; print message
    lda VAR_MESSAGE_IDX
    asl
    tax
    lda messages,x
    sta VAR_MESSAGE_PTR
    inx
    lda messages,x
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_1

    ;; set timer 1 to continuous, free-run mode
    lda #$40
    sta REG_ACR

    ;; enable timer 1 interrupt
    lda #[IER_SET | IRQ_TIMER_1]
    sta REG_IER

    ;; set timer to fire every 50000 cycles (50ms)
    lda #[<50000]
    sta REG_T1C_L
    lda #[>50000]
    sta REG_T1C_H

    ;; enable interrupts
_enter_loop:
    cli

_loop:
    ;; spin until VAR_ADVANCE is set
    lda VAR_ADVANCE
    beq _loop

    ;; disable interrupts
    sei

    ;; reset VAR_ADVANCE
    stz VAR_ADVANCE

    ;; go to next message
    lda VAR_MESSAGE_IDX
    inc
    and #$03
    sta VAR_MESSAGE_IDX

    ;; refresh the display
    asl
    tax
    lda messages,x
    sta VAR_MESSAGE_PTR
    inx
    lda messages,x
    sta [VAR_MESSAGE_PTR+1]

    jsr dsp_home
    jsr dsp_print_2

    jmp _enter_loop
.scend


;;
;; on_irq
;;
.scope
.data ram
.space VAR_IRQ_COUNTER  1

.text
on_irq:
    ;; save accum value
    pha

    ;; clear the interrupt
    lda #$ff
    sta REG_IFR

    ;; increment the counter
    inc VAR_IRQ_COUNTER
    lda VAR_IRQ_COUNTER

    ;; if 1s has elapsed, set VAR_ADVANCE and clear the IRQ_COUNTER
    cmp #20
    bne _end
    inc VAR_ADVANCE
    stz VAR_IRQ_COUNTER

_end:
    ;; restore accum value and return
    pla
    rti
.scend
