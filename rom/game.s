;;
;; game.s - Game code
;;
;; Functions:
;; - game_init       - Initialize the game
;; - game_run        - Run the game
;; - game_intro      - Show the intro screen
;; - game_loop       - The main loop
;; - game_interrupt  - Macro to handle 250ms ticks
;; - game_redraw     - Redraw the display buffer
;; - game_on_tick    - Handle 250ms tick
;; - game_on_up      - Handle up button
;; - game_on_down    - Handle down button
;; - game_on_left    - Handle left button
;; - game_on_right   - Handle right button
;; - game_on_trigger - Handle trigger button
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
.space VAR_TICK         1   ;; counts 250ms ticks
.space VAR_BUTTON_STATE 1   ;; button state
.space VAR_POS          1   ;; player position
.space VAR_LASER        1   ;; laser position

.data
.space VAR_BUFFER       128 ;; display buffer

.text
intro1: .byte " Squid Defender ",0
intro2: .byte "     10000      ",0
player: .byte $D6,$DB,0
laser:  .byte $A5,0
enemy:  .byte $3C,$BA,$7F,0


;;
;; game_init: Game Initialization
;;
.scope
.text
game_init:
    ;; initialize variables
    stz VAR_TICK
    stz VAR_BUTTON_STATE
    stz VAR_POS
    stz VAR_LASER
    jsr game_redraw
.scend


;;
;; game_run: Game entry point
;;
.scope
.text
game_run:
    ;; do the intro
    jsr game_intro

    ;; enable interrupts
    cli

    ;; enter game loop
    jsr game_loop
.scend


;;
;; game_loop: The main game loop
;;
.scope
.text
game_loop:
    ;; if 250ms elapsed, _on_tick
    lda VAR_TICK
    bne _on_tick

    ;; if button state changed, _on_button_changed
    lda REG_IOA
    cmp VAR_BUTTON_STATE
    bne _on_button_changed

    ;; if neither, loop
    jmp game_loop

_on_button_changed:
    ;; wait for 5ms for results to de-bounce
    sta VAR_BUTTON_STATE
    lda #5
    jsr delay_ms
    lda VAR_BUTTON_STATE
    ora REG_IOA

    ;; dispatch buttons
    tax
    and #BTN_UP
    beq _on_up
    txa
    and #BTN_DOWN
    beq _on_down
    txa
    and #BTN_LEFT
    beq _on_left
    txa
    and #BTN_RIGHT
    beq _on_right
    txa
    and #BTN_TRIGGER
    beq _on_trigger
    jmp _continue_loop
_on_right:
    jsr game_on_right
    jmp _continue_loop
_on_left:
    jsr game_on_left
    jmp _continue_loop
_on_down:
    jsr game_on_down
    jmp _continue_loop
_on_up:
    jsr game_on_up
    jmp _continue_loop
_on_trigger:
    jsr game_on_trigger
    jmp _continue_loop
_on_tick:
    jsr game_on_tick
_continue_loop:
    cli
    jmp game_loop
.scend


;;
;; game_on_tick - Handle game tick by refreshing the display
;;
.scope
.text
game_on_tick:
    ;; reset VAR_TICK
    stz VAR_TICK

    jsr game_update_laser

    ;; re-paint display
    lda #[<VAR_BUFFER]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>VAR_BUFFER]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_1

    lda #[<[VAR_BUFFER+$40]]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>[VAR_BUFFER+$40]]
    sta [VAR_MESSAGE_PTR+1]
    jsr dsp_print_2

    rts
.scend


;;
;; game_update_laser - Update laser position and redraw if needed
;;
.scope
.text
game_update_laser:
    lda VAR_LASER
    beq _end
    inc
    sta VAR_LASER
    and $BF
    cmp #15
    bmi _redraw
    stz VAR_LASER

_redraw:
    jsr game_redraw

_end:
    rts
.scend


;;
;; game_on_up - Move character up
;;
.scope
.text
game_on_up:
    lda VAR_POS
    cmp #$40
    bmi _end
    sec
    sbc #$40
    sta VAR_POS

    jsr game_redraw
_end:
    rts
.scend


;;
;; game_on_down - Move character down
;;
.scope
.text
game_on_down:
    lda VAR_POS
    cmp #$40
    bpl _end
    clc
    adc #$40
    sta VAR_POS

    jsr game_redraw
_end:
    rts
.scend


;;
;; game_on_left - Move character left
;;
.scope
.text
game_on_left:
    lda VAR_POS
    and #$BF
    beq _end
    dec VAR_POS

    jsr game_redraw
_end:
    rts
.scend


;;
;; game_on_right - Move character right
;;
.scope
.text
game_on_right:
    lda VAR_POS
    and #$BF
    cmp #14
    bpl _end
    inc VAR_POS

    jsr game_redraw
_end:
    rts
.scend


;;
;; game_on_trigger - NOP
;;
.scope
.text
game_on_trigger:
    lda VAR_LASER
    bne _end
    lda VAR_POS
    inc
    sta VAR_LASER

    jsr game_redraw
_end:
    rts
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
    ;; wait for 3 seconds (12 * 250ms)
    lda VAR_TICK
    cmp #12
    bcc _loop

    ;; clear the tick counter
    stz VAR_TICK
    rts
.scend


;;
;; game_redraw: Redraw display buffers
;;
.scope
.text
game_redraw:
    sei

    ;; clear display buffers
    lda #$20 ;; space
    ldy 16
_clear_line_1:
    dey
    sta VAR_BUFFER,y
    bne _clear_line_1
    stz [VAR_BUFFER+$10]

    lda #$20 ;; space
    ldy 16
_clear_line_2:
    dey
    sta [VAR_BUFFER+$40],y
    bne _clear_line_2
    stz [VAR_BUFFER+$50]

    ;; draw player
    ldy VAR_POS
    lda [player+0]
    sta VAR_BUFFER,y
    iny
    lda [player+1]
    sta VAR_BUFFER,y

    ;; draw enemy
    ldy #12
    lda [enemy]
    sta VAR_BUFFER,y
    iny
    lda [enemy+1]
    sta VAR_BUFFER,y
    iny
    lda [enemy+2]
    sta VAR_BUFFER,y

    ;; draw laser
    ldy VAR_LASER
    beq _end
    lda laser
    sta VAR_BUFFER,y

_end:
    cli
    rts
.scend


;;
;; 250ms Interrupt Macro
;;
.macro game_interrupt
    inc VAR_TICK
.macend
