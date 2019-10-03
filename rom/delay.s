;;
;; delay.s - Delay functions
;;
;; Functions:
;; - delay_us - Delay by multiple of 10us
;; - delay_ms - Delay by multiple of 1ms
;;


;;
;; delay_us: A short delay busy-loop
;;
;; Parameters:
;; - A - Delay is A * 10us + 20us
;;
;; Registers Used: A
;;
.scope
.text
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
.text
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
