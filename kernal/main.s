.p816

.include "mac.inc"
.include "io.inc"
.include "multitask.inc"
.include "screen.inc"
.include "pipes.inc"

.export vec_reset_02

.import iokeys

.import ioinit, screen_init, screen_clear_line, screen_get_color
.import screen_set_color, screen_get_char, screen_set_char
.import screen_set_char_color, screen_get_char_color
.import screen_set_position, screen_get_position, screen_clear_screen

.import i2c_read_byte, i2c_write_byte, i2c_batch_read, i2c_batch_write
.import i2c_read_first_byte, i2c_read_next_byte, i2c_read_stop, i2c_direct_read
.import i2c_write_first_byte, i2c_write_next_byte, i2c_write_stop
.import i2c_restore, i2c_mutex

.import mt_init, mt_start

.import pipe_init, pipe_push, pipe_pop
.import pipe_conout, pipe_kbdin

.segment "KVAR"
character:  .byte $00
character2: .byte $00

.res $40 
proc_stack: 

.segment "KERNAL"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Stuff in "drivers" are low level, call directly, never called from user programs
;;
;; Stuff above "drivers" are high level, uses params and stack frame, can be called by user programs
;;
;; We're always in 16 bit mode except when we aren't....
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vec_reset_02:
    
    BEGIN_CRITICAL_SECTION
    
    ; Native Mode
    modeNative

    ; Setup stack
    mode16
    ldx #$01ff	
	txs      
    mode8

    jsr ioinit           ;go initilize i/o devices
    jsr i2c_restore      ;release I2C pins and clear mutex flag   
    ;jsr ramtas           ;go ram test and set
	;jsr restor           ;go set up os vectors	
	;jsr ps2data_init
     
    mode16

    ; Initialize pages - Ends up in $00 and $01 because 16 bit
    stz $00

    ; Initialize the screen driver
    Screen_Init
        
    ; Start Interrupts    
    Multitask_Init   
    
    ; Init Pipes        
    Pipe_Init pipe_conout
    Pipe_Init pipe_kbdin            

    ; Clear the screen        
    Screen_Clear_Screen    
    
    ; Start the 2nd thread
    Multitask_Start thread, #proc_stack, ^D    
        
    mode8
    ldx #$01
    jsr screen_set_position
    lda #1
    ldx #$61
    ldy #$01
    jsr screen_set_char_color
        
    lda #2    
    iny
    jsr screen_set_char_color
        
    lda #3
    iny
    jsr screen_set_char_color
    
    lda #4    
    iny
    jsr screen_set_char_color

    @2:

        BEGIN_CRITICAL_SECTION

        ldx #$03
        jsr screen_set_position
        lda character
        inc 
        sta character        
        ldx #$61
        ldy #$01
        jsr screen_set_char_color
    
        ldx #$42
        ldy #$07    
        jsr i2c_read_byte
        pha

        ldx #$02
        jsr screen_set_position
        pla
        cmp #$00
        beq @3
            ldx #$61
            ldy #$01
            jsr screen_set_char_color
        @3:
        
        END_CRITICAL_SECTION

        cop #$00        
        
    jmp @2    

.proc thread: near
    @1:
        lda $07fd
        inc
        sta $07fd
        mode8

        BEGIN_CRITICAL_SECTION

        ldx #$06
        jsr screen_set_position
        lda character2
        inc 
        sta character2       
        ldx #$61
        ldy #$01
        jsr screen_set_char_color

        END_CRITICAL_SECTION

        cop #$00
        mode16        
    bra @1
    rtl
.endproc