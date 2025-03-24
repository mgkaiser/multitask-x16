.p816

.include "mac.inc"
.include "multitask.inc"
.include "regs.inc"

; from main.s
.import taskTable

.export mt_start
.export mt_kill

.segment "MULTITASK"

; mt_start - Start a new process
; (Use Native Mode)
; CALLING CONVENTION: Stack
; IN:
;   address of process
;   bank of process
;   stack address of process (must be in 1st 64k)
;   data bank of process
; OUT:
;   Process ID (0 = fail)
.proc mt_start: near
        
    ; 16 bit mode
    .A16
    .I16
    rep #$30        

    ; Save working registers
    ProcPrefix    

    ; Create local variable
    DeclareLocal l_newProcSlot, 0
    DeclareLocal l_currentStack, 1
    SetLocalCount 2

    ; Declare parameters - reverse order
    DeclareParam p_dataBank, 0
    DeclareParam p_stackAddress, 1
    DeclareParam p_processBank, 2
    DeclareParam p_processAddr, 3
    DeclareParam r_retVal, 4
    
    ; Setup stack frame
    SetupStackFrame
    
    ; interrupts off
    sei            

    ; Make sure there is space in the task table
    jsr find_proc_slot
    cpx #$ffff
    bne skip1
        lda #$0000
        sta r_retVal
        bra end
    skip1:
    stx l_newProcSlot    

    ; remember current stack
    tsx
    stx l_currentStack

    ; set the new stack
    ldx p_stackAddress    
    txs    

    ; setup the new stack
    .A8                 ;  8 bit mode
    .I8
    sep #$30
    lda #$30            ; Status for new process
    pha
    lda #$31            ; Native mode for new process
    pha         
    .A16                ; 16 bit mode
    .I16
    rep #$30      
    pha                 ; A for new process
    phx                 ; X for new process
    phy                 ; Y for new process    
    .A8                 ; 8 bit mode
    .I8
    sep #$30
    lda p_dataBank      ; Data Bank of new process
    pha
    lda #$00            ; RAM/ROM banks for new process
    pha
    lda p_processBank   ; Program Bank of new process
    pha    
    .A16                ; 16 bit mode
    .I16
    rep #$30            
    lda p_processAddr   ; Address of new process
    pha       

    ; Store where the stack pointer it in the task table
    tsx
    txa
    ldx l_newProcSlot    
    sta taskTable, x    
    
    ; restore current stack
    ldx l_currentStack
    txs

    end:

    ; interrupts on
    cli
    
    ; Exit the procedure
    FreeLocals
    ProcSuffix    
    
    rtl
.endproc

; mt_kill - Terminate a process
; (Use Native Mode)
; CALLING CONVENTION: Stack
; IN:
;   Process ID
; OUT:
;   Success/Failure = true/false
.proc mt_kill: near     

    ; 16 bit mode
    .A16
    .I16
    rep #$30        

    ; Save working registers
    ProcPrefix    

    ; Create local variable    
    SetLocalCount 0

    ; Declare parameters - reverse order
    DeclareParam p_ProcessId, 0 
    DeclareParam r_retVal, 1   
    
    ; Setup stack frame
    SetupStackFrame

    ; interrupts off
    sei    
     
    ; Make sure task 0 cannot be killed
    ldx p_ProcessId
    cpx #$0000
    beq skip

        ; Remove the task from the task table
        lda #$0000
        sta taskTable, x

        ; Return true 
        lda #$ffff
        sta r_retVal
        bra skip2

    skip:

        ; Return false
        lda #$0000
        sta r_retVal

    skip2:

    ; interrupts on
    cli

    ; Exit the procedure
    FreeLocals
    ProcSuffix    

    rtl
.endproc

; find_proc_slot - Find the next available processor slot
; (Use Native Mode)
; CALLING CONVENTION: Fastcall
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
    ldx #$ffff
    end:
    rts
.endproc