;;
;; util.s - Utility functions
;;
;; Functions:
;; - delay_us - Delay by multiple of 10us
;; - delay_ms - Delay by multiple of 1ms
;; - zero_ram - Initialize ram
;; - rng_init - Initilize the random number generator
;; - rand     - Generate a random number
;;


;;
;; Zero Page Variables
;;
.alias VAR_RAM_PTR   $02
.alias VAR_RAND_SEED $04


;;
;; delay_us: A short delay busy-loop
;;
;; Parameters:
;; - A - Delay is A * 10us + 20us
;;
;; Registers Used: A
;;
.scope
delay_us:
    ;; pad loop w/ dummy jmp + nop so each iteration takes 10us
    jmp _dummy      ;; 3 cycles
_dummy:
    nop             ;; 2 cycles
    dec             ;; 2 cycles
    bne delay_us    ;; 3 cycles
_cleanup:
    ;; waste 6 cycles to total non-loop overhead is jsr + 3*nop + rts = 6us + 3*2us + 8us = 20us
    nop             ;; 2 cycles
    nop             ;; 2 cycles
    nop             ;; 2 cycles
    rts             ;; 8 cycles
.scend


;;
;; delay_ms: A long delay busy-loop
;;
;; Parameters:
;; - A - Delay is A milliseconds + 14us (6 for jsr and 8 for rts)
;;
;; Registers Used: A, X
;;
.scope
delay_ms:
    ldx #198        ;; 2 cycles
_loop:
    dex             ;; 2 cycles
    bne _loop       ;; 3 cycles
    jmp _target     ;; 3 cycles
_target:
    dec             ;; 2 cycles
    bne delay_ms    ;; 3 cycles
    rts             ;; 8 cycles
.scend


;;
;; zero_ram: Zero out RAM (above the stack)
;;
;; Parameters: None
;;
;; Registers Used: A, Y
;;
.scope
zero_ram:
    ;; VAR_RAM_PTR = $0200
    lda #[<$0200]
    sta VAR_RAM_PTR
    lda #[>$0200]
    sta [VAR_RAM_PTR+1]
_zero_page:
    ;; Start at page offset 0
    ldy #$00
    lda #$00
_loop:
    ;; Zero the page
    sta (VAR_RAM_PTR),y
    iny
    bne _loop
_next_page:
    ;; Increment RAM_PTR
    lda [VAR_RAM_PTR+1]
    inc
    sta [VAR_RAM_PTR+1]
    ;; Loop until up to $4000
    cmp $40
    bne _zero_page
.scend


;;
;; rng_init: Initialize the Random Number generator
;;
;; Registers used: A
;;
.scope
rng_init:
    lda #$A5
    sta [VAR_RAND_SEED+0]
    lda #$96
    sta [VAR_RAND_SEED+1]
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
rand:
    ldy #8
    lda [VAR_RAND_SEED+0]
_loop:
    asl
    rol [VAR_RAND_SEED+1]
    bcc _skip
    eor #$39
_skip:
    dey
    bne _loop
    sta [VAR_RAND_SEED+0]
    cmp #0
    rts
.scend
