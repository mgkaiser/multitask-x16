.p816

.include "mac.inc"
.include "regs.inc"
.include "pipes.inc"

; https://embedjournal.com/implementing-circular-buffer-embedded-c/

.export pipe_init, pipe_push, pipe_pop

.segment "PIPES"

; ***************************************************************
; ** IN:
; **    16-bit RetVal
; **    16-bit pPipe - High Word ($00kk)
; **    16-bit pPipe - Low Word ($pppp)
; ***************************************************************
; ** OUT:
; **    RetVal = No meaningful value
; ***************************************************************
.proc pipe_init: near

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order         
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
; **    RetVal = No meaningful value
; **    Carry Clear = Success
; **    Carry Set   = Failure
; ***************************************************************
.proc pipe_push: near

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order                 
    DeclareLocal l_pBuffer, 2
    DeclareLocal l_Next, 0
    SetLocalCount 1

    ; Declare parameters - reverse order        
    DeclareParam value, 0
    DeclareParam pPipe, 1       ; Skip 2 because long param        
    DeclareParam r_retVal, 3

    ; Setup stack frame
    SetupStackFrame    

    ; next = pPipe->pipe::head + 1;
    ldy #pipe::head
    lda [pPipe], y 
    inc
    sta l_Next

    ; if (next >= PIPE_LEN)
    cmp #PIPE_LEN
    bcc @1

        ; next = 0;
        stz l_Next

@1:

    ; if (next == pPipe->pipe::tail)            if the head + 1 == tail, circular buffer is full
    ldy #pipe::tail
    lda [pPipe], y 
    cmp l_Next
    bne @2

        ; return -1;
        sec 
        bra end

@2:

    ; l_pBuffer = &(pPipe->pipe::buffer)
    clc
    lda pPipe
    adc #pipe::buffer
    sta l_pBuffer
    lda pPipe + 2
    sta l_pBuffer + 2

    ; l_pBuffer[pPipe->pipe::head] = data;      ; Load data and then move
    mode8
    ldy #pipe::head
    lda [pPipe], y 
    tay                                         ; Y = pPipe->pipe::head
    lda value
    sta [l_pBuffer], y
    mode16
    
    ; pPipe->pipe::head = next;                 ; head to next data offset.
    ldy #pipe::head
    lda l_Next
    sta [pPipe], y

    ; Success
    clc

end:

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

; ***************************************************************
; ** IN:
; **    16-bit RetVal
; **    16-bit pPipe - High Word ($00kk)
; **    16-bit pPipe - Low Word ($pppp)
; ***************************************************************
; ** OUT:
; **    RetVal = Byte popped from pipe
; **    Carry Clear = Success
; **    Carry Set   = Failure
; ***************************************************************
.proc pipe_pop: near
    
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order             
    DeclareLocal l_pBuffer, 2
    DeclareLocal l_Next, 0
    SetLocalCount 3

    ; Declare parameters - reverse order            
    DeclareParam pPipe, 0       ; Skip 2 because long param        
    DeclareParam r_retVal, 2

    ; Setup stack frame
    SetupStackFrame    

    ; if (pPipe->pipe::head == pPipe->pipe::tail)  // if the head == tail, we don't have any data
    ldy #pipe::head    
    lda [pPipe], y
    ldy #pipe::tail
    cmp [pPipe], y
    bne @1

    ; return -1;
    sec 
    bra end

@1:

    ; next = pPipe->pipe::tail + 1;  // next is where tail will point to after this read.
    ldy #pipe::tail
    lda [pPipe], y 
    inc
    sta l_Next

    ; if (next >= PIPE_LEN)
    cmp #PIPE_LEN
    bcc @2

        ; next = 0;
        stz l_Next

@2:

    ; l_pBuffer = &(pPipe->pipe::buffer)
    clc
    lda pPipe
    adc #pipe::buffer
    sta l_pBuffer
    lda pPipe + 2
    sta l_pBuffer + 2

    ; *r_retVal = l_pBuffer[pPipe->pipe::tail];  // Read data and then move
    mode8
    ldy #pipe::tail
    lda [pPipe], y 
    tay                                         
    lda [l_pBuffer], y
    mode16
    and #$00ff
    sta r_retVal
    
    ; c->tail = next;              // tail to next offset.
    ldy #pipe::tail
    lda l_Next
    sta [pPipe], y

    ; Success! 
    clc

end:

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc