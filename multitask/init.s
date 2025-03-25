.p816

.include "mac.inc"
.include "multitask.inc"
.include "regs.inc"
.include "banks.inc"
.include "io.inc"

.export mt_init
.export mt_done

; from main.s
.import currentTask
.import oldIrq

; from scheduler.s
.import mt_scheduler

.segment "MULTITASK"

; mt_init - Start task scheduler
; (Use Native Mode)
; IN:
;   None
; OUT:
;   None
.proc mt_init: near
        
    ; 16 bit mode
    mode16  

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order         
    DeclareLocalPointerWithValue l_pCurrentTask, currentTask, 2
    DeclareLocalPointerWithValue l_pMTScheduler, mt_scheduler, 1
    DeclareLocalPointerWithValue l_pOldIrq, oldIrq, 0
    SetLocalCount 3

    ; Declare parameters - reverse order        
    DeclareParam r_retVal, 0  

    ; Setup stack frame
    SetupStackFrame

    lda l_pCurrentTask    
    sta $0700
    lda l_pMTScheduler
    sta $0702
    lda l_pOldIrq
    sta $0704

    ; interrupts off
    sei        

    ; Are we initialized?
    lda (l_pOldIrq)
    cmp #$0000
    bne alreadyInitialized

    ; Always start with task 0
    lda #$0000
    sta (l_pCurrentTask)

    ; Remember old IRQ
    lda irq + 1
    sta (l_pOldIrq)

    ; Attach new IRQ
    lda l_pMTScheduler
    sta irq + 1

    ; Setup first VBLANK
    lda #1
    sta VERA_IEN
    
    alreadyInitialized:

    ; interrupts on
    cli

    ; Store the results
    sty r_retVal    

    ; Exit the procedure
    FreeLocals
    ProcSuffix        

    rtl

.endproc

; mt_init - Terminate task scheduler (and all processes except for root process)
; (Use Native Mode)
; IN:
;   None
; OUT:
;   None
.proc mt_done: near

    ; 16 bit mode
    mode16  

    ; Save working registers
    ProcPrefix 
    ProcFar 
    
    ; Create local variable - Number in descending order          
    DeclareLocalPointerWithValue l_pOldIrq, oldIrq, 0
    SetLocalCount 1

    ; Declare parameters - reverse order        
    DeclareParam r_retVal, 0  

    ; Setup stack frame
    SetupStackFrame
    
    ; interrupts off
    sei        

    ; Are we initialized?
    lda oldIrq
    cmp #$0000
    beq alreadyDone

    ; Restore old irq
    lda (l_pOldIrq)
    sta irq + 1

    alreadyDone:

    ; interrupts on
    cli

    ; Store the results
    sty r_retVal    

    ; Exit the procedure
    FreeLocals
    ProcSuffix    

    rtl
.endproc