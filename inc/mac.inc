;----------------------------------------------------------------------
; Commander X16 KERNAL 16 Bit Macros
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD
; based on GEOS 64, edited by Maciej 'YTM/Alliance' Witkowiak

.macro LoadB dest, value
	.if .const(value) .and value=0
		stz dest
	.else
		lda #value
		sta dest
	.endif
.endmacro

.macro LoadW dest, value
	.if .const(value) .and .lobyte(value)=0
		stz dest
	.else
		lda #<(value)
		sta dest
	.endif
	.if .const(value) .and .hibyte(value)=0
		stz dest+1
	.else
		.if (.not .const(value)) .or (>(value))<>(<(value))
			lda #>(value)
		.endif
		sta dest+1
	.endif
.endmacro

.macro MoveB source, dest
	lda source
	sta dest
.endmacro

.macro MoveW source, dest
	MoveB source+0, dest+0
	MoveB source+1, dest+1
.endmacro

.macro add source
	clc
	adc source
.endmacro

.macro AddB source, dest
	lda source
	add dest
	sta dest
.endmacro

.macro AddW source, dest
	AddB source+0, dest+0
	lda source+1
	adc dest+1
	sta dest+1
.endmacro

.macro AddW3 source1, source2, dest
	lda source1
	clc
	adc source2
	sta dest
	lda source1+1
	adc source2+1
	sta dest+1
.endmacro

.macro AddVB value, dest
	lda dest
	clc
	adc #value
	sta dest
.endmacro

.macro AddVW value, dest
	.local j
	lda dest
	clc
	adc #<(value)
	sta dest
	.if (>(value))=0
		bcc j
		inc dest+1
		j:
	.else
		lda dest+1
		adc #>(value)
		sta dest+1
	.endif
.endmacro

.macro sub source
	sec
	sbc source
.endmacro

.macro SubB source, dest
	lda dest
	sub source
	sta dest
.endmacro

.macro SubW source, dest
	SubB source+0, dest+0
	lda dest+1
	sbc source+1
	sta dest+1
.endmacro

.macro SubVW value, dest
	.local j
	lda dest+0
	sec
	sbc #<(value)
	sta dest+0

	.if (>(value))=0
		bcs j
		dec dest+1
		j:
	.else
		lda dest+1
		sbc #>(value)
		sta dest+1
	.endif
.endmacro

.macro CmpB source, dest
	lda source
	cmp dest
.endmacro

.macro CmpBI source, immed
	lda source
	cmp #immed
.endmacro

.macro CmpW source, dest
	.local @j
	CmpB source+1, dest+1
	bne @j
	CmpB source+0, dest+0
@j:
.endmacro

.macro CmpWI source, immed
	.local @j
	CmpBI source+1, >(immed)
	bne @j
	CmpBI source+0, <(immed)
@j:
.endmacro

.macro PushB source
	lda source
	pha
.endmacro

.macro PushW source
	PushB source+0
	PushB source+1
.endmacro

.macro PopB dest
	pla
	sta dest
.endmacro

.macro PopW dest
	PopB dest+1
	PopB dest+0
.endmacro

.macro smb bitN, dest
	pha
	smbf bitN, dest
	pla
.endmacro

.macro smbf bitN, dest
	lda #1 << bitN
	tsb dest
.endmacro

.macro rmb bitN, dest
	pha
	rmbf bitN, dest
	pla
.endmacro

.macro rmbf bitN, dest
	lda #1 << bitN
	trb dest
.endmacro

.macro bbs bitN, source, addr
	.local @j
	php
	pha
	lda source
	and #1 << bitN
	beq @j
	pla
	plp
	bra addr
@j:
	pla
	plp
.endmacro

.macro bbsf bitN, source, addr
	.if (bitN = 7)
		bit source
		bmi addr
	.else
		.if (bitN = 6)
			bit source
			bvs addr
		.else
			lda source
			and #1 << bitN
			bne addr
		.endif
	.endif
.endmacro

.macro bbr bitN, source, addr
	.local @j
	php
	pha
	lda source
	and #1 << bitN
	bne @j
	pla
	plp
	bra addr
@j:
	pla
	plp
.endmacro

.macro bbrf bitN, source, addr
	.if (bitN = 7)
		bit source
		bpl addr
	.else
		.if (bitN = 6)
			bit source
			bvc addr
		.else
			lda source
			and #1 << bitN
			beq addr
		.endif
	.endif
.endmacro

.macro addv value
	clc
	adc #value
.endmacro

.macro subv value
	sec
	sbc #value
.endmacro

.macro bnex addr
	txa
	bne addr
.endmacro

.macro beqx addr
	txa
	beq addr
.endmacro

.macro IncW addr
	.local @j
	inc addr
	bne @j
	inc addr+1
	@j:
.endmacro

.macro DecW_ addr
	.local @j
	lda addr
	bne @j
	dec addr+1
@j:	dec addr
.endmacro

.macro DecW addr
	DecW_ addr
	lda addr
	ora addr+1
