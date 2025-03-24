.p816

.export thread

.include "mac.inc"
.include "multitask.inc"
.include "multitest.inc"
.include "regs.inc"

.segment "MULTITEST"

.proc start: near
    
    ; Native Mode
    clc
    xce    

    ; 16 bit mode
    .A16
    .I16
    rep #$30        

    ; ** Initialize multitasking engine
    jsl mt_init

    ; ** Start a new process
    Multitask_Start thread, #$0000, proc_stack, ^D

    ; 8 bit mode, emulation
    .A8
    .I8
    sep #$30
    sec
    xce           

    rts
.endproc

.proc thread: near
    top:
        lda $07fd
        inc
        sta $07fd
    bra top
    rtl
.endproc

.segment "DATA"    
    .repeat $3f
        .byte $00
    .endrep
    proc_stack: .byte $00