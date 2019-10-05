;;
;; game.s - Game code
;;
;; Functions:
;; - game_init           - Initialize the game
;; - game_run            - Run the game
;; - game_intro          - Show the intro screen
;; - game_loop           - The main loop
;; - game_interrupt      - Macro to handle 250ms ticks
;; - game_spawn_enemies  - Spawn random enemies
;; - game_update_enemies - Update enemy positions
;; - game_update_lasers  - Update laser positions
;; - game_redraw         - Redraw the display buffer
;; - game_on_tick        - Handle 250ms tick
;; - game_on_up          - Handle up button
;; - game_on_down        - Handle down button
;; - game_on_left        - Handle left button
;; - game_on_right       - Handle right button
;; - game_on_trigger     - Handle trigger button
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

.alias NLASER   3
.alias NENEMIES 4

.data zp
.space VAR_TICK          1   ;; counts 250ms ticks
.space VAR_BUTTON_STATE  1   ;; button state
.space VAR_POS           1   ;; player position
.space VAR_LASERS        3   ;; laser positions
.space VAR_ENEMIES       4   ;; enemy positions
.space VAR_BUTTON_EVENTS 1   ;; button events for this tick

.data
.space VAR_BUFFER       128 ;; display buffer

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
    stz VAR_BUTTON_STATE
    stz VAR_POS

    lda #$FF
    sta VAR_BUTTON_EVENTS

    ;; zero out laser array
    lda #$00
    ldy NLASER
_laser_loop:
    dey
    sta VAR_LASERS,y
    bne _laser_loop

    ;; ff out enemy array
    lda #$FF
    ldy NENEMIES
_enemy_loop:
    dey
    sta VAR_ENEMIES,y
    bne _enemy_loop

    jsr game_redraw

    rts
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

    ;; from now on we draw from VAR_BUFFER
    lda #[<VAR_BUFFER]
    sta [VAR_MESSAGE_PTR+0]
    lda #[>VAR_BUFFER]
    sta [VAR_MESSAGE_PTR+1]

    ;; enter game loop
    jsr game_loop

    rts
.scend


;;
;; game_loop: The main game loop
;;
.scope
.text
game_loop:
    ;; handle game tick
    lda VAR_TICK
    bne _on_tick

    ;; if button state changed, _on_button_changed
    lda REG_IOA
    cmp VAR_BUTTON_STATE
    bne _on_button_changed

    ;; if neither, loop
    jmp game_loop

_on_button_changed:
    ;; wait for 2ms for results to de-bounce
    sta VAR_BUTTON_STATE
    lda #5
    jsr delay_ms
    lda VAR_BUTTON_STATE
    ora REG_IOA

    ;; include in button events
    and VAR_BUTTON_EVENTS
    sta VAR_BUTTON_EVENTS

    cli
    jmp game_loop

_on_tick:
    ;; de-bounced sample of button states
    lda REG_IOA
    sta VAR_BUTTON_STATE
    lda #5
    jsr delay_ms
    lda VAR_BUTTON_STATE
    ora REG_IOA

    ;; include in button events
    and VAR_BUTTON_EVENTS
    sta VAR_BUTTON_EVENTS

    jsr game_on_tick

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

    jsr game_handle_input
    jsr game_spawn_enemies
    jsr game_update_lasers
    jsr game_update_enemies
    jsr game_redraw
    jsr dsp_blit

    rts
.scend


;;
;; game_handle_input - Handle user input
;;
.scope
.text
game_handle_input:
_check_up:
    lda VAR_BUTTON_EVENTS
    tax
    and #BTN_UP
    beq _on_up
_check_down:
    txa
    and #BTN_DOWN
    beq _on_down
_check_left:
    txa
    and #BTN_LEFT
    beq _on_left
_check_right:
    txa
    and #BTN_RIGHT
    beq _on_right
_check_trigger:
    txa
    and #BTN_TRIGGER
    beq _on_trigger
_end:
    lda #$FF
    sta VAR_BUTTON_EVENTS
    rts
_on_up:
    jsr game_on_up
    jmp _check_down
_on_down:
    jsr game_on_down
    jmp _check_left
_on_left:
    jsr game_on_left
    jmp _check_right
_on_right:
    jsr game_on_right
    jmp _check_trigger
_on_trigger:
    jsr game_on_trigger
    jmp _end
.scend


;;
;; game_spawn_enemies - Spawn random enemies
;;
.scope
.text
game_spawn_enemies:
    ;; find a blank spot in Y, or jump to end
    ldy #NENEMIES
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

    ;; only spawn 30% of the time
    cmp #$B0
    bmi _end

    ;; use random number to choose row
    and #$40
    clc
    adc #$10

    ;; create the enemy
    sta VAR_ENEMIES,y

_end:
    rts
.scend


;;
;; game_update_enemies - Update enemy positions
;;
.scope
.text
game_update_enemies:
    ldy #NENEMIES
_loop:
    dey
    bmi _end
    lda VAR_ENEMIES,y
    cmp #$FF
    beq _loop
    dec
    sta VAR_ENEMIES,y
    cmp #$3F
    bne _loop
    lda #$FF
    sta VAR_ENEMIES,y
    jmp _loop
_end:
    rts
.scend


;;
;; game_update_lasers - Update laser positions
;;
.scope
.text
game_update_lasers:
    ldy #NLASER
_loop:
    dey
    bmi _end
    lda VAR_LASERS,y
    beq _loop
    inc
    sta VAR_LASERS,y
    and #$0F
    bne _loop
    sta VAR_LASERS,y
    jmp _loop
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
_end:
    rts
.scend


;;
;; game_on_trigger - NOP
;;
.scope
.text
game_on_trigger:
    ldy #NLASER
_loop:
    dey
    bmi _end
    lda VAR_LASERS,y
    bne _loop
    lda VAR_POS
    inc
    sta VAR_LASERS,y
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
_clear:
    dey
    sta VAR_BUFFER,y
    sta [VAR_BUFFER+$40],y
    bne _clear

    ;; draw player
    ldy VAR_POS
    lda [player+0]
    sta VAR_BUFFER,y
    iny
    lda [player+1]
    sta VAR_BUFFER,y

    ;; draw enemies
    lda enemy
    ldy #NENEMIES
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
    lda laser
    ldy #NLASER
_laser_loop:
    dey
    bmi _laser_done
    ldx VAR_LASERS,y
    beq _laser_loop
    sta VAR_BUFFER,x
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
