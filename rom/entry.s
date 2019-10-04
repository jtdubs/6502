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
.data zp
.space VAR_ADVANCE 1

.data zp
.space VAR_LINE_1  17
.space VAR_LINE_2  17

.text
intro1: .byte "  Trivial Game  ",0
intro2: .byte " by Justin Dubs ",0

.text
on_reset:
    ;; disable interrupts until after init sequence
    sei

    ;; initialize stack pointer
    ldx #$ff
    txs

    ;; initialize hardware
    jsr per_init
    jsr dsp_init
    jsr rng_init

    ;; initialize variables
    stz VAR_IRQ_COUNTER
    stz VAR_ADVANCE

    ; initialize display buffers
    lda #'a
    ldy 16
_clear_line_1:
    dey
    sta VAR_LINE_1,y
    bne _clear_line_1
    stz [VAR_LINE_1+16]

    lda #'A
    ldy 16
_clear_line_2:
    dey
    sta VAR_LINE_2,y
    bne _clear_line_2
    stz [VAR_LINE_2+16]

    ;; set timer to fire every 50000 cycles (50ms)
    lda #[<50000]
    sta REG_T1C_L
    lda #[>50000]
    sta REG_T1C_H

    ;; set timer 1 to continuous, free-run mode
    lda #$40
    sta REG_ACR

    ;; enable timer 1 interrupt
    lda #[IER_SET | IRQ_TIMER_1]
    sta REG_IER

    ;; print intro message
    lda #[<intro1]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>intro1]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_1

    lda #[<intro2]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>intro2]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_2

_enter_intro_loop:
    ;; enable interrupts
    cli

_intro_loop:
    ;; wait for 4 seconds (16 * 250ms)
    lda VAR_ADVANCE
    cmp #16
    bcc _intro_loop

_enter_game_loop:
    ;; enable interrupts
    cli

_game_loop:
    ;; wait for 250ms
    lda VAR_ADVANCE
    cmp #$01
    bcc _game_loop

    ;; disable interrupts
    sei

    ;; reset VAR_ADVANCE
    stz VAR_ADVANCE

    ;; blah
    inc VAR_LINE_1

    ;; re-paint display
    lda #[<VAR_LINE_1]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>VAR_LINE_1]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_1

    lda #[<VAR_LINE_2]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>VAR_LINE_2]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_2

    jmp _enter_game_loop
.scend


;;
;; on_irq
;;
.scope
.data zp
.space VAR_IRQ_COUNTER  1

.text
on_irq:
    ;; save accum value
    pha

    ;; dispatch the interrupt
    lda REG_IFR
    bpl _end
    and REG_IER
    asl
    bmi _timer_1
    jmp _not_timer_1

_timer_1:
    ;; clear the interrupt
    lda REG_T1C_L

    ;; increment the counter
    inc VAR_IRQ_COUNTER
    lda VAR_IRQ_COUNTER

    ;; if 250ms has elapsed, set VAR_ADVANCE and clear the IRQ_COUNTER
    cmp #5
    bcc _end
    inc VAR_ADVANCE
    stz VAR_IRQ_COUNTER

_not_timer_1:
    ;; clear the interrupt
    lda #$ff
    sta REG_IFR
    jmp _end

_end:
    ;; restore accum value and return
    pla
    rti
.scend
