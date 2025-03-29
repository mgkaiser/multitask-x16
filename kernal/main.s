.p816

.include "mac.inc"
.include "io.inc"
;.include "multitask.inc"
.include "pipes.inc"

.export vec_reset_02

.import iokeys

.import ioinit, screen_init, screen_clear_line, screen_get_color
.import screen_set_color, screen_get_char, screen_set_char
.import screen_set_char_color, screen_get_char_color
.import screen_set_position, screen_get_position

.import i2c_read_byte, i2c_write_byte, i2c_batch_read, i2c_batch_write
.import i2c_read_first_byte, i2c_read_next_byte, i2c_read_stop, i2c_direct_read
.import i2c_write_first_byte, i2c_write_next_byte, i2c_write_stop
.import i2c_restore, i2c_mutex

.import mt_init

.import pipe_init, pipe_push, pipe_pop
.import pipe_conout, pipe_kbdin

.segment "KVAR"
character: .byte $00

.segment "KERNAL"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Stuff in "drivers" are low level, call directly, never called from user programs
;;
;; Stuff above "drivers" are high level, uses params and stack frame, can be called by user programs
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vec_reset_02:

    ; Suspend interrupts
    sei
    
    ; Native Mode
    modeNative

    ; Setup stack
    mode16
    ldx #$01ff	
	txs      
    mode8

    jsr ioinit           ;go initilize i/o devices
    jsr i2c_restore      ;release I2C pins and clear mutex flag
    jsr screen_init  
	;jsr ramtas           ;go ram test and set
	;jsr restor           ;go set up os vectors	
	;jsr ps2data_init
    
    ; Initialize pages
    stz $00
    stz $01
    
    ; Start Interrupts
    jsr mt_init   
    jsr iokeys     
    cli

    ; Init Pipes    
    mode16
    Pipe_Init pipe_conout
    Pipe_Init pipe_kbdin    
    mode8

    ; Clear the screen
    ldx #$00
    @1:    
        jsr screen_clear_line
        inx
        cpx #60
    bne @1    
    
    ldx #$01
    jsr screen_set_position
    lda #2
    ldx #$61
    ldy #$01
    jsr screen_set_char_color
        
    lda #15    
    iny
    jsr screen_set_char_color
        
    lda #15
    iny
    jsr screen_set_char_color
    
    lda #2    
    iny
    jsr screen_set_char_color

    loop:

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
        beq loop
        ldx #$61
        ldy #$01
        jsr screen_set_char_color        
        
    jmp loop    

