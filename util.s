;;
;; delay: Delay by A NOPs (1 NOP = 2us)
;;
.scope
delay:
	dec
	bne delay
	rts
.scend


;;
;; delay_long: Delay by A * 255 NOPs (1 NOP = 2us)
;;
.scope
delay_long:
	ldx #255
_loop:
	dex
	bne _loop
	dec
	bne delay_long
	rts
.scend
