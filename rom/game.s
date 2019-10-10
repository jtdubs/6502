;;
;; game.s - Game code
;;
;; Exported Functions:
;; - game_run             - Run the game
;;
;; Local Functions:
;; - _game_init           - Initialize the game
;; - _game_intro          - Show the intro screen
;; - _game_outro          - Show the outro screen
;; - _game_loop           - The main loop
;; - _game_interrupt      - Macro to handle 250ms ticks
;; - _game_handle_input   - Handle input
;; - _game_spawn_enemies  - Spawn random enemies
;; - _game_update_enemies - Update enemy positions
;; - _game_update_lasers  - Update laser positions
;; - _game_redraw         - Redraw the display buffer
;; - _game_on_up          - Handle up button
;; - _game_on_down        - Handle down button
;; - _game_on_left        - Handle left button
;; - _game_on_right       - Handle right button
;; - _game_on_btn_a       - Handle A button
;;
.scope

.require "rng.s"
.require "delay.s"
.require "display.s"
.require "peripheral.s"


;;
;; Buttons
;;
.alias _BTN_A        $80
.alias _BTN_B        $40
.alias _BTN_SELECT   $20
.alias _BTN_START    $10
.alias _BTN_UP       $08
.alias _BTN_DOWN     $04
.alias _BTN_LEFT     $02
.alias _BTN_RIGHT    $01


;;
;; Game Data
;;

.alias _N_LASERS  4
.alias _N_ENEMIES 4

.data
.space VAR_DISPLAY_TICK   1   ;; ticks at 4hz
.space VAR_INPUT_TICK     1   ;; ticks at 100hz
.space _VAR_BUTTON_EVENTS 1   ;; button events for this tick
.space _VAR_POS           1   ;; player position
.space _VAR_ENEMIES       4   ;; enemy positions
.space _VAR_EXPLOSIONS    4   ;; explosion positions
.space _VAR_LASERS        4   ;; laser positions
.space _VAR_ENEMY_POS     1   ;; temp storage for kill checks
.space _VAR_END_GAME      1   ;; end game signal
.space _VAR_BUFFER        128 ;; display buffer

.text
intro1: .byte " Squid Defender ",0
intro2: .byte "     10000      ",0

outro1: .byte "   Game Over    ",0
outro2: .byte "                ",0

sprite_player:    .byte $D6,$DB
sprite_laser:     .byte $A5
sprite_enemy:     .byte $F4
sprite_explosion: .byte $2A


;;
;; _game_init: Game Initialization
;;
.text
_game_init:
.scope
    ;; zero tick counter, button state, position
    stz VAR_DISPLAY_TICK
    stz VAR_INPUT_TICK
    stz _VAR_POS
    stz _VAR_END_GAME

    ;; button events start at FF because button presses are low
    lda #$FF
    sta _VAR_BUTTON_EVENTS

    ;; FF out laser array
    lda #$FF
    ldy #_N_LASERS
_laser_loop:
    dey
    sta _VAR_LASERS,y
    bne _laser_loop

    ;; FF out enemy and explosion array
    lda #$FF
    ldy #_N_ENEMIES
_enemy_loop:
    dey
    sta _VAR_ENEMIES,y
    sta _VAR_EXPLOSIONS,y
    bne _enemy_loop

    ;; fill the display buffer w/ the initial game state
    jsr _game_redraw

    rts
.scend


;;
;; game_run: Game entry point
;;
.scope
.text
game_run:
    ;; initialize the game
    jsr _game_init

    ;; do the intro
    jsr _game_intro

    ;; from now on we draw from _VAR_BUFFER
    lda #[<_VAR_BUFFER]
    sta [VAR_DSP_MESSAGE_PTR+0]
    lda #[>_VAR_BUFFER]
    sta [VAR_DSP_MESSAGE_PTR+1]

    ;; enter game loop
    jsr _game_loop

    ;; do the outro
    jsr _game_outro

    jmp game_run
.scend


;;
;; _game_loop: The main game loop
;;
.text
_game_loop:
.scope
    ;; if time to end game, do so
    lda _VAR_END_GAME
    bne _end

    ;; handle input ticks
    lda VAR_INPUT_TICK
    bne _on_input_tick

_check_display_tick:
    ;; handle display ticks
    lda VAR_DISPLAY_TICK
    bne _on_display_tick

    jmp _game_loop

_on_input_tick:
    stz VAR_INPUT_TICK
    jsr _game_sample_buttons
    jmp _check_display_tick

_on_display_tick:
    stz VAR_DISPLAY_TICK
    jsr _game_handle_input
    jsr _game_spawn_enemies
    jsr _game_update_lasers
    jsr _game_update_explosions
    jsr _game_update_enemies
    jsr _game_redraw
    jsr dsp_blit
    jmp _game_loop

