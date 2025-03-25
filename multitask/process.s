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
    mode16    

    ; Save working registers
    ProcPrefix   
    ProcFar 

    ; Create local variable - Number in descending order
    DeclareLocal l_newProcSlot, 2
    DeclareLocal l_currentStack, 1
    DeclareLocalPointerWithValue l_pTaskTable, taskTable, 0
    SetLocalCount 3    

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
    Multitask_find_proc_slot
    cmp #$ffff
    bne skip1
        lda #$0000
        sta r_retVal
        bra end
    skip1:
    sta l_newProcSlot    

    ; remember current stack
    tsc
    sta l_currentStack

    ; set the new stack
    lda p_stackAddress    
    tcs    

    ; setup the new stack
    mode8
    lda p_processBank   ; Program Bank of new process
    pha    
    mode16         
    lda p_processAddr   ; Address of new process
    pha       
    mode8
    lda #$30            ; Status for new process
    pha
    lda #$31            ; Native mode for new process
    pha         
    mode16
    pha                 ; A for new process
    phx                 ; X for new process
    phy                 ; Y for new process
    mode8        
    lda p_dataBank      ; Data Bank of new process
    pha
    mode16 
    lda #$00            ; RAM/ROM banks for new process
    pha    

    ; Store where the stack pointer it in the task table
    tsc    
    ldy l_newProcSlot    
    sta (l_pTaskTable), y        
    
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
    mode16     

    ; Save working registers
    ProcPrefix
    ProcFar    

    ; Create local variable - Number in descending order 
    DeclareLocalPointerWithValue l_pTaskTable, taskTable, 0   
    SetLocalCount 1

    ; Declare parameters - reverse order
    DeclareParam p_ProcessId, 0 
    DeclareParam r_retVal, 1   
    
    ; Setup stack frame
    SetupStackFrame

    ; interrupts off
    sei    
     
    ; Make sure task 0 cannot be killed
    ldy p_ProcessId
    cpy #$0000
    beq skip

        ; Remove the task from the task table
        lda #$0000
        sta (l_pTaskTable), y

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

    ; 16 bit mode
    mode16    
    
    ; Save working registers
    ProcPrefix 
    ProcNear  
    
    ; Create local variable - Number in descending order    
    DeclareLocalPointerWithValue l_pTaskTable, taskTable, 0
    SetLocalCount 1

    ; Declare parameters - reverse order        
    DeclareParam r_retVal, 0

    ; Setup stack frame
    SetupStackFrame

    ldy #$0000
    loop:
        lda (l_pTaskTable), y
        cmp #$00
        beq end
        iny
        iny
        cpy #max_tasks * 2
    bne loop
    ldy #$ffff
    end:

    ; Store the results
    sty r_retVal    

    ; Exit the procedure
    FreeLocals
    ProcSuffix    

    rts
.endproc