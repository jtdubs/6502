;;
;; game.s - Game code
;;
;; Exported Functions:
;; - game_run             - Run the game
;;
;; Local Functions:
;; - game_init           - Initialize the game
;; - game_intro          - Show the intro screen
;; - game_outro          - Show the outro screen
;; - game_loop           - The main loop
;; - game_interrupt      - Macro to handle 250ms ticks
;; - game_handle_input   - Handle input
;; - game_spawn_enemies  - Spawn random enemies
;; - game_update_enemies - Update enemy positions
;; - game_update_lasers  - Update laser positions
;; - game_redraw         - Redraw the display buffer
;; - game_on_up          - Handle up button
;; - game_on_down        - Handle down button
;; - game_on_left        - Handle left button
;; - game_on_right       - Handle right button
;; - game_on_btn_a       - Handle A button
;;
.pc02


;; Imports from Display
.import dsp_clear, dsp_print_1, dsp_print_2, dsp_blit
.importzp VAR_DSP_MESSAGE_PTR

;; Imports from Peripheral Controller
.import REG_IOA
.importzp IO_A_NES_LATCH, IO_A_NES_CLK

;; Imports from Random
.import rng_init, rand

;; Exports
.export VAR_DISPLAY_TICK, VAR_INPUT_TICK, game_run


;;
;; Buttons
;;
BTN_A        = $80
BTN_B        = $40
BTN_SELECT   = $20
BTN_START    = $10
BTN_UP       = $08
BTN_DOWN     = $04
BTN_LEFT     = $02
BTN_RIGHT    = $01


;;
;; Game Data
;;

.define N_LASERS  4
.define N_ENEMIES 4

.data
VAR_DISPLAY_TICK:   .res 1   ;; ticks at 4hz
VAR_INPUT_TICK:     .res 1   ;; ticks at 100hz
VAR_BUTTON_EVENTS:  .res 1   ;; button events for this tick
VAR_POS:            .res 1   ;; player position
VAR_ENEMIES:        .res 4   ;; enemy positions
VAR_EXPLOSIONS:     .res 4   ;; explosion positions
VAR_LASERS:         .res 4   ;; laser positions
VAR_ENEMY_POS:      .res 1   ;; temp storage for kill checks
VAR_END_GAME:       .res 1   ;; end game signal
VAR_BUFFER:         .res 128 ;; display buffer

.rodata
intro1: .byte " Squid Defender ",0
intro2: .byte "     10000      ",0

outro1: .byte "   Game Over    ",0
outro2: .byte "                ",0

sprite_player:    .byte $D6,$DB
sprite_laser:     .byte $A5
sprite_enemy:     .byte $F4
sprite_explosion: .byte $2A


;;
;; game_init: Game Initialization
;;
.code
.proc game_init
    ;; zero tick counter, button state, position
    stz VAR_DISPLAY_TICK
    stz VAR_INPUT_TICK
    stz VAR_POS
    stz VAR_END_GAME

    ;; button events start at FF because button presses are low
    lda #$FF
    sta VAR_BUTTON_EVENTS

    ;; FF out laser array
    lda #$FF
    ldy #N_LASERS
_laser_loop:
    dey
    sta VAR_LASERS,y
    bne _laser_loop

    ;; FF out enemy and explosion array
    lda #$FF
    ldy #N_ENEMIES
_enemy_loop:
    dey
    sta VAR_ENEMIES,y
    sta VAR_EXPLOSIONS,y
    bne _enemy_loop

    ;; fill the display buffer w/ the initial game state
    jsr game_redraw

    rts
.endproc


;;
;; game_run: Game entry point
;;
.code
.proc game_run
    ;; initialize the game
    jsr game_init

    ;; do the intro
    jsr game_intro

    ;; from now on we draw from VAR_BUFFER
    lda #<VAR_BUFFER
    sta VAR_DSP_MESSAGE_PTR+0
    lda #>VAR_BUFFER
    sta VAR_DSP_MESSAGE_PTR+1

    ;; enter game loop
    jsr game_loop

    ;; do the outro
    jsr game_outro

    jmp game_run
.endproc


;;
;; game_loop: The main game loop
;;
.code
.proc game_loop
    ;; if time to end game, do so
    lda VAR_END_GAME
    bne _end

    ;; handle input ticks
    lda VAR_INPUT_TICK
    bne _on_input_tick

_check_display_tick:
    ;; handle display ticks
    lda VAR_DISPLAY_TICK
    bne _on_display_tick

    jmp game_loop

_on_input_tick:
    stz VAR_INPUT_TICK
    jsr game_sample_buttons
    jmp _check_display_tick

_on_display_tick:
    stz VAR_DISPLAY_TICK
    jsr game_handle_input
    jsr game_spawn_enemies
    jsr game_update_lasers
    jsr game_update_explosions
    jsr game_update_enemies
    jsr game_redraw
    jsr dsp_blit
    jmp game_loop

