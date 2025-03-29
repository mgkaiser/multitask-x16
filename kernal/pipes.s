.p816

.include "mac.inc"
;.include "multitask.inc"
.include "regs.inc"
.include "pipes.inc"

.export pipe_init, pipe_push, pipe_pop

.segment "PIPES"

.proc pipe_init: near

    ; 16 bit mode
    mode16  

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order         
    ;DeclareLocalPointerWithValue l_pCurrentTask, currentTask, 2
    ;DeclareLocalPointerWithValue l_pMTScheduler, mt_scheduler, 1
    ;DeclareLocalPointerWithValue l_pOldIrq, oldIrq, 0
    SetLocalCount 0

    ; Declare parameters - reverse order        
    DeclareParam pPipe, 0       ; Skip 2 because long param    
    DeclareParam r_retVal, 2

    ; Setup stack frame
    SetupStackFrame    

    ; Make head point to 0
    ldy #pipe::head
    lda #$0000
    sta [pPipe], y

    ; Make tail point to 0
    ldy #pipe::tail    
    sta [pPipe], y

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    ; 8 bit mode
    mode8  

    rtl

.endproc

.proc pipe_push: near

    ; 16 bit mode
    mode16  

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order                 
    DeclareLocal l_NewTail, 0
    SetLocalCount 1

    ; Declare parameters - reverse order        
    DeclareParam value, 0
    DeclareParam pPipe, 1       ; Skip 2 because long param        
    DeclareParam r_retVal, 3

    ; Setup stack frame
    SetupStackFrame    

    ; Calculate new tail, including wraparound

    ; If head = tail-1 then full

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    ; 8 bit mode
    mode8  

    rtl

.endproc

; ***************************************************************
; ** IN:
; **    16-bit RetVal
; **    16-bit pPipe - High Word ($00kk)
; **    16-bit pPipe - Low Word ($pppp)
; **    16-bit value - (only low byte is pushed to pipe)
; ***************************************************************
; ** OUT:
; **
; ***************************************************************

.proc pipe_pop: near

    ; 16 bit mode
    mode16  

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order             
    DeclareLocal l_NewHead, 0
    SetLocalCount 1

    ; Declare parameters - reverse order            
    DeclareParam value, 0
    DeclareParam pPipe, 1       ; Skip 2 because long param        
    DeclareParam r_retVal, 3

    ; Setup stack frame
    SetupStackFrame    

    ; Calculate new head, including wraparound

    ; if head == tail then empty

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    ; 8 bit mode
    mode8  

    rtl

.endproc