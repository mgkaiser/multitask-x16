.p816

.include "mac.inc"
.include "multitask.inc"
.include "regs.inc"
.include "io.inc"
.include "kernal.inc"

; Kernal routines we're "borrowing"
cursor_blink    = $c86c
led_update      = $e73a
kbd_scan        = $d242
clock_update    = $e94c
ps2data_fetch   = $d104

; Pointers to variables
pCurrentTask    =  $7c
pTaskTable       =  $7e

.export mt_scheduler

; from main.s
.import currentTask
.import taskTable

.segment "MULTITASK"

; This is a special procedure.  DO NOT use paramater passing.  This is the interrupt handler
.proc mt_scheduler: near              

    ; Save the state
    php         ; Push Flags
    xce         ; Push emulator flag
    php
    modeNative
    mode16        
    pha         ; Push A
    phx         ; Push X
    phy         ; Push Y
    phd         ; Push data bank
    lda $00     ; Push RAM and ROM Banks
    pha

    ; RAM and ROM banks to 0
    stz $00
    stz $01

    ; Get pointers to variables (relocatable code)      
    per taskTable
    pla
    sta pTaskTable
    per currentTask
    pla
    sta pCurrentTask

    ; Do something to prove interrupt is alive
    lda $07ff
    inc
    sta $07ff

    ; Change direct page to $0000 for the Kernal routines 
    lda #$0000        
    tcd

    ; Remember the current stack
    lda (pCurrentTask)
    tay
    tsc
    sta(pTaskTable) ,y

    ; Are we running task 0?
    lda (pCurrentTask)
    cmp #$0000
    beq skipStackSet

        ; If we're not running task 0, switch to the task 0 stack    
        lda (pTaskTable)
        tcs

    skipStackSet:

    ; 8 bit mode
    mode8           
    modeEmulation

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

    ; 16 bit mode
    modeNative    
    mode16 

    ; ** BEGIN Context Switch - This will also clean up the switched stack
    ; Remember the current stack    

    nextTask:

        ; @1: currentTask++
        lda (pCurrentTask)
        inc
        inc

        ; if currentTask = max_tasks currentTask = 0
        cmp #max_tasks * 2
        bne skipZero
            lda #$0000
        skipZero:        
        sta (pCurrentTask)

        ; if taskTable[curentTask] == 0 goto @1
        tay
        lda(pTaskTable), Y
        cmp #$0000
        beq nextTask   

        ; Debug out pCurrentTask, Y and *pTaskTable + Y     
        lda pCurrentTask
        sta $0700
        lda (pCurrentTask) 
        sta $0702
        lda pTaskTable
        sta $0704
        lda (pTaskTable), y
        sta $0706
        sty $0708

    ; SP = taskTable[currentTask]
    ;tcs
    lda #$0000
    sta (pCurrentTask)

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