_end:
    rts
.endproc


;;
;; game_sample_buttons
;;
.code
.proc game_sample_buttons
    ;; setup Y for high CLK value
    ldy #<IO_A_NES_CLK

    ;; latch high for 12us
    lda #<IO_A_NES_LATCH
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
    and VAR_BUTTON_EVENTS
    sta VAR_BUTTON_EVENTS

    rts
.endproc


;;
;; game_handle_input - Handle user input
;;
.code
.proc game_handle_input
    asl VAR_BUTTON_EVENTS
    bcs _1
    jsr game_on_btn_a
_1:
    asl VAR_BUTTON_EVENTS
    bcs _2
    nop ;; no use for B
_2:
    asl VAR_BUTTON_EVENTS
    bcs _3
    nop ;; no use for Select
_3:
    asl VAR_BUTTON_EVENTS
    bcs _4
    nop ;; no use for Start
_4:
    asl VAR_BUTTON_EVENTS
    bcs _5
    jsr game_on_up
_5:
    asl VAR_BUTTON_EVENTS
    bcs _6
    jsr game_on_down
_6:
    asl VAR_BUTTON_EVENTS
    bcs _7
    jsr game_on_left
_7:
    asl VAR_BUTTON_EVENTS
    bcs _end
    jsr game_on_right
_end:
    lda #$FF
    sta VAR_BUTTON_EVENTS
    rts
.endproc


;;
;; game_spawn_enemies - Spawn random enemies
;;
.code
.proc game_spawn_enemies
    ;; find a blank spot in Y, or jump to end
    ldy #N_ENEMIES
_loop:
    dey
    bmi _end
    lda VAR_ENEMIES,y
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
    sta VAR_ENEMIES,y

_end:
    rts
.endproc


;;
;; game_update_enemies - Update enemy positions
;;
.code
.proc game_update_enemies
    ;; for each enemy
    ldy #N_ENEMIES
_loop:
    dey
    bmi _end

    ;; if enemy position is FF, then it doesn't exist
    lda VAR_ENEMIES,y
    cmp #$FF
    beq _loop

    ;; kill check at current position, in case laser moved into it
    sta VAR_ENEMY_POS
    phy
    jsr game_kill_check
    ply
    cmp #$01
    beq _kill

    ;; move left and check against edge of screen (end of game condition)
    dec VAR_ENEMY_POS
    lda VAR_ENEMY_POS
    cmp #$FF        ;; wrap-around on first line is $00 - $01 == $FF
    beq game_end
    cmp #$3F        ;; wrap-around on second line is $40 - $01 == $3F
    beq game_end

    ;; kill check in new position
    phy
    jsr game_kill_check
    ply
    cmp #$01
    beq _kill

    ;; it survived, so update it's position
    lda VAR_ENEMY_POS
    sta VAR_ENEMIES,y
    jmp _loop

_kill:
    lda #$FF
    sta VAR_ENEMIES,y
    jmp _loop

game_end:
    lda #$FF
    sta VAR_ENEMIES,y
    sta VAR_END_GAME
    jmp _loop

_end:
    rts
.endproc


;;
;; game_kill_check - checks for a hit at VAR_ENEMY_POS and removes the matching laser
;;
.code
.proc game_kill_check
    ;; for each laser
    ldy #N_LASERS
_loop:
    dey
    bmi _end

    ;; if laser doesn't match enemy, loop
    lda VAR_LASERS,y
    cmp VAR_ENEMY_POS
    bne _loop

    ;; get rid of laser
    lda #$FF
    sta VAR_LASERS,y

    ;; create explosion
    jsr game_explosion

    ;; return true
    lda #$01
    rts

_end:
    lda #$00
    rts
.endproc


;;
;; game_explosion - create an explosion at VAR_ENEMY_POS
;;
.code
.proc game_explosion
    ;; for each explosion
    ldy #N_ENEMIES
_loop:
    dey
    bmi _end

    ;; if explosion is non-FF, it already exists
    lda VAR_EXPLOSIONS,y
    cmp #$FF
    bne _loop

    ;; create an explosion
    lda VAR_ENEMY_POS
    sta VAR_EXPLOSIONS,y

_end:
    rts
.endproc


;;
;; game_update_explosions - Update explosions
;;
.code
.proc game_update_explosions
    ;; clear explosion array
    lda #$FF
    ldy #N_ENEMIES
_loop:
    dey
    sta VAR_EXPLOSIONS,y
    bne _loop
    rts
.endproc


;;
;; game_update_lasers - Update laser positions
;;
.code
.proc game_update_lasers
    ;; for each laser
    ldy #N_LASERS
_loop:
    dey
    bmi _end

    ;; if laser position is FF, then it doesn't exist
    lda VAR_LASERS,y
    cmp #$FF
    beq _loop

    ;; otherwise, laser moves right
    inc
    sta VAR_LASERS,y

    ;; if laser passes right edge of screen, it no longer exists
    and #$0F
    bne _loop
    lda #$FF
    sta VAR_LASERS,y

    ;; loop
    jmp _loop

