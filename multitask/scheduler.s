.p816

.include "multitask.inc"
.include "regs.inc"
.include "io.inc"
.include "kernal.inc"

cursor_blink = $c86c
led_update = $e73a
kbd_scan = $d242
clock_update = $e94c
ps2data_fetch = $d104

.export mt_scheduler

; from main.s
.import currentTask
.import oldIrq

.segment "MULTITASK"

.proc mt_scheduler_x: near

    ; Do something to prove interrupt is alive
    lda $07ff
    inc
    sta $07ff

    ; Acknowlege IRQ
    lda #1
    sta VERA_ISR

    jmp(oldIrq)
.endproc

.proc mt_scheduler: near              

    ; Save the state
    php         ; Push Flags
    xce         ; Push emulator flag
    php
    clc         ; Native Mode
    xce
    .A16        ; 16 bit mode
    .I16
    rep #$30        
    pha         ; Push A
    phx         ; Push X
    phy         ; Push Y
    phd         ; Push data bank
    lda $00     ; Push RAM and ROM Banks
    pha

    ; RAM and ROM banks to 0
    stz $00
    stz $01

    ; Push a fake address for the stock RTI
    ;phk
    ;pea mt_scheduler_return     

    ; Do something to prove interrupt is alive
    lda $07ff
    inc
    sta $07ff

    ; 8 bit mode, emulation
    .A8         ; 8 bit mode
    .I8
    sep #$30   
    sec         ; Emulation mode
    xce

    ; Do stuff
    jsr ps2data_fetch
	jsr mouse_scan  ;scan mouse (do this first to avoid sprite tearing)
	jsr joystick_scan
	jsr clock_update
	jsr cursor_blink
	jsr kbd_scan
	jsr led_update

    ; Acknowlege IRQ
    lda #1
    sta VERA_ISR

    ; 16 bit mode, no emulation
    .A16
    .I16   
    clc 
    xce
    rep #$30

    ; ** BEGIN Context Switch

    ; taskTable[currentTask] = SP

    ; @1: currentTask++

    ; if currentTask = max_tasks currentTask = 0

    ; if taskTable[curentTask] == 0 goto @1

    ; SP = taskTable[currentTask]

    ; ** END Context Switch

    ; Restore State
    pla         ; Pull RAM and ROM Banks
    sta $00
    pld         ; Pull data bank
    ply         ; Pull Y
    plx         ; Pull X
    pla         ; Pull A
    plp         ; Emulator back to original
    xce
    plp         ; Pull Status
    
    ; Return from interrupt
    rti

.endproc