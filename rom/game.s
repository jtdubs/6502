;;
;; game.s - Game code
;;
;; Functions:
;; - game_init      - Initialize the game
;; - game_run       - Run the game
;; - game_interrupt - Macro to handle 250ms ticks
;;

.require "rng.s"
.require "delay.s"
.require "display.s"
.require "peripheral.s"


;;
;; Buttons
;;
.alias BTN_TRIGGER  $01
.alias BTN_UP       $02
.alias BTN_DOWN     $04
.alias BTN_LEFT     $08
.alias BTN_RIGHT    $10


;;
;; Game Data
;;

.data zp
.space VAR_TICK    1
.space VAR_LINE_1  17
.space VAR_LINE_2  17

.text
intro1: .byte "  Trivial Game  ",0
intro2: .byte " by Justin Dubs ",0


;;
;; game_init: Game Initialization
;;
.scope
.text
game_init:
    ;; initialize variables
    stz VAR_TICK

    ; initialize display buffers
    lda #'a
    ldy 16
_clear_line_1:
    dey
    sta VAR_LINE_1,y
    bne _clear_line_1
    stz [VAR_LINE_1+16]

    lda #'A
    ldy 16
_clear_line_2:
    dey
    sta VAR_LINE_2,y
    bne _clear_line_2
    stz [VAR_LINE_2+16]
.scend


;;
;; game_run: Game entry point
;;
.scope
.text
game_run:
    ;; do the intro
    jsr game_intro

_enter_game_loop:
    ;; enable interrupts
    cli

_game_loop:
    ;; wait for 250ms
    lda VAR_TICK
    cmp #$01
    bcc _game_loop

    ;; disable interrupts
    sei

    ;; reset VAR_TICK
    stz VAR_TICK

    ;; blah
    inc VAR_LINE_1

    ;; re-paint display
    lda #[<VAR_LINE_1]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>VAR_LINE_1]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_1

    lda #[<VAR_LINE_2]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>VAR_LINE_2]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_2

    jmp _enter_game_loop
.scend


;;
;; game_intro: Show the intro screen
;;
.scope
.text
game_intro:
    ;; print intro message
    lda #[<intro1]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>intro1]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_1

    lda #[<intro2]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>intro2]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_2

    ;; enable interrupts
    cli

_loop:
    ;; wait for 4 seconds (16 * 250ms)
    lda VAR_TICK
    cmp #16
    bcc _loop

    ;; disable interrupts
    sei

    ;; clear the tick counter
    stz VAR_TICK
    rts
.scend


;;
;; 250ms Interrupt Macro
;;
.macro game_interrupt
    inc VAR_TICK
.macend
