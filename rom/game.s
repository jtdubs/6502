;;
;; game.s - Game code
;;
;; Exported Functions:
;; - game_init            - Initialize the game
;; - game_run             - Run the game
;;
;; Local Functions:
;; - _game_intro          - Show the intro screen
;; - _game_loop           - The main loop
;; - _game_interrupt      - Macro to handle 250ms ticks
;; - _game_handle_input   - Handle input
;; - _game_spawn_enemies  - Spawn random enemies
;; - _game_update_enemies - Update enemy positions
;; - _game_update_lasers  - Update laser positions
;; - _game_redraw         - Redraw the display buffer
;; - _game_on_tick        - Handle 250ms tick
;; - _game_on_up          - Handle up button
;; - _game_on_down        - Handle down button
;; - _game_on_left        - Handle left button
;; - _game_on_right       - Handle right button
;; - _game_on_trigger     - Handle trigger button
;;
.scope

.require "rng.s"
.require "delay.s"
.require "display.s"
.require "peripheral.s"


;;
;; Buttons
;;
.alias _BTN_TRIGGER  $01
.alias _BTN_UP       $02
.alias _BTN_DOWN     $04
.alias _BTN_LEFT     $08
.alias _BTN_RIGHT    $10


;;
;; Game Data
;;

.alias _N_LASERS  3
.alias _N_ENEMIES 4

.data
.space VAR_TICK           1   ;; counts 250ms ticks
.space _VAR_BUTTON_STATE  1   ;; button state
.space _VAR_POS           1   ;; player position
.space _VAR_LASERS        3   ;; laser positions
.space _VAR_ENEMIES       4   ;; enemy positions
.space _VAR_BUTTON_EVENTS 1   ;; button events for this tick
.space _VAR_BUFFER        128 ;; display buffer

.text
intro1: .byte " Squid Defender "
intro2: .byte "     10000      "
player: .byte $D6,$DB
laser:  .byte $A5
enemy:  .byte $F4


;;
;; game_init: Game Initialization
;;
.scope
.text
game_init:
    stz VAR_TICK
    stz _VAR_BUTTON_STATE
    stz _VAR_POS

    lda #$FF
    sta _VAR_BUTTON_EVENTS

    ;; zero out laser array
    lda #$00
    ldy _N_LASERS
_laser_loop:
    dey
    sta _VAR_LASERS,y
    bne _laser_loop

    ;; ff out enemy array
    lda #$FF
    ldy _N_ENEMIES
_enemy_loop:
    dey
    sta _VAR_ENEMIES,y
    bne _enemy_loop

    jsr _game_redraw

    rts
.scend


;;
;; game_run: Game entry point
;;
.scope
.text
game_run:
    ;; do the intro
    jsr _game_intro

    ;; enable interrupts
    cli

    ;; from now on we draw from _VAR_BUFFER
    lda #[<_VAR_BUFFER]
    sta [VAR_DSP_MESSAGE_PTR+0]
    lda #[>_VAR_BUFFER]
    sta [VAR_DSP_MESSAGE_PTR+1]

    ;; enter game loop
    jsr _game_loop

    rts
.scend


;;
;; _game_loop: The main game loop
;;
.text
_game_loop:
.scope
    ;; handle game tick
    lda VAR_TICK
    bne _on_tick

    ;; if button state changed, _on_button_changed
    lda REG_IOA
    cmp _VAR_BUTTON_STATE
    bne _on_button_changed

    ;; if neither, loop
    jmp _game_loop

_on_button_changed:
    ;; wait for 2ms for results to de-bounce
    sta _VAR_BUTTON_STATE
    lda #5
    jsr delay_ms
    lda _VAR_BUTTON_STATE
    ora REG_IOA

    ;; include in button events
    and _VAR_BUTTON_EVENTS
    sta _VAR_BUTTON_EVENTS

    cli
    jmp _game_loop

_on_tick:
    ;; de-bounced sample of button states
    lda REG_IOA
    sta _VAR_BUTTON_STATE
    lda #5
    jsr delay_ms
    lda _VAR_BUTTON_STATE
    ora REG_IOA

    ;; include in button events
    and _VAR_BUTTON_EVENTS
    sta _VAR_BUTTON_EVENTS

    jsr _game_on_tick

    cli
    jmp _game_loop
.scend


;;
;; _game_on_tick - Handle game tick by refreshing the display
;;
_game_on_tick:
.scope
.text
    ;; reset VAR_TICK
    stz VAR_TICK

    jsr _game_handle_input
    jsr _game_spawn_enemies
    jsr _game_update_lasers
    jsr _game_update_enemies
    jsr _game_redraw
    jsr dsp_blit

    rts
.scend


;;
;; _game_handle_input - Handle user input
;;
.text
_game_handle_input:
.scope
_check_up:
    lda _VAR_BUTTON_EVENTS
    tax
    and #_BTN_UP
    beq _on_up
_check_down:
    txa
    and #_BTN_DOWN
    beq _on_down
_check_left:
    txa
    and #_BTN_LEFT
    beq _on_left
_check_right:
    txa
    and #_BTN_RIGHT
    beq _on_right
