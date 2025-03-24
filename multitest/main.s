.p816

.export thread

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
    lda #thread             ; Address of the process we are starting
    sta r0
    lda #$00                ; Bank of the process we are starting
    sta r1L
    lda #proc_stack - 1     ; Stack for the process we are starting
    sta r2
    lda #$00                ; Databank for the process we are starting
    sta r3L    
    jsl mt_start            ; Start the process

    ; 8 bit mode
    .A8
    .I8
    sep #$30           

    rts
.endproc

.proc thread: far
    rtl
.endproc

.segment "DATA"    
        .repeat $40
            .byte $00
        .endrep
    proc_stack:     ; SP goes to TOP of stack