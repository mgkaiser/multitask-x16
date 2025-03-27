.p816

.export thread
.export proc_stack

.include "mac.inc"
.include "multitask.inc"
.include "multitest.inc"
.include "regs.inc"

.segment "MULTITEST"

.proc start: near
    
    ; 16 bit mode
    modeNative    
    mode16   

    ; ** Start a new process
    ;Multitask_Start thread, #$0000, proc_stack, ^D

    ; ** Initialize multitasking engine
    Multitask_Init        

    ;.byte $db
    mode8    
    loop:
        ;.byte $db    
        lda #$41
        jsr $ffd2
    bra loop
    
    ; 8 bit mode    
    mode8    
    modeEmulation
    
    rts
.endproc

.proc thread: near
    top:
        lda $07fd
        inc
        sta $07fd
        mode8
        lda #$42
        jsr $ffd2
        mode16        
    bra top
    rtl
.endproc

.segment "DATA"    
    .repeat $3f
        .byte $00
    .endrep
    proc_stack: .byte $00