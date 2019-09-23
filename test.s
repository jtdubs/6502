#define PER_IO_A  $600F
#define PER_IO_B  $6000
#define PER_DDR_A $6003
#define PER_DDR_B $6002
#define PER_AUX   $600B

#define PER_A_BTN    $01
#define PER_A_BTN_U  $02
#define PER_A_BTN_D  $04
#define PER_A_BTN_L  $08
#define PER_A_BTN_R  $10
#define PER_A_DSP_RS $20
#define PER_A_DSP_RW $40
#define PER_A_DSP_E  $80

.org $8000

reset:
    ; button are inputs, display control lines are outputs
    ldx #$E0
    stx PER_DDR_A

    ; display lines are outputs
    ldx #$FF
    stx PER_DDR_B

loop:
    ldx PER_IO_A
    bbs0 on_btn
    bbs1 on_up
    bbs2 on_down
    bbs3 on_left
    bbs4 on_right
    jmp loop

on_btn:
    nop
    nop
    jmp loop

on_up:
    nop
    nop
    jmp loop

on_down:
    nop
    nop
    jmp loop

on_left:
    nop
    nop
    jmp loop

on_right:
    nop
    nop
    jmp loop

.org $fff4
    dfw $0000 ; cop
    dfw $0000 ; --
    dfw $0000 ; abort
    dfw $0000 ; nmi
    dfw $8000 ; reset
    dfw $0000 ; irq / brk
