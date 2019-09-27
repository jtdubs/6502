;;
;; periph.s - Driver for the WC65C22 peripheral controller
;;
;; Functions:
;; - per_init - Initialize the controller


;;
;; Memory-mapped Regiser Definitions
;;
.alias IO_A  $600F
.alias IO_B  $6000
.alias DDR_A $6003
.alias DDR_B $6002


;;
;; DDR directions
;;
.alias DIR_IN  $00
.alias DIR_OUT $ff


;;
;; Port A masks for buttons vs. display control lines
;;
.alias IO_A_BTN_MASK $1F
.alias IO_A_DSP_MASK $E0


;;
;; per_init: Initialize the W65C22 Peripheral Controller
;;
;; Parameters: None
;;
;; Registers Used: A
;;
.scope
per_init:
    ;; set display control pins to outputs
    lda #IO_A_DSP_MASK
    sta DDR_A
    rts
.scend
