;;
;; rng.s - Random number generation
;;
;; Exported Functions:
;; - rng_init - Initilize the random number generator
;; - rand     - Generate a random number
;;
.pc02


;; Imports from Peripheral Controller
.import REG_T1C_H, REG_T1C_L

;: Exports
.export rng_init, rand


;;
;; Zero Page Variables
;;

.data
VAR_SEED: .res 2


;;
;; rng_init: Initialize the Random Number generator
;;
;; Registers used: A
;;
.code
.proc rng_init
    lda REG_T1C_L
    sta VAR_SEED+0
    lda REG_T1C_H
    sta VAR_SEED+1
    rts
.endproc


;;
;; rand: Generate an 8-bit Random Number
;;
;; Reference: https://wiki.nesdev.com/w/index.php/Random_number_generator#Linear_feedback_shift_register
;;
;; Parameters: None
;;
;; Registers used: A, Y
;;
;; Return Value: A
;;
.code
.proc rand
    ldy #8
    lda VAR_SEED+0
_loop:
    asl
    rol VAR_SEED+1
    bcc _skip
    eor #$39
_skip:
    dey
    bne _loop
    sta VAR_SEED+0
    rts
.endproc
