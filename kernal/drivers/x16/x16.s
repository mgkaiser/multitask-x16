;----------------------------------------------------------------------
; Commander X16 Machine Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "io.inc"

; for initializing the audio subsystems
.include "audio.inc"

.export ioinit
.export iokeys
.export vera_wait_ready

.segment "MACHINE"

;---------------------------------------------------------------
; IOINIT - Initialize I/O Devices
;
; Function:  Init all devices.
;            -- This is KERNAL API --
;---------------------------------------------------------------
ioinit:
	jsr vera_wait_ready
	jsr clear_interrupt_sources
	;jsr serial_init
	;jsr entropy_init
	;jsr clklo       ;release the clock line	

;---------------------------------------------------------------
; Set up VBLANK IRQ
;
;---------------------------------------------------------------
iokeys:
	lda #1
	sta VERA_IEN    ;VERA VBLANK IRQ for 60 Hz
	rts

;---------------------------------------------------------------
; Wait for VERA to be ready
;
; VERA's FPGA needs some time to configure itself. This function
; will see if the configuration is done by writing a VERA
; register and checking if the value is correctly written.
;---------------------------------------------------------------
vera_wait_ready:
	lda #42
	sta VERA_ADDR_L
	lda VERA_ADDR_L
	cmp #42
	bne vera_wait_ready
	rts

;---------------------------------------------------------------
; Reset device state such that there are no interrupt sources
; (assuming stock hardware)
;
; Includes VERA interrupt sources, VIA 1, VIA 2, and YM2151.
;---------------------------------------------------------------

clear_interrupt_sources:
	php
	sei
	; wait for YM2151 busy flag to clear
	ldx #0
@1:
	bit YM_DATA
	bpl @2
	dex
	bne @1
	; give up, YM2151 likely not present, but try to
	; write to it anyway
@2:
	lda #$14
	sta YM_REG
	; handle all of the other non-YM2151 resets to fill
	; the 18 clock cycles needed in between the YM_REG
	; and YM_DATA writes
	stz VERA_IEN
	lda #$7F
	sta d1ier
	sta d2ier
	nop
	lda #%00110000
	sta YM_DATA
	plp
	rts