.endmacro

.macro breakpoint
	;.byte $ea
	.byte $db
.endmacro

.macro ProcPrefix
	pha  
    phx
    phy
    phd	
.endmacro

.macro ProcSuffix
	pld
    ply
    plx
    pla
.endmacro

.macro SetupStackFrame		
	tsc
    tcd
.endmacro

.macro RestoreStackFrame
	pla
	tcd
.endmacro

.macro DeclareLocal lname, position
	lname = (position * 2) + 1	
	pha
.endmacro

.macro DeclareLocalWithValue lname, value, position
	lname = (position * 2) + 1	
	lda value
	pha
.endmacro

.macro DeclareLocalPointerWithValue lname, value, position
	lname = (position * 2) + 1	
	per value	
.endmacro

.macro ProcNear
	farOffset=0
.endmacro

.macro ProcFar
	farOffset=1
.endmacro

.macro DeclareParam lname, position
	lname = (position * 2) + 11 + farOffset + (lcount * 2)
.endmacro

.macro FreeLocals
	; Make this smart and move SP rather than a mess of PLA when lcount > x
	; Always PLA the last one so RetVal ends up in A
	.repeat lcount
		pla
	.endrepeat
.endmacro

.macro FreeParams count
	; Make this smart and move SP rather than a mess of PLA when count > x
	; Always PLA the last one so RetVal ends up in A
	.repeat count
		pla
	.endrepeat
.endmacro

.macro SetLocalCount count
	lcount = count
.endmacro

; # TODO: Document these
; Push Params, detect type
; PER = label				param is an offset, but pushes the resolved value onto the stack
; PEA = Absloute Value		param is the actual 16-bit value to push on the stack
; PEI = Pointer 			param is a DP address to be used as a pointer.  The value it points to is pushed on the stack
.macro SetParam arg	
	.if (.match (.left (1, {arg}), #))
		.out "-- PEA --"
		.byte $f4
		.byte <(.right (.tcount ({arg})-1, {arg}))		
		.byte >(.right (.tcount ({arg})-1, {arg}))		
	.else
		.if (.match (.left (1, {arg}), *))
			.out "-- PEI --"
			pei (.right (.tcount ({arg})-1, {arg}))
		.else			
			.if (.match (.left (2, {arg}), ^A))
				.out "-- A --"
				pha
			.else
				.if (.match (.left (2, {arg}), ^D))
					.out "-- D --"					
					phd
				.else
					.if (.match (.left (2, {arg}), ^Y))
						.out "-- Y --"					
						phy
					.else
						.if (.match (.left (2, {arg}), ^X))
							.out "-- X --"					
							phx
						.else
							.if (.match (.left (2, {arg}), ^^))
								.out "-- ^^ --"
								.byte $a5	
								.byte <(.right (.tcount ({arg})-2, {arg}))
								pha
							.else																																								
								.out "-- PER --"
								per arg														
							.endif												
						.endif
					.endif
				.endif
			.endif
		.endif
	.endif
.endmacro

.macro SetParamL arg
	.out "-- f:PEA --"
	.byte $f4
	.byte ^(.right (.tcount ({arg})-1, {arg}))		
	.byte $00
	.byte $f4
	.byte <(.right (.tcount ({arg})-1, {arg}))		
	.byte >(.right (.tcount ({arg})-1, {arg}))	
.endmacro	

.macro SetRetVal
	.out "-- SetRetVal --"
	pha
.endmacro

.macro rjsr arg		
	per @+-1
	brl arg
	@:
.endmacro

.macro rjsl arg		
	phk
	per @+-1
	brl arg
	@:
.endmacro

.macro il_jsl arg		
	phk
	per @+-1
	jml [arg]
	@:
.endmacro

.macro il_jsr arg	
	.local continue	
	per @+-1
	jmp [arg]
	@:
.endmacro

.macro mode16
	.A16
    .I16
    rep #$30 
.endmacro

.macro mode8
	.A8
    .I8
    sep #$30 
.endmacro

.macro modeEmulation
	sec             
    xce    
.endmacro

.macro modeNative
	clc
    xce    
.endmacro

.macro BEGIN_DP_ZERO		
	tdc
	pha
	lda #$0000
	tcd	
.endmacro

.macro END_DP_ZERO
	pla
	tcd
.endmacro

.macro BEGIN_CRITICAL_SECTION
	sei
.endmacro

.macro END_CRITICAL_SECTION
	cli
.endmacro

.macro set_int_vec value, addr
	mode8
	lda #$5c
    sta addr+0
	lda #<value
	sta addr+1
	lda #>value
	sta addr+2
    lda #^value
    sta addr+3
	mode16
.endmacro

.macro set_screen_addr addr
.byte (addr>>9)
.endmacro

.macro set_charset_addr addr
.byte ((addr>>11)<<2)
.endmacro

.macro bge value
	bcs value
.endmacro

.macro blt value
	bcc value
.endmacro