_end:
    rts
.scend


;;
;; _game_sample_buttons
;;
.text
_game_sample_buttons:
.scope
    ;; setup Y for high CLK value
    ldy #IO_A_NES_CLK

    ;; latch high for 12us
    lda #IO_A_NES_LATCH
    sta REG_IOA
    lda #$00
    nop
    nop
    nop
    stz REG_IOA

    ;; read A
    eor REG_IOA
    sty REG_IOA
    nop
    asl
    stz REG_IOA

    ;; read B
    eor REG_IOA
    sty REG_IOA
    nop
    asl
    stz REG_IOA

    ;; read Select
    eor REG_IOA
    sty REG_IOA
    nop
    asl
    stz REG_IOA

    ;; read Start
    eor REG_IOA
    sty REG_IOA
    nop
    asl
    stz REG_IOA

    ;; read Up
    eor REG_IOA
    sty REG_IOA
    nop
    asl
    stz REG_IOA

    ;; read Down
    eor REG_IOA
    sty REG_IOA
    nop
    asl
    stz REG_IOA

    ;; read Left
    eor REG_IOA
    sty REG_IOA
    nop
    asl
    stz REG_IOA

    ;; read Right
    eor REG_IOA
    sty REG_IOA
    nop
    nop
    stz REG_IOA

    ;; include in button events
    and _VAR_BUTTON_EVENTS
    sta _VAR_BUTTON_EVENTS

    rts
.scend


;;
;; _game_handle_input - Handle user input
;;
.text
_game_handle_input:
.scope
    asl _VAR_BUTTON_EVENTS
    bcs _1
    jsr _game_on_btn_a
_1:
    asl _VAR_BUTTON_EVENTS
    bcs _2
    nop ;; no use for B
_2:
    asl _VAR_BUTTON_EVENTS
    bcs _3
    nop ;; no use for Select
_3:
    asl _VAR_BUTTON_EVENTS
    bcs _4
    nop ;; no use for Start
_4:
    asl _VAR_BUTTON_EVENTS
    bcs _5
    jsr _game_on_up
_5:
    asl _VAR_BUTTON_EVENTS
    bcs _6
    jsr _game_on_down
_6:
    asl _VAR_BUTTON_EVENTS
    bcs _7
    jsr _game_on_left
_7:
    asl _VAR_BUTTON_EVENTS
    bcs _end
    jsr _game_on_right
_end:
    lda #$FF
    sta _VAR_BUTTON_EVENTS
    rts
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

    ;; don't spawn every time
    cmp #$80
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
    ;; for each enemy
    ldy #_N_ENEMIES
_loop:
    dey
    bmi _end

    ;; if enemy position is FF, then it doesn't exist
    lda _VAR_ENEMIES,y
    cmp #$FF
    beq _loop

    ;; kill check at current position, in case laser moved into it
    sta _VAR_ENEMY_POS
    phy
    jsr _game_kill_check
    ply
    cmp #$01
    beq _kill

    ;; move left and check against edge of screen (end of game condition)
    dec _VAR_ENEMY_POS
    lda _VAR_ENEMY_POS
    cmp #$FF        ;; wrap-around on first line is $00 - $01 == $FF
    beq _game_end
    cmp #$3F        ;; wrap-around on second line is $40 - $01 == $3F
    beq _game_end

    ;; kill check in new position
    phy
    jsr _game_kill_check
    ply
    cmp #$01
    beq _kill

    ;; it survived, so update it's position
    lda _VAR_ENEMY_POS
    sta _VAR_ENEMIES,y
    jmp _loop

_kill:
    lda #$FF
    sta _VAR_ENEMIES,y
    jmp _loop

_game_end:
    lda #$FF
    sta _VAR_ENEMIES,y
    sta _VAR_END_GAME
    jmp _loop

_end:
    rts
.scend


;;
;; _game_kill_check - checks for a hit at _VAR_ENEMY_POS and removes the matching laser
;;
.text
_game_kill_check:
.scope
    ;; for each laser
    ldy #_N_LASERS
_loop:
    dey
    bmi _end

    ;; if laser doesn't match enemy, loop
    lda _VAR_LASERS,y
    cmp _VAR_ENEMY_POS
    bne _loop

    ;; get rid of laser
    lda #$FF
    sta _VAR_LASERS,y

    ;; create explosion
    jsr _game_explosion

    ;; return true
    lda #$01
    rts

_end:
    lda #$00
    rts
.scend


;;
;; _game_explosion - create an explosion at _VAR_ENEMY_POS
;;
.text
_game_explosion:
.scope
    ;; for each explosion
    ldy #_N_ENEMIES
_loop:
    dey
    bmi _end

    ;; if explosion is non-FF, it already exists
    lda _VAR_EXPLOSIONS,y
    cmp #$FF
    bne _loop

    ;; create an explosion
    lda _VAR_ENEMY_POS
    sta _VAR_EXPLOSIONS,y

