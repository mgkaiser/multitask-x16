.p816

.include "mac.inc"
.include "regs.inc"
.include "pipes.inc"

; https://embedjournal.com/implementing-circular-buffer-embedded-c/

.export pipe_init, pipe_push, pipe_pop

.export pipe_conout
.export pipe_kbdin

.segment "PIPES_JUMP"

.segment "PIPES_VAR"
    PIPE_SIZE = .sizeof(struct_pipe)
    pipe_conout:    .res PIPE_SIZE
    pipe_kbdin:     .res PIPE_SIZE

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

    mode8   

    ; Make head point to 0
    ldy #struct_pipe::head
    lda #$0000
    sta [pPipe], y

    ; Make tail point to 0
    ldy #struct_pipe::tail    
    sta [pPipe], y

    mode16

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
    DeclareLocal l_Next, 0
    SetLocalCount 1

    ; Declare parameters - reverse order        
    DeclareParam value, 0
    DeclareParam pPipe, 1       ; Skip 2 because long param        
    DeclareParam r_retVal, 3

    ; Setup stack frame
    SetupStackFrame    

    mode8

    ; next = pPipe->struct_pipe::head + 1;
    ldy #struct_pipe::head
    lda [pPipe], y 
    inc
    sta l_Next

    ; if (next >= PIPE_LEN)
    cmp #PIPE_LEN
    bcc @1

        ; next = 0;
        stz l_Next

@1:

    ; if (next == pPipe->struct_pipe::tail)            if the head + 1 == tail, circular buffer is full
    ldy #struct_pipe::tail
    lda [pPipe], y 
    cmp l_Next
    bne @2

        ; return -1;
        sec 
        bra end

@2:

    ; pPipe[pPipe->struct_pipe::head] = data;          ; Load data and then move    
    ldy #struct_pipe::head
    lda [pPipe], y 
    tay                                         ; Y = pPipe->struct_pipe::head
    lda value
    sta [pPipe], y    
    
    ; pPipe->struct_pipe::head = next;                 ; head to next data offset.
    ldy #struct_pipe::head
    lda l_Next
    sta [pPipe], y

    ; Success
    clc

end:

    mode16

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
    DeclareLocal l_Next, 0
    SetLocalCount 1

    ; Declare parameters - reverse order            
    DeclareParam pPipe, 0       ; Skip 2 because long param        
    DeclareParam r_retVal, 2

    ; Setup stack frame
    SetupStackFrame    

    mode8

    ; if (pPipe->struct_pipe::head == pPipe->struct_pipe::tail)  // if the head == tail, we don't have any data
    ldy #struct_pipe::head    
    lda [pPipe], y
    ldy #struct_pipe::tail
    cmp [pPipe], y
    bne @1

    ; return -1;
    sec 
    bra end

@1:

    ; next = pPipe->struct_pipe::tail + 1;  // next is where tail will point to after this read.
    ldy #struct_pipe::tail
    lda [pPipe], y 
    inc
    sta l_Next

    ; if (next >= PIPE_LEN)
    cmp #PIPE_LEN
    bcc @2

        ; next = 0;
        stz l_Next

@2:

    ; *r_retVal = pPipe[pPipe->struct_pipe::tail];  // Read data and then move    
    ldy #struct_pipe::tail
    lda [pPipe], y 
    tay                                         
    lda [pPipe], y    
    and #$00ff
    sta r_retVal
    
    ; c->tail = next;              // tail to next offset.
    ldy #struct_pipe::tail
    lda l_Next
    sta [pPipe], y

    ; Success! 
    clc

end:

    mode16

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc