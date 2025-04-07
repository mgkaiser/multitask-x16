.p816

.include "mac.inc"
.include "multitask.inc"
.include "regs.inc"
.include "io.inc"

; Interrupt Sources
INT_VSYNC   = %00000001
INT_LINE    = %00000010
INT_SPRCOL  = %00000100
INT_AUDIO   = %00001000

.export mt_scheduler, mt_init, mt_start

.segment "INTERRUPT_DATA"
    
    tasks: .res .sizeof(struct_tasks)

.segment "INTERRUPT_VEC"

    vec_vsync:  .dword $000000
    vec_line:   .dword $000000    
    vec_sprcol: .dword $000000    
    vec_audio:  .dword $000000    

.segment "INTERRUPT"

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
    SetLocalCount 0

    ; Declare parameters - reverse order        
    DeclareParam r_retVal, 0  

    ; Setup stack frame
    SetupStackFrame    

    ; Current task is 0

    lda #$0000
    sta tasks + struct_tasks::currentTask

    ; Task 0 is used
    lda #$ffff
    sta tasks

    ; All other tasks are not used
    ldx #$0002
    lda #$0000
    @1:
        sta tasks, x
        inx 
        inx
        cpx# MAX_TASKS*2
    bne @1    

    ; Setup vectors    
    set_int_vec mt_dummy_vec, vec_vsync    
    set_int_vec mt_dummy_vec, vec_line    
    set_int_vec mt_dummy_vec, vec_sprcol
    set_int_vec mt_dummy_vec, vec_audio   

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

; mt_scheduler - The scheduler itself.  DO NOT CALL DIRECTLY
; IN:
;   None
; OUT:
;   None
.proc mt_scheduler: near  
    
    ; Save the state        
    mode16        
    pha         ; Push A
    phx         ; Push X
    phy         ; Push Y
    phd         ; Push direct page
    phb         ; Push data bank    
    lda f:$00   ; Push RAM and ROM Banks    
    pha    

    sei

    ; RAM and ROM banks to 0
    lda #$0000
    sta f:$00    

    ; Remember the current stack    
    lda f:tasks + struct_tasks::currentTask         
    tax
    tsc
    sta f:tasks, x
            
    mode8

    lda #INT_VSYNC
    bit VERA_ISR  
    beq @1
        ; Do INT_VSYNC here                  
        jsl vec_vsync           
        ;lda #$01
        ;sta f:$9fba
        
        ; Ack INT_VSYNC
        lda VERA_ISR
        ora #INT_VSYNC
        sta VERA_ISR        

@1: lda #INT_LINE
    bit VERA_ISR  
    beq @2
        ; Do INT_LINE here
        jsl vec_line        
        ;lda #$02
        ;sta f:$9fba
        
        ; Ack INT_VSYNC
        lda VERA_ISR
        ora #INT_LINE
        sta VERA_ISR        

@2: lda #INT_SPRCOL
    bit VERA_ISR  
    beq @3
        ; Do INT_SPRCOL here
        jsl vec_sprcol        
        ;lda #$03
        ;sta f:$9fba
        
        ; Ack INT_SPRCOL
        lda VERA_ISR
        ora #INT_SPRCOL
        sta VERA_ISR                

@3: lda #INT_AUDIO
    bit INT_AUDIO
    beq @4
        ; Do INT_AUDIO here
        jsl vec_audio        
        ;lda #$04
        ;sta f:$9fba
        
        ; Ack INT_AUDIO
        lda VERA_ISR
        ora #INT_AUDIO
        sta VERA_ISR                
@4:            

    mode16

    ;; Do normal IRQ housekeeping here? - Or should this happen on task 0?

    ; ** BEGIN Context Switch - This will also clean up the switched stack
    ; Remember the current stack        
    
    nextTask:

        ; tasks.struct_tasks::currentTask++
        lda f:tasks + struct_tasks::currentTask
        inc
        inc

        ; if tasks.struct_tasks::currentTask = MAX_TASKS tasks.struct_tasks::currentTask = 0
        cmp #MAX_TASKS * 2
        bne skipZero
            lda #$0000
        skipZero:        
        sta f:tasks + struct_tasks::currentTask

        ; if tasks[currentTask] == 0 goto @1
        tax
        lda f:tasks, x
        cmp #$0000

    beq nextTask   
    
    ; Make the next task active
    tcs    

    ; Which task is up next?
    ;mode8
    ;txa
    ;sta f:$9fb9       
    ;mode16

    ; ** END Context Switch

    cli

    ; Restore State          
    pla         ; Pull RAM and ROM Banks
    sta f:$00
    plb         ; Pull data bank
    pld         ; Pull direct page
    ply         ; Pull Y
    plx         ; Pull X
    pla         ; Pull A        
        
    ; Return from interrupt
    rti

.endproc

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
    DeclareLocal l_currentStack, 1
    DeclareLocal l_newProcSlot, 0
    SetLocalCount 2

    ; Declare parameters - reverse order
    DeclareParam p_dataBank, 0
    DeclareParam p_stackAddress, 1
    DeclareParam p_processAddr, 2       ; Skip 1 because long    
    DeclareParam r_retVal, 4
    
    ; Setup stack frame
    SetupStackFrame
            
    BEGIN_CRITICAL_SECTION

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

    ;;# TODO: Do something sane when task runs to completion?  It should remove itself from task table.  
    ;;       Push a return address so when task RTL it removes task from task table
    ;;       It should deallocate the memory it sits on.
    ;;       TaskInfo?  malloc_handle, stdin_handle, stdout_handle

    ; setup the new stack
    mode8
    lda p_processAddr + 2   ; Program Bank of new process
    pha    
    mode16         
    lda p_processAddr       ; Address of new process    
    pha
    mode8
    lda #$30    
    pha                 ; Flags                       
    mode16
    pha                 ; A for new process
    phx                 ; X for new process
    phy                 ; Y for new process    
    lda #$0000          ; Direct Page
    pha             
    mode8
    lda p_dataBank      ; Data Bank of new process
    pha  
    mode16               
    lda #$00            ; RAM/ROM banks for new process
    pha    

    ; Store where the stack pointer it in the task table
    tsc    
    ldy l_newProcSlot    
    sta tasks, y      

    ; restore current stack
    ldx l_currentStack
    txs              

    end:

    END_CRITICAL_SECTION
    
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
    SetLocalCount 0

    ; Declare parameters - reverse order        
    DeclareParam r_retVal, 0

    ; Setup stack frame
    SetupStackFrame

    ldy #$0000
    loop:
        lda tasks, y
        cmp #$00
        beq end
        iny
        iny
        cpy #MAX_TASKS * 2
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

.proc mt_dummy_vec: near
    rtl
.endproc