_check_trigger:
    txa
    and #_BTN_TRIGGER
    beq _on_trigger
_end:
    lda #$FF
    sta _VAR_BUTTON_EVENTS
    rts
_on_up:
    jsr _game_on_up
    jmp _check_down
_on_down:
    jsr _game_on_down
    jmp _check_left
_on_left:
    jsr _game_on_left
    jmp _check_right
_on_right:
    jsr _game_on_right
    jmp _check_trigger
_on_trigger:
    jsr _game_on_trigger
    jmp _end
.scend


;;
;; _game_spawn_enemies - Spawn random enemies
;;
.text
_game_spawn_enemies:
.scope
    ;; find a blank spot in Y, or jump to end
    ldy #_N_ENEMIES
_loop:
    dey
    bmi _end
    lda _VAR_ENEMIES,y
    cmp #$FF
    bne _loop

    ;; get a random number in A
    phy
    jsr rand
    ply

    ;; only spawn 30% of the time
    cmp #$B0
    bmi _end

    ;; use random number to choose row
    and #$40
    clc
    adc #$10

    ;; create the enemy
    sta _VAR_ENEMIES,y

_end:
    rts
.scend


;;
;; _game_update_enemies - Update enemy positions
;;
.text
_game_update_enemies:
.scope
    ldy #_N_ENEMIES
_loop:
    dey
    bmi _end
    lda _VAR_ENEMIES,y
    cmp #$FF
    beq _loop
    dec
    sta _VAR_ENEMIES,y
    cmp #$3F
    bne _loop
    lda #$FF
    sta _VAR_ENEMIES,y
    jmp _loop
_end:
    rts
.scend


;;
;; _game_update_lasers - Update laser positions
;;
.text
_game_update_lasers:
.scope
    ldy #_N_LASERS
_loop:
    dey
    bmi _end
    lda _VAR_LASERS,y
    beq _loop
    inc
    sta _VAR_LASERS,y
    and #$0F
    bne _loop
    sta _VAR_LASERS,y
    jmp _loop
_end:
    rts
.scend


;;
;; _game_on_up - Move character up
;;
.text
_game_on_up:
.scope
    lda _VAR_POS
    cmp #$40
    bmi _end
    sec
    sbc #$40
    sta _VAR_POS
_end:
    rts
.scend


;;
;; _game_on_down - Move character down
;;
.text
_game_on_down:
.scope
    lda _VAR_POS
    cmp #$40
    bpl _end
    clc
    adc #$40
    sta _VAR_POS
_end:
    rts
.scend


;;
;; _game_on_left - Move character left
;;
.text
_game_on_left:
.scope
    lda _VAR_POS
    and #$BF
    beq _end
    dec _VAR_POS
_end:
    rts
.scend


;;
;; _game_on_right - Move character right
;;
.text
_game_on_right:
.scope
    lda _VAR_POS
    and #$BF
    cmp #14
    bpl _end
    inc _VAR_POS
_end:
    rts
.scend


;;
;; _game_on_trigger - NOP
;;
.text
_game_on_trigger:
.scope
    ldy #_N_LASERS
_loop:
    dey
    bmi _end
    lda _VAR_LASERS,y
    bne _loop
    lda _VAR_POS
    inc
    sta _VAR_LASERS,y
_end:
    rts
.scend


;;
;; _game_intro: Show the intro screen
;;
.text
_game_intro:
.scope
    ;; print intro message
    lda #[<intro1]
    sta [VAR_DSP_MESSAGE_PTR+0]
    lda #[>intro1]
    sta [VAR_DSP_MESSAGE_PTR+1]
    jsr dsp_print_1

    lda #[<intro2]
    sta [VAR_DSP_MESSAGE_PTR+0]
    lda #[>intro2]
    sta [VAR_DSP_MESSAGE_PTR+1]
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
;; _game_redraw: Redraw display buffers
;;
.text
_game_redraw:
.scope
    sei

    ;; clear display buffers
    lda #$20 ;; space
    ldy 16
_clear:
    dey
    sta _VAR_BUFFER,y
    sta [_VAR_BUFFER+$40],y
    bne _clear

    ;; draw player
    ldy _VAR_POS
    lda [player+0]
    sta _VAR_BUFFER,y
    iny
    lda [player+1]
    sta _VAR_BUFFER,y

    ;; draw enemies
    lda enemy
    ldy #_N_ENEMIES
_enemy_loop:
    dey
    bmi _enemy_done
    ldx _VAR_ENEMIES,y
    cpx #$FF
    beq _enemy_loop
    sta _VAR_BUFFER,x
    jmp _enemy_loop
_enemy_done:

    ;; draw lasers
    lda laser
    ldy #_N_LASERS
_laser_loop:
    dey
    bmi _laser_done
    ldx _VAR_LASERS,y
    beq _laser_loop
    sta _VAR_BUFFER,x
    jmp _laser_loop
_laser_done:

    cli
    rts
.scend


;;
;; 250ms Interrupt Macro
;;
.macro game_interrupt
    inc VAR_TICK
.macend

.scend
