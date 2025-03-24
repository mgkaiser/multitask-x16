.p816

.include "multitask.inc"
.include "regs.inc"

; from main.s
.import taskTable

.export mt_start
.export mt_kill

.segment "MULTITASK"

; mt_start - Start a new process
; (Use Native Mode)
; IN:
;   R0 - address of process
;   R1 - bank of process
;   R2 - stack address of process (must be in 1st 64k)
;   R3 - data bank of process
; OUT:
;   R0 - Process ID (0 = fail)
; CLOBBERS:
;   R4, R5
.proc mt_start: near

    ; interrupts off
    sei    

    ; 16 bit mode
    .A16
    .I16
    rep #$30        

    ; Make sure there is space in the task table
    jsr find_proc_slot
    cpx #$ff
    bne skip1
        lda #$0000
        sta r0
        bra end
    skip1:
    stx r4    

    ; remember current stack
    tsx
    stx r5

    ; set the new stack
    ldx r2    
    txs    

    ; setup the new stack
    .A8         ; 8 bit mode
    .I8
    sep #$30
    lda #$30    ; Status for new process
    pha
    lda #$31    ; Emultion mode for new process
    pha         
    .A16        ; 16 bit mode
    .I16
    rep #$30      
    pha         ; A for new process
    phx         ; X for new process
    phy         ; Y for new process    
    .A8         ; 8 bit mode
    .I8
    sep #$30
    lda r3L     ; Data Bank of new process
    pha
    lda #$00    ; RAM/ROM banks for new process
    pha
    lda r1L     ; Program Bank of new process
    pha    
    .A16        ; 16 bit mode
    .I16
    rep #$30    ; Address of new process
    lda r0
    pha       

    ; Store where the stack pointer it in the task table
    tsx
    txa
    ldx r4    
    sta taskTable, x    
    
    ; restore current stack
    ldx r5
    txs

    end:

    ; interrupts on
    cli

    rtl
.endproc

; mt_kill - Terminate a process
; (Use Native Mode)
; IN:
;   X - Process ID
; OUT:
;   None
.proc mt_kill: near     

    ; interrupts off
    sei    

    ; 16 bit mode
    .A16
    .I16
    rep #$30   

    ; Remove the task from the task table
    lda #$0000
    sta taskTable, x

    ; interrupts on
    cli

    rtl
.endproc

; find_proc_slot - Find the next available processor slot
; (Use .A16, .I16)
; IN:
;   none
; OUT:
;   X - Process ID
.proc find_proc_slot: near
    ldx #$0000
    loop:
        lda taskTable, x
        cmp #$00
        beq end
        inx
        cpx #max_tasks
    bne loop
    ldx #$ff
    end:
    rts
.endproc