_end:
    rts
.endproc


;;
;; game_on_up - Move character up
;;
.code
.proc game_on_up
    lda VAR_POS
    cmp #$40
    bmi _end
    sec
    sbc #$40
    sta VAR_POS
_end:
    rts
.endproc


;;
;; game_on_down - Move character down
;;
.code
.proc game_on_down
    lda VAR_POS
    cmp #$40
    bpl _end
    clc
    adc #$40
    sta VAR_POS
_end:
    rts
.endproc


;;
;; game_on_left - Move character left
;;
.code
.proc game_on_left
    lda VAR_POS
    and #$BF
    beq _end
    dec VAR_POS
_end:
    rts
.endproc


;;
;; game_on_right - Move character right
;;
.code
.proc game_on_right
    lda VAR_POS
    and #$BF
    cmp #14
    bpl _end
    inc VAR_POS
_end:
    rts
.endproc


;;
;; game_on_btn_a - Fire a laser
;;
.code
.proc game_on_btn_a
    ;; for each laser
    ldy #N_LASERS
_loop:
    dey
    bmi _end

    ;; if laser is non-FF, it already exists
    lda VAR_LASERS,y
    cmp #$FF
    bne _loop

    ;; create a laser at POS+1
    lda VAR_POS
    inc
    sta VAR_LASERS,y

_end:
    rts
.endproc


;;
;; game_intro: Show the intro screen
;;
.code
.proc game_intro
    ;; print intro message
    lda #<intro1
    sta VAR_DSP_MESSAGE_PTR+0
    lda #>intro1
    sta VAR_DSP_MESSAGE_PTR+1
    jsr dsp_print_1

    lda #<intro2
    sta VAR_DSP_MESSAGE_PTR+0
    lda #>intro2
    sta VAR_DSP_MESSAGE_PTR+1
    jsr dsp_print_2

_input_loop:
    ;; handle input ticks
    lda VAR_INPUT_TICK
    beq _input_loop

_on_input_tick:
    ;; loop until BTN_A
    stz VAR_INPUT_TICK
    jsr game_sample_buttons
    lda VAR_BUTTON_EVENTS
    and #BTN_A
    bne _input_loop

_setup:
    ;; init rng
    jsr rng_init

    ;; clear display
    jsr dsp_clear

    ;; reset state for main game
    lda #$FF
    sta VAR_BUTTON_EVENTS

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
.endproc


;;
;; game_outro: Show the outro screen
;;
.code
.proc game_outro
    ;; print intro message
    lda #<outro1
    sta VAR_DSP_MESSAGE_PTR+0
    lda #>outro1
    sta VAR_DSP_MESSAGE_PTR+1
    jsr dsp_print_1

    lda #<outro2
    sta VAR_DSP_MESSAGE_PTR+0
    lda #>outro2
    sta VAR_DSP_MESSAGE_PTR+1
    jsr dsp_print_2

_input_loop:
    ;; handle input ticks
    lda VAR_INPUT_TICK
    beq _input_loop

_on_input_tick:
    ;; loop until BTN_A
    stz VAR_INPUT_TICK
    jsr game_sample_buttons
    lda VAR_BUTTON_EVENTS
    and #BTN_A
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
.endproc


;;
;; game_redraw: Redraw display buffers
;;
.code
.proc game_redraw
    sei

    ;; clear display buffers
    lda #$20 ;; space
    ldy #16
_clear:
    dey
    sta VAR_BUFFER,y
    sta VAR_BUFFER+$40,y
    bne _clear

    ;; draw player
    ldy VAR_POS
    lda sprite_player+0
    sta VAR_BUFFER,y
    iny
    lda sprite_player+1
    sta VAR_BUFFER,y

    ;; draw enemies
    lda sprite_enemy
    ldy #N_ENEMIES
_enemy_loop:
    dey
    bmi _enemy_done
    ldx VAR_ENEMIES,y
    cpx #$FF
    beq _enemy_loop
    sta VAR_BUFFER,x
    jmp _enemy_loop
_enemy_done:

    ;; draw lasers
    lda sprite_laser
    ldy #N_LASERS
_laser_loop:
    dey
    bmi _laser_done
    ldx VAR_LASERS,y
    cpx #$FF
    beq _laser_loop
    sta VAR_BUFFER,x
    jmp _laser_loop
_laser_done:

    ;; draw explosions
    lda sprite_explosion
    ldy #N_ENEMIES
_explosion_loop:
    dey
    bmi _explosion_done
    ldx VAR_EXPLOSIONS,y
    cpx #$FF
    beq _explosion_loop
    sta VAR_BUFFER,x
    jmp _explosion_loop
_explosion_done:

    cli
    rts
.endproc
