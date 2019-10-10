;;
;; periph.s - Driver for the WC65C22 peripheral controller
;;
;; Exported Functions:
;; - per_init - Initialize the controller
.scope


;;
;; Memory-mapped Regiser
;;
.data pc
.space REG_IOB    1
.space REG_IOA_HS 1
.space REG_DDRB   1
.space REG_DDRA   1
.space REG_T1C_L  1
.space REG_T1C_H  1
.space REG_T1L_L  1
.space REG_T1L_H  1
.space REG_T2C_L  1
.space REG_T2C_H  1
.space REG_SR     1
.space REG_ACR    1
.space REG_PCR    1
.space REG_IFR    1
.space REG_IER    1
.space REG_IOA    1


;;
;; DDR directions
;;
.alias DIR_IN  $00
.alias DIR_OUT $FF


;;
;; Interrupt flags
;;
.alias IER_SET     $80
.alias IER_CLR     $00
.alias IFR_IRQ     $80
.alias IRQ_TIMER_1 $40
.alias IRQ_TIMER_2 $20
.alias IRQ_CB1     $10
.alias IRQ_CB2     $08
.alias IRQ_SR      $04
.alias IRQ_CA1     $02
.alias IRQ_CA2     $01


;;
;; Port A masks for buttons vs. display control lines
;;
.alias IO_A_NES_DATA  $01
.alias IO_A_NES_LATCH $02
.alias IO_A_NES_CLK   $04
.alias IO_A_DSP_RS    $20
.alias IO_A_DSP_RW    $40
.alias IO_A_DSP_E     $80


;;
;; per_init: Initialize the W65C22 Peripheral Controller
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.scope
.text
per_init:
    ;; set output pins on port A (NES controller + Display control lines)
    lda #[IO_A_NES_CLK | IO_A_NES_LATCH | IO_A_DSP_RS | IO_A_DSP_RW | IO_A_DSP_E]
    sta REG_DDRA

    ;; set display data pins to outputs
    lda #DIR_OUT
    sta REG_DDRB

    rts
.scend

.scend
