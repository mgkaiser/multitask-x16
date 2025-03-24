.p816

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
    
    ; interrupts off
    sei    

    ; 16 bit mode
    .A16
    .I16
    rep #$30   

    ; Are we initialized?
    lda oldIrq
    cmp #$0000
    bne alreadyInitialized

    ; Remember old IRQ
    lda irq + 1
    sta oldIrq

    ; Attach new IRQ
    lda #mt_scheduler
    sta irq + 1     

    alreadyInitialized:

    ; interrupts on
    cli

    rtl

.endproc

; mt_init - Terminate task scheduler (and all processes except for root process)
; (Use Native Mode)
; IN:
;   None
; OUT:
;   None
.proc mt_done: near
    
    ; interrupts off
    sei    

    ; 16 bit mode
    .A16
    .I16
    rep #$30

    ; Are we initialized?
    lda oldIrq
    cmp #$0000
    beq alreadyDone

    ; Restore old irq
    lda oldIrq    
    sta irq + 1

    alreadyDone:

    ; interrupts on
    cli

    rtl
.endproc