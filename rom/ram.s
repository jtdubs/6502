;;
;; ram.s - RAM functions
;;
;; Exported Functions:
;; - ram_init - Initialize ram
;;
.scope


;;
;; ram_init: Zero out RAM (above the stack)
;;
;; Parameters: None
;;
;; Registers Used: A, Y
;;
.scope
.data zp
.space _VAR_PTR 2
.text
ram_init:
    ;; _VAR_PTR = $0200
    lda #[<$0200]
    sta _VAR_PTR
    lda #[>$0200]
    sta [_VAR_PTR+1]
_zero_page:
    ;; Start at page offset 0
    ldy #$00
    lda #$00
_loop:
    ;; Zero the page
    sta (_VAR_PTR),y
    iny
    bne _loop
_next_page:
    ;; Increment RAM_PTR
    lda [_VAR_PTR+1]
    inc
    sta [_VAR_PTR+1]
    ;; Loop until up to $4000
    cmp #$40
    bne _zero_page
    rts
.scend

.scend
