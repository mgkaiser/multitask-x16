.p816

.include "mac.inc"
.include "multitask.inc"
.include "regs.inc"
.include "io.inc"
.include "kernal.inc"

.export mt_scheduler
.export mt_init

.segment "INTERRUPT_DATA"
    currentTask: 	.word $0000     ; Current task	
	taskTable:      .res $40		; 64 bytes to hold task table.

.segment "INTERRUPT"

;# TODO: Clean up to use params and stack frame (small exceptiob because currentTask and taskTable are "global")
;# TODO: Use LONG to address task table and current task
.proc mt_init: near  

    mode16

    ; Current task is 0
    lda #$0000
    sta currentTask

    ; Task 0 is used
    lda #$ffff
    sta taskTable

    ; All other tasks are not used
    ldx #$0002
    lda #$0000
    @1:
        sta taskTable, x
        inx 
        inx
        cpx# max_tasks*2
    bne @1
    mode8

    rts
.endproc

.proc mt_scheduler: near      
            
    ; Save the state        
    mode16        
    pha         ; Push A
    phx         ; Push X
    phy         ; Push Y
    phd         ; Push data bank
    lda $00   ; Push RAM and ROM Banks
    pha

    ; RAM and ROM banks to 0
    stz $00
    stz $01
    
    ; Do something to prove interrupt is alive
    lda $07ff
    inc
    sta $07ff

    ;; BEGIN: Break out and dispatch the various kinds of IRQ

    ; Acknowlege IRQ
    lda #1
    sta VERA_ISR  

    ;; END: Break out and dispatch the various kinds of IRQ

    ;; Do normal IRQ housekeeping here?


    ; ** BEGIN Context Switch - This will also clean up the switched stack
    ; Remember the current stack    

    ; Remember the current stack
    ldy currentTask    
    tsc
    sta taskTable, y
    
    nextTask:

        ; currentTask++
        lda currentTask
        inc
        inc

        ; if currentTask = max_tasks currentTask = 0
        cmp #max_tasks * 2
        bne skipZero
            lda #$0000
        skipZero:        
        sta currentTask

        ; if taskTable[curentTask] == 0 goto @1
        tay
        lda taskTable, Y
        cmp #$0000

    beq nextTask   

    ; Make the next task active
    tcs    

    ; ** END Context Switch

    ; Restore State
    pla         ; Pull RAM and ROM Banks
    sta $00
    pld         ; Pull data bank
    ply         ; Pull Y
    plx         ; Pull X
    pla         ; Pull A    
    mode8        
    
    ; Return from interrupt
    rti

.endproc