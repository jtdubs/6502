;;
;; rng.s - Random number generation
;;
;; Functions:
;; - rng_init - Initilize the random number generator
;; - rand     - Generate a random number
;;
.scope


;;
;; Zero Page Variables
;;

.data
.space _VAR_SEED 2


;;
;; rng_init: Initialize the Random Number generator
;;
;; Registers used: A
;;
.scope
.text
rng_init:
    lda #$A5
    sta [_VAR_SEED+0]
    lda #$96
    sta [_VAR_SEED+1]
    rts
.scend


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
.scope
.text
rand:
    ldy #8
    lda [_VAR_SEED+0]
_loop:
    asl
    rol [_VAR_SEED+1]
    bcc _skip
    eor #$39
_skip:
    dey
    bne _loop
    sta [_VAR_SEED+0]
    rts
.scend

.scend
