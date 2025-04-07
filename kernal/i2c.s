.p816

.include "io.inc"
.include "i2c.inc"
.include "mac.inc"
.include "regs.inc"

.export i2c_restore, i2c_read_byte, i2c_write_byte

.segment "I2C_JUMP" 

.segment "I2C_VAR" 

.segment "I2CMUTEX"
i2c_mutex: .res 1

.segment "I2C"

;---------------------------------------------------------------
; i2c_read_byte
;---------------------------------------------------------------
.I16
.A16
.proc i2c_read_byte: near
    mode16

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order         
    SetLocalCount 0

    ; Declare parameters - reverse order        
    DeclareParam p_addr, 0    
    DeclareParam r_retVal, 1

    ; Setup stack frame
    SetupStackFrame      

    ; Interrupts off
    sei

    ; Get address into C
    lda p_addr
    
    ; 8 bit mode
    mode8    

    ; Low Byte of C into Y, High Byte of C into X
    tay
    xba
    tax

    ; Check the mutex
    lda i2c_mutex
	bne @err

    ; Get the byte
	jsr i2c_read_first_byte
	bcs @err
    sta r_retVal 

    ; Stop read	
	jsr i2c_read_stop	
		
    bra @done

@err:
    lda #$ee
    sta r_retVal    

@done:

    ; Back to 16 bit
    mode16

    ; Interrupts back on
    cli 

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

;---------------------------------------------------------------
; i2c_write_byte
;---------------------------------------------------------------
.I16
.A16
.proc i2c_write_byte: near
    mode16

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order         
    SetLocalCount 0

    ; Declare parameters - reverse order        
    DeclareParam p_value, 0 
    DeclareParam p_addr, 1  
    DeclareParam r_retVal, 2

    ; Setup stack frame
    SetupStackFrame    

    ; Interrupts off
    sei

    ; Get address into C
    lda p_addr
    
    ; 8 bit mode
    mode8    

    ; Low Byte of C into Y, High Byte of C into X
    tay
    xba
    tax  

    ; Check the mutex
    lda i2c_mutex
	bne @error
    
    lda p_value
	jsr i2c_write_first_byte
	bcs @error
	jsr i2c_write_stop

    mode16
    lda #$0000
    sta r_retVal

	bra @done

@error:

    mode16
	lda #$ffff
    sta r_retVal
    
@done: 
    
    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

;---------------------------------------------------------------
; i2c_write_stop
;
; Function:	Stops I2C transmission that has been initialized
;			with i2c_write_first_byte
;
; Pass:		Nothing
;
; Return:	Nothing
;---------------------------------------------------------------
i2c_write_stop:
	lda i2c_mutex
	beq :+
	rts
:	jmp i2c_stop

;---------------------------------------------------------------
; i2c_write_first_byte
; 
; Function: Writes one byte over I2C without stopping the
;           transmission. Subsequent bytes may be written by
;           i2c_write_next_byte. When done, call function
;           i2c_write_stop to close the I2C transmission.
;
; Pass:      a    value
;            x    7-bit device address
;            y    offset
;
; Return:    c    1 on error (NAK)
;---------------------------------------------------------------
i2c_write_first_byte:
	pha                ; value
	lda i2c_mutex
	bne @error

	jsr i2c_init
	jsr i2c_start
	txa                ; device
	asl
	phy
	jsr i2c_write
	ply
	bcs @error
	tya                ; offset
	phy
	jsr i2c_write
	ply
	pla                ; value
	jsr i2c_write
	clc
	rts

@error:
	pla                ; value
	sec
	rts

;---------------------------------------------------------------
; i2c_init
;
; Function: Configure VIA for being an I2C controller.
;
; Pass:      None
;
; Return:    None
;
; I2C Exit:  SDA: Z
;            SCL: Z
;---------------------------------------------------------------
.I8
.A8
i2c_init:
	lda #SDA | SCL
	trb pr
	sda_high
	scl_high
	rts

;---------------------------------------------------------------
; i2c_start
;
; Function: Signal an I2C start condition. The start condition
;           drives the SDA signal low prior to driving SCL low.
;           Start/Stop is the only time when it is legal to for
;           SDA to change while SCL is high. Both SDA and SCL
;           will be in the LOW state at the end of this function.
;
; Pass:      None
;
; Return:    None
;
; I2C Exit:  SDA: 0
;            SCL: 0
;---------------------------------------------------------------
.I8
.A8
i2c_start:
	sda_low
	i2c_brief_delay
	scl_low
	rts

;---------------------------------------------------------------
; i2c_read_stop
;
; Function:	Stops I2C transmission that has been initialized
;			with i2c_read_first_byte
;
; Pass:		Nothing
;
; Return:	Nothing
;---------------------------------------------------------------
.I8
.A8
i2c_read_stop:
	lda i2c_mutex
	beq :+
	rts
:	i2c_nack
	jmp i2c_stop

;---------------------------------------------------------------
; i2c_write
;
; Function: Write a single byte over I2C
;
; Pass:      a    byte to write
;
; Return:    c    0 if ACK, 1 if NAK
;
; I2C Exit:  SDA: Z
;            SCL: 0
;---------------------------------------------------------------
.I8
.A8
i2c_write:
	ldx #8
i2c_write_loop:
	rol
	tay
	send_bit
	tya
	dex
	bne i2c_write_loop
	rec_bit     ; C = 0: success
	rts

;---------------------------------------------------------------
; i2c_read_first_byte
;
; Function: Reads one byte over I2C without stopping the
;           transmission. Subsequent bytes may be read by
;           i2c_read_next_byte. When done, call function
;           i2c_read_stop to close the I2C transmission.
;
; Pass:      x    7-bit device address
;            y    offset
;
; Return:    a    value
;            c    1 on error (NAK)
;---------------------------------------------------------------
.I8
.A8
i2c_read_first_byte:
	lda i2c_mutex
	beq @1
	sec
	rts

@1:	jsr i2c_init
	jsr i2c_start                        ; SDA -> LOW, (wait 5 us), SCL -> LOW, (no wait)
	txa                ; device
	asl
	pha                ; device * 2
	phy
	jsr i2c_write
	ply
	bcs @error
	plx                ; device * 2
	tya                ; offset
	phx                ; device * 2
	jsr i2c_write
	jsr i2c_stop
	jsr i2c_start
	pla                ; device * 2
	inc
	jsr i2c_write
	bra i2c_read_next_byte_after_ack
	
@error:
	pla
	jsr i2c_stop
	lda #$ee
	sec
	rts

;---------------------------------------------------------------
; i2c_stop
;---------------------------------------------------------------
.I8
.A8
i2c_stop:
	sda_low
	i2c_brief_delay
	scl_high
	i2c_brief_delay
	sda_high
	i2c_brief_delay
	rts

;---------------------------------------------------------------
; i2c_restore
;---------------------------------------------------------------
.I8
.A8
i2c_restore:
	stz i2c_mutex
	jsr i2c_stop    
    rtl


;---------------------------------------------------------------
; i2c_read
;
; Function: Read a single byte from a device over I2C
;
; Pass:      None
;
; Return:    a    value from device
;
; I2C Exit:  SDA: Z
;            SCL: 0
;---------------------------------------------------------------
.I8
.A8
i2c_read:
	ldx #8
i2c_read_loop:	
	tay
	rec_bit
	tya
	rol
	dex
	bne i2c_read_loop
	rts

.I8
.A8
i2c_read_next_byte_after_ack:
	jsr i2c_read
	cmp #0
	clc
	rts