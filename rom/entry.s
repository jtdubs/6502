;;
;; entry.s - Main entry point for 6502 code
;;
;; Exported Functions:
;; - on_reset - Initialize hardware and start the game
;; - on_irq   - Handle Timer 1 interrupts and notify the game
;; - on_nmi   - NOP
;; - on_abort - NOP
;; - on_cop   - NOP
;;
.scope

.require "ram.s"
.require "display.s"
.require "peripheral.s"
.require "game.s"

;;
;; Variables
;;
.data
.space _VAR_IRQ_COUNTER 1


;;
;; on_reset: Main Entry Point
;;
.scope
.text
on_reset:
    ;; initialize stack pointer
    ldx #$FF
    txs

    ;; initialize hardware
    jsr per_init
    jsr dsp_init

    ;; initialize variables
    stz _VAR_IRQ_COUNTER

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

    ;; run the game
    jsr game_run
.scend


;;
;; on_irq
;;
.scope
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
    inc _VAR_IRQ_COUNTER
    lda _VAR_IRQ_COUNTER

    ;; if 250ms has elapsed, let the game do something and clear the IRQ_COUNTER
    cmp #5
    bcc _end
    .invoke game_interrupt
    stz _VAR_IRQ_COUNTER

_not_timer_1:
    ;; clear the interrupt
    lda #$FF
    sta REG_IFR
    jmp _end

_end:
    ;; restore accum value and return
    pla
    rti
.scend


;;
;; on_nmi
;;
.scope
.text
on_nmi:
    rti
.scend


;;
;; on_abort
;;
.scope
.text
on_abort:
    rti
.scend


;;
;; on_cop
;;
.scope
.text
on_cop:
    rti
.scend

.scend