_end:
    rts
.scend


;;
;; _game_update_explosions - Update explosions
;;
.text
_game_update_explosions:
.scope
    ;; clear explosion array
    lda #$FF
    ldy #_N_ENEMIES
_loop:
    dey
    sta _VAR_EXPLOSIONS,y
    bne _loop
    rts
.scend


;;
;; _game_update_lasers - Update laser positions
;;
.text
_game_update_lasers:
.scope
    ;; for each laser
    ldy #_N_LASERS
_loop:
    dey
    bmi _end

    ;; if laser position is FF, then it doesn't exist
    lda _VAR_LASERS,y
    cmp #$FF
    beq _loop

    ;; otherwise, laser moves right
    inc
    sta _VAR_LASERS,y

    ;; if laser passes right edge of screen, it no longer exists
    and #$0F
    bne _loop
    lda #$FF
    sta _VAR_LASERS,y

    ;; loop
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
;; _game_on_btn_a - Fire a laser
;;
.text
_game_on_btn_a:
.scope
    ;; for each laser
    ldy #_N_LASERS
_loop:
    dey
    bmi _end

    ;; if laser is non-FF, it already exists
    lda _VAR_LASERS,y
    cmp #$FF
    bne _loop

    ;; create a laser at POS+1
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

_input_loop:
    ;; handle input ticks
    lda VAR_INPUT_TICK
    beq _input_loop

_on_input_tick:
    ;; loop until BTN_A
    stz VAR_INPUT_TICK
    jsr _game_sample_buttons
    lda _VAR_BUTTON_EVENTS
    and #_BTN_A
    bne _input_loop

_setup:
    ;; init rng
    jsr rng_init

    ;; clear display
    jsr dsp_clear

    ;; reset state for main game
    lda #$FF
    sta _VAR_BUTTON_EVENTS

    ;; wait for 1 second (4 display ticks)
    stz VAR_DISPLAY_TICK
_delay_loop:
    lda VAR_DISPLAY_TICK
    cmp #4
    bcc _delay_loop

    ;; clear tick counters
    stz VAR_DISPLAY_TICK
    stz VAR_INPUT_TICK

    rts
.scend


;;
;; _game_outro: Show the outro screen
;;
.text
_game_outro:
.scope
    ;; print intro message
    lda #[<outro1]
    sta [VAR_DSP_MESSAGE_PTR+0]
    lda #[>outro1]
    sta [VAR_DSP_MESSAGE_PTR+1]
    jsr dsp_print_1

    lda #[<outro2]
    sta [VAR_DSP_MESSAGE_PTR+0]
    lda #[>outro2]
    sta [VAR_DSP_MESSAGE_PTR+1]
    jsr dsp_print_2

_input_loop:
    ;; handle input ticks
    lda VAR_INPUT_TICK
    beq _input_loop

_on_input_tick:
    ;; loop until BTN_A
    stz VAR_INPUT_TICK
    jsr _game_sample_buttons
    lda _VAR_BUTTON_EVENTS
    and #_BTN_A
    bne _input_loop

_reset:
    ;; clear display
    jsr dsp_clear

    ;; wait for 0.5 second (2 display ticks)
    stz VAR_DISPLAY_TICK
_delay_loop:
    lda VAR_DISPLAY_TICK
    cmp #2
    bcc _delay_loop

    stz VAR_DISPLAY_TICK
    stz VAR_INPUT_TICK

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
    ldy #16
_clear:
    dey
    sta _VAR_BUFFER,y
    sta [_VAR_BUFFER+$40],y
    bne _clear

    ;; draw player
    ldy _VAR_POS
    lda [sprite_player+0]
    sta _VAR_BUFFER,y
    iny
    lda [sprite_player+1]
    sta _VAR_BUFFER,y

    ;; draw enemies
    lda sprite_enemy
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
    lda sprite_laser
    ldy #_N_LASERS
_laser_loop:
    dey
    bmi _laser_done
    ldx _VAR_LASERS,y
    cpx #$FF
    beq _laser_loop
    sta _VAR_BUFFER,x
    jmp _laser_loop
_laser_done:

    ;; draw explosions
    lda sprite_explosion
    ldy #_N_ENEMIES
_explosion_loop:
    dey
    bmi _explosion_done
    ldx _VAR_EXPLOSIONS,y
    cpx #$FF
    beq _explosion_loop
    sta _VAR_BUFFER,x
    jmp _explosion_loop
_explosion_done:

    cli
    rts
.scend


;;
;; Interrupt Macros
;;
.macro display_tick
    inc VAR_DISPLAY_TICK
.macend

.macro input_tick
    inc VAR_INPUT_TICK
.macend

.scend
