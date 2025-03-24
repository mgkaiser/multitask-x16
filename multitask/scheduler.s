.p816

.include "multitask.inc"
.include "regs.inc"
.include "io.inc"

.export mt_scheduler

; from main.s
.import currentTask
.import oldIrq

.segment "MULTITASK"

.proc mt_scheduler: near              

    ; Save the state        
    pha
    phx
    phy
    php
    phd

    ; Push a fake address for the stock RTI
    phk
    pea mt_scheduler_return     

    ; Do something to prove interrupt is alive
    lda $07ff
    inc
    sta $07ff

    ; Chain to old interrrupt in 8 bit mode
    ;.A8    
    ;sep #$30        
    jmp (oldIrq)    

.endproc

.proc mt_scheduler_return: near    

    ; 16 bit mode    
    .A16
    .I16
    rep #$30   

    ; Store current context    

    ; Advance the task pointer

    ; Make next task active

    ; Restore state
    pld
    plp
    ply
    plx
    pla
    
    ; Return from interrupt
    rti

.endproc