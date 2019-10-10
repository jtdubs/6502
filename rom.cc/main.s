;;
;; main.s - defines the memory map and pulls in the code and data
;;
.pc02


;; Imports from Peripheral Controller
.import REG_IER, REG_IFR, REG_ACR, REG_T1C_L, REG_T1C_H, per_init
.importzp IRQ_TIMER_1, IER_SET

;; Imports from Display
.import dsp_init

;; Imports from Game
.import VAR_INPUT_TICK, VAR_DISPLAY_TICK, game_run



;;
;; Variables
;;
.data
VAR_IRQ_COUNTER: .res 1


;;
;; on_reset: Main Entry Point
;;
.code
.proc on_reset
    ;; initialize stack pointer
    ldx #$FF
    txs

    ;; initialize hardware
    jsr per_init
    jsr dsp_init

    ;; initialize variables
    stz VAR_IRQ_COUNTER

    ;; set timer to fire every 50000 cycles (10ms)
    lda #<10000
    sta REG_T1C_L
    lda #>10000
    sta REG_T1C_H

    ;; set timer 1 to continuous, free-run mode
    lda #$40
    sta REG_ACR

    ;; enable timer 1 interrupt
    lda #<(IER_SET | IRQ_TIMER_1)
    sta REG_IER

    ;; run the game
    jsr game_run
.endproc


;;
;; on_irq
;;
.code
.proc on_irq
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

    ;; if 10ms elapsed, process input
    inc VAR_INPUT_TICK

    ;; if 250ms has elapsed,refresh display
    cmp #25
    bcc _end
    inc VAR_DISPLAY_TICK
    stz VAR_IRQ_COUNTER

_not_timer_1:
    ;; clear the interrupt
    lda #$FF
    sta REG_IFR
    jmp _end

_end:
    ;; restore accum value and return
    pla
    rti
.endproc


;;
;; on_nmi
;;
.code
.proc on_nmi
    rti
.endproc


;;
;; on_abort
;;
.code
.proc on_abort
    rti
.endproc


;;
;; on_cop
;;
.code
.proc on_cop
    rti
.endproc


;;
;; Vector Table
;;

.segment "VECTORS"
.word on_cop
.word $0000
.word on_abort
.word on_nmi
.word on_reset
.word on_irq
