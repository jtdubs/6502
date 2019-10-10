;;
;; periph.s - Driver for the WC65C22 peripheral controller
;;
;; Exported Functions:
;; - per_init - Initialize the controller
.pc02


;; Exports
.export IER_SET, IER_CLR, IFR_IRQ, IRQ_TIMER_1, IRQ_TIMER_2, IRQ_CB1, IRQ_CB2, IRQ_SR, IRQ_CA1, IRQ_CA2
.export IO_A_NES_DATA, IO_A_NES_LATCH, IO_A_NES_CLK, IO_A_DSP_RS, IO_A_DSP_RW, IO_A_DSP_E
.export REG_IOB, REG_IOA_HS, REG_DDRB, REG_DDRA, REG_T1C_L, REG_T1C_H, REG_T1L_L, REG_T1L_H, REG_T2C_L, REG_T2C_H, REG_SR, REG_ACR, REG_PCR, REG_IFR, REG_IER, REG_IOA
.export DIR_IN, DIR_OUT
.export per_init


;;
;; Memory-mapped Regiser
;;
.segment "PC"
REG_IOB:    .res 1
REG_IOA_HS: .res 1
REG_DDRB:   .res 1
REG_DDRA:   .res 1
REG_T1C_L:  .res 1
REG_T1C_H:  .res 1
REG_T1L_L:  .res 1
REG_T1L_H:  .res 1
REG_T2C_L:  .res 1
REG_T2C_H:  .res 1
REG_SR:     .res 1
REG_ACR:    .res 1
REG_PCR:    .res 1
REG_IFR:    .res 1
REG_IER:    .res 1
REG_IOA:    .res 1

.rodata

;;
;; DDR directions
;;
DIR_IN  = $00
DIR_OUT = $FF


;;
;; Interrupt flags
;;
IER_SET     = $80
IER_CLR     = $00
IFR_IRQ     = $80
IRQ_TIMER_1 = $40
IRQ_TIMER_2 = $20
IRQ_CB1     = $10
IRQ_CB2     = $08
IRQ_SR      = $04
IRQ_CA1     = $02
IRQ_CA2     = $01

;;
;; Port A masks for buttons vs. display control lines
;;
IO_A_NES_DATA  = $01
IO_A_NES_LATCH = $02
IO_A_NES_CLK   = $04
IO_A_DSP_RS    = $20
IO_A_DSP_RW    = $40
IO_A_DSP_E     = $80


;;
;; per_init: Initialize the W65C22 Peripheral Controller
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.code
.proc per_init
    ;; set output pins on port A (NES controller + Display control lines)
    lda #(IO_A_NES_CLK | IO_A_NES_LATCH | IO_A_DSP_RS | IO_A_DSP_RW | IO_A_DSP_E)
    sta REG_DDRA

    ;; set display data pins to outputs
    lda #DIR_OUT
    sta REG_DDRB

    rts
.endproc
