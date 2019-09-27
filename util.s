;;
;; util.s - Utility functions
;;
;; Functions:
;; - delay_us - Delay by multiple of 10us
;; - delay_ms - Delay by multiple o 1ms
;;


;;
;; delay_us: A short delay busy-loop
;;
;; Parameters:
;; - A - Delay is A * 10us + 10us
;;
;; Registers Used: A
;;
.scope
delay_us:
    dec             ;; 2 cycles
    jmp _target     ;; 3 cycles
_target:
    nop             ;; 2 cycles
    bne delay_us    ;; 3 cycles
    nop             ;; 2 cycles
    rts             ;; 8 cycles
.scend


;;
;; delay_ms: A long delay busy-loop
;;
;; Parameters:
;; - A - Delay is A milliseconds + 8us
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
