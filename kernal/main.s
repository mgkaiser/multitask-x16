.p816

.include "mac.inc"

.export vec_reset_02

.import ioinit, screen_init, screen_clear_line, screen_get_color
.import screen_set_color, screen_get_char, screen_set_char
.import screen_set_char_color, screen_get_char_color
.import screen_set_position, screen_get_position

.import i2c_read_byte, i2c_write_byte, i2c_batch_read, i2c_batch_write
.import i2c_read_first_byte, i2c_read_next_byte, i2c_read_stop, i2c_direct_read
.import i2c_write_first_byte, i2c_write_next_byte, i2c_write_stop
.import i2c_restore, i2c_mutex

.segment "KERNAL"

vec_reset_02:

    ; Suspend interrupts
    sei

    ; Setup stack
    ldx #$ff	
	txs

    jsr ioinit           ;go initilize i/o devices
	;jsr ramtas           ;go ram test and set
	;jsr restor           ;go set up os vectors
	jsr i2c_restore      ;release I2C pins and clear mutex flag
	;jsr ps2data_init
    jsr screen_init    

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

    ; Interupts back on
    cli

