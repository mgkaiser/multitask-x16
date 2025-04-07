pr  = d1pra
ddr = d1ddra
SDA = (1 << 0)
SCL = (1 << 1)

.macro i2c_brief_delay
	pha
	pla
	pha
	pla
.endmacro

.macro sda_low
	lda #SDA
	tsb ddr
.endmacro

.macro sda_high
	lda #SDA
	trb ddr
.endmacro

.macro scl_high
.scope
	lda #SCL
	trb ddr

wait_for_clk:
	lda pr
	and #SCL
	beq wait_for_clk
.endscope
.endmacro

.macro scl_low
	lda #SCL
	tsb ddr
.endmacro

.macro i2c_nack
	sec
	send_bit
.endmacro

.macro send_bit
	bcs @1
	sda_low
	bra @2
@1:	sda_high
@2:	scl_high
	scl_low
.endmacro

.macro rec_bit
	sda_high		; Release SDA so that device can drive it
	scl_high
	lda pr
	.assert SDA = (1 << 0), error, "update the shift instructions if SDA is not bit #0"
	lsr             ; bit -> C
	scl_low
.endmacro

.macro I2C_Restore
    php
    mode8
    jsl i2c_restore
    plp
.endmacro

.macro I2C_Read_Byte addr
    .out "I2C_Read_Byte"
    SetRetVal                   ; Return Value 
    SetParam addr               ;      
    jsl i2c_read_byte           ; 
    FreeParams 2                ; Pop all the params off leaving return value in A  
.endmacro

.macro I2C_Write_Byte addr, value
    .out "I2C_Read_Byte"
    SetRetVal                   ; Return Value 
    SetParam addr               ;      
    SetParam value              ;      
    jsl i2c_write_byte          ; 
    FreeParams 3                ; Pop all the params off leaving return value in A  
.endmacro

