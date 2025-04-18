;----------------------------------------------------------------------
; VERA Text Mode Screen Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.p816

.include "screen.inc"
.include "io.inc"
.include "mac.inc"
.include "regs.inc"

.export screen_init, screen_clear_line, screen_put_charcolor, screen_clear_screen, screen_set_active, screen_scroll, screen_scroll_window

.import charpet

.segment "SCREEN_JUMP" 

.segment "SCREEN_VAR" 

char_addrs: .res 5	
screen_addrs: .res 5
screen_addrs_h: .res 5
screen_addrs_m: .res 5

; Screen
;
;.export data; [cpychr]
.export color;

pnt:	.res 2           ;$D1 pointer to row
color:	.res 1           ;    activ color nybble
;data:	.res 1           ;$D7
llen:	.res 1           ;$D9 x resolution

.segment "SCREEN"

default_char_addrs: 	
	set_charset_addr $0001f000
	set_charset_addr $0001f000
	set_charset_addr $0001f000
	set_charset_addr $0001f000
	set_charset_addr $0001f000 
default_screen_addrs:	
	set_screen_addr $0001b000
	set_screen_addr $00000000
	set_screen_addr $00004000
	set_screen_addr $00008000
	set_screen_addr $0000c000
default_screen_addrs_h:
	.byte ^$0001b000
	.byte ^$00000000
	.byte ^$00004000
	.byte ^$00008000
	.byte ^$0000c000
default_screen_addrs_m:
	.byte >$0001b000
	.byte >$00000000
	.byte >$00004000
	.byte >$00008000
	.byte >$0000c000

;---------------------------------------------------------------
; Initialize screen
;
;---------------------------------------------------------------
.proc screen_init: near
        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order                 
	DeclareLocal l_databank, 0
    SetLocalCount 1

    ; Declare parameters - reverse order        
    DeclareParam r_retVal, 0  

    ; Setup stack frame
    SetupStackFrame  

	mode8

	BEGIN_CRITICAL_SECTION

	; Remember Data bank
	phb
	pla
	sta l_databank

	; Set data bank to $00
	lda #$00
	pha
	plb

	; Set active screen to zero
	lda #$00	

	; Prime the screen and char table	
	tax
@1:	
	lda f:default_char_addrs, x
	sta f:char_addrs, x
	lda f:default_screen_addrs, x	
	sta f:screen_addrs, x
	lda f:default_screen_addrs_h, x	
	sta f:screen_addrs_h, x
	lda f:default_screen_addrs_m, x	
	sta f:screen_addrs_m, x
	inx
	cpx #$05
	bne @1

	; Set ADDR1 active
	stz VERA_CTRL   

	; Default line length
	lda #$80
	sta llen	

	; Load the character set	
	ldx #<charpet
	ldy #>charpet
	jsr screen_set_charset

	; Load the palette
	jsr upload_default_palette

	; Layer 1 configuration
	lda #((1<<6)|(2<<4)|(0<<0))
	sta VERA_L1_CONFIG

	; Set the screen location to default - Always init to Screen 0, change later if you want
	ldx #$00
	lda screen_addrs, x	
	sta VERA_L1_MAPBASE

	; Set the charset location to default - Always init to Screen 0, change later if you want
	ldx #$00
	lda char_addrs, x	
	sta VERA_L1_TILEBASE

	; Set the default scroll settings
	stz VERA_L1_HSCROLL_L
	stz VERA_L1_HSCROLL_H
	stz VERA_L1_VSCROLL_L
	stz VERA_L1_VSCROLL_H

	; Display composer configuration
	lda #2
	sta VERA_CTRL
	stz VERA_DC_HSTART
	lda #(640>>2)
	sta VERA_DC_HSTOP
	stz VERA_DC_VSTART
	lda #(480>>2)
	sta VERA_DC_VSTOP

	stz VERA_CTRL
	lda #$21
	sta VERA_DC_VIDEO
	lda #128
	sta VERA_DC_HSCALE
	sta VERA_DC_VSCALE
	stz VERA_DC_BORDER

	; Clear sprite attributes ($1FC00-$1FFFF)
	stz VERA_ADDR_L
	lda #$FC
	sta VERA_ADDR_M
	lda #$11
	sta VERA_ADDR_H

	ldx #4
	ldy #0
:	stz VERA_DATA0     ;clear 128*8 bytes
	iny
	bne :-
	dex
	bne :-	

	; Load the defaults from the table
	jsr screen_load_defaults

	; Set Databank back to original
	lda l_databank
	pha
	plb

	END_CRITICAL_SECTION

	mode16

	; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

screen_load_defaults:
	.A8
    .I8
	stz VERA_CTRL
	lda @defaults+2
	sta VERA_DC_VIDEO
	lda @defaults+3
	sta VERA_DC_HSCALE
	lda @defaults+4
	sta VERA_DC_VSCALE
	lda @defaults+5
	sta VERA_DC_BORDER
	lda #2
	sta VERA_CTRL
	lda @defaults+6
	sta VERA_DC_HSTART
	lda @defaults+7
	sta VERA_DC_HSTOP
	lda @defaults+8
	sta VERA_DC_VSTART
	lda @defaults+9
	sta VERA_DC_VSTOP
	stz VERA_CTRL
	lda @defaults+10
	sta color
	rts

@defaults:
	; active profile
	.byte $00
	; profile 0
	.byte $00,$21,$80,$80,$00,$00,$A0,$00,$F0,$61,$00,$00,$00	

;---------------------------------------------------------------
; Clear line
;---------------------------------------------------------------
.proc screen_clear_line: near
 	        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order     
	DeclareLocal l_pnt, 1        
	DeclareLocal l_databank, 0
    SetLocalCount 2

    ; Declare parameters - reverse order       	
	DeclareParam p_pline, 0
	DeclareParam p_screen, 1
    DeclareParam r_retVal, 2

    ; Setup stack frame
    SetupStackFrame  
	
	; Grab X from the param
	ldx p_pline

	mode8

	; Get the screen address
	stz l_pnt
	stx l_pnt+1

	; Set the line length
	ldy llen

	; Get the screen
	lda p_screen
	tax

	BEGIN_CRITICAL_SECTION

	; Remember Data bank
	phb
	pla
	sta l_databank

	; Set data bank to $00
	lda #$00
	pha
	plb

	; Stuff the pointer into VERA
	lda #$00
	sta VERA_CTRL
	lda l_pnt
	sta VERA_ADDR_L      		; set base address
	lda l_pnt+1
	clc	
	adc f:screen_addrs_h, x
	sta VERA_ADDR_M	
	lda f:screen_addrs_h, x
	ora #$10
	sta VERA_ADDR_H

	; Store a space in the current color into the line
:	lda #' '
	sta VERA_DATA0     			; store space
	lda color       			; always clear to current foregnd color
	sta VERA_DATA0
	dey
	bne :-

	; Set Databank back to original
	lda l_databank
	pha
	plb

	END_CRITICAL_SECTION

	mode16

	; Exit the procedure
    FreeLocals
    ProcSuffix          

    rtl

.endproc

;---------------------------------------------------------------
; Clear Screen
;---------------------------------------------------------------
.proc screen_clear_screen: near 	
        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order     	
    SetLocalCount 0

    ; Declare parameters - reverse order   
	DeclareParam p_screen, 0    	
    DeclareParam r_retVal, 1  

    ; Setup stack frame
    SetupStackFrame  
	
	; Clear all the lines on the screen
	ldx #$0000
    @1:          		
        Screen_Clear_Line *p_screen, ^X        		
        inx
        cpx #62
    bne @1    	

	; Exit the procedure
    FreeLocals
    ProcSuffix          

    rtl

.endproc

;---------------------------------------------------------------
; Put charColor
;---------------------------------------------------------------
.proc screen_put_charcolor: near 		

	;BEGIN_CRITICAL_SECTION    	 
		        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order     	
    DeclareLocal l_pnt, 1        
	DeclareLocal l_databank, 0
    SetLocalCount 2

    ; Declare parameters - reverse order   
	DeclareParam p_charcolor, 0    	
	DeclareParam p_ypos, 1    	
	DeclareParam p_xpos, 2    	
	DeclareParam p_screen, 3
    DeclareParam r_retVal, 4  	

    ; Setup stack frame	
    SetupStackFrame  			
		
	; Multiply x_pos * 2	
	clc
	rol p_xpos

	; Pointer to current screen
	ldx p_screen
	
	; Set pointer to beginning of line
	lda p_xpos
	ldy p_ypos	
	mode8	
	sta l_pnt
	sty l_pnt+1	

	BEGIN_CRITICAL_SECTION

	; Remember Data bank
	phb
	pla
	sta l_databank

	; Set data bank to $00
	lda #$00
	pha
	plb
		
	; Stuff the pointer into VERA	
	stz VERA_CTRL
	lda l_pnt	
	sta VERA_ADDR_L      		; set base address		
	lda l_pnt+1	
	clc
	adc f:screen_addrs_m, x	
	sta VERA_ADDR_M	
	lda f:screen_addrs_h, x
	ora #$10
	sta VERA_ADDR_H	
	
	; Store character and color
	mode16
	lda p_charcolor
	mode8
	sta VERA_DATA0	
	xba	
	sta VERA_DATA0

	; Set Databank back to original
	lda l_databank
	pha
	plb

	END_CRITICAL_SECTION

	mode16
		
	; Exit the procedure	
    FreeLocals
    ProcSuffix  

	;END_CRITICAL_SECTION

    rtl

.endproc

.A8
.I8

;---------------------------------------------------------------
; Set charset
;
; Function: Activate a 256 character 8x8 charset.
;
;   In:   
;         .x/.y  pointer to charset
;---------------------------------------------------------------
screen_set_charset:
	jsr inicpy	

cpycustom:	
	
	; Set Direct Page inside the stack, create a local
	mode16	
	SetLocalCount 1
	DeclareLocal pCharSet, 0
	SetupStackFrame	
	mode8

	stx pCharSet
	sty pCharSet+1
	ldx #8
	ldy #0	
@l1:	
	lda (pCharSet) ,y	
	;eor data
	sta VERA_DATA0
	iny
	bne @l1	
	inc pCharSet+1	
	dex
	bne @l1

	; Cleanup local, DP back to $0000
	mode16
	lda #$0000
	tcd
	FreeLocals
	mode8

	rts

inicpy:
	phx
	ldx #<charset_addr
	stx VERA_ADDR_L
	ldx #>charset_addr
	stx VERA_ADDR_M
	ldx #$10 | ^charset_addr
	stx VERA_ADDR_H
	plx
	;stz data	
	rts	

upload_default_palette:
	stz VERA_CTRL
	lda #<VERA_PALETTE_BASE
	sta VERA_ADDR_L
	lda #>VERA_PALETTE_BASE
	sta VERA_ADDR_M
	lda #(^VERA_PALETTE_BASE) | $10
	sta VERA_ADDR_H

	ldx #0
@1:
	lda default_palette,x
	sta VERA_DATA0
	inx
	bne @1
@2:
	lda default_palette+256,x
	sta VERA_DATA0
	inx
	bne @2

	rts

;---------------------------------------------------------------
; Set Active Screen
;
;---------------------------------------------------------------
.proc screen_set_active: near 
        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order             
    DeclareLocal l_databank, 0
    SetLocalCount 1

    ; Declare parameters - reverse order        
    DeclareParam p_screen, 0
	DeclareParam r_retVal, 1  

    ; Setup stack frame
    SetupStackFrame  

	; Grab the screen from the param
	lda p_screen	
	tax

	mode8

	BEGIN_CRITICAL_SECTION

	; Remember Data bank
	phb
	pla
	sta l_databank

	; Set data bank to $00
	lda #$00
	pha
	plb

	; Set the screen location to default
	lda f:screen_addrs, x	
	sta VERA_L1_MAPBASE

	; Set the charset location to default
	lda f:char_addrs, x	
	sta VERA_L1_TILEBASE

	; Set Databank back to original
	lda l_databank
	pha
	plb

	END_CRITICAL_SECTION

	mode16

	; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

;---------------------------------------------------------------
; Scroll the screen
;
;---------------------------------------------------------------
.proc screen_scroll: near 
        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order             
	DeclareLocal l_srcpnt, 2
	DeclareLocal l_dstpnt, 1
    DeclareLocal l_databank, 0	
    SetLocalCount 3

    ; Declare parameters - reverse order        
    DeclareParam p_screen, 0
	DeclareParam r_retVal, 1  

    ; Setup stack frame
    SetupStackFrame  

	; Grab the screen from the param
	lda p_screen	
	tax

	mode8

	BEGIN_CRITICAL_SECTION

	; Remember Data bank
	phb
	pla
	sta l_databank

	; Set data bank to $00
	lda #$00
	pha
	plb

	; Scroll the screen

	; Pointer to current screen
	ldx p_screen

	; Set source address to beginning of line 2
	stz l_srcpnt
	lda #$01
	sta l_srcpnt+1

	stz VERA_CTRL
	lda l_srcpnt	
	sta VERA_ADDR_L      		; set base address		
	lda l_srcpnt+1	
	clc
	adc f:screen_addrs_m, x	
	sta VERA_ADDR_M	
	lda f:screen_addrs_h, x
	ora #$10
	sta VERA_ADDR_H	

	; Set destination address to beginning of line 1
	stz l_dstpnt
	stz l_dstpnt + 1

	lda #$01
	sta VERA_CTRL
	lda l_dstpnt	
	sta VERA_ADDR_L      		; set base address		
	lda l_dstpnt+1	
	clc
	adc f:screen_addrs_m, x	
	sta VERA_ADDR_M	
	lda f:screen_addrs_h, x
	ora #$10
	sta VERA_ADDR_H	


	; Copy Source to Destination	
	ldx #$3b
	ldy #$00
@1:		
		lda VERA_DATA0
		sta VERA_DATA1
		iny
	bne @1
		dex
	bne @1		

	; Set Databank back to original
	lda l_databank
	pha
	plb

	END_CRITICAL_SECTION

	mode16

	; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

;---------------------------------------------------------------
; Scroll a window
;
;---------------------------------------------------------------
.proc screen_scroll_window: near 
        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order             
	DeclareLocal l_srcpnt, 2
	DeclareLocal l_dstpnt, 1
    DeclareLocal l_databank, 0	
    SetLocalCount 3

    ; Declare parameters - reverse order        
	DeclareParam p_height, 0
	DeclareParam p_width, 1	
	DeclareParam p_org_y, 2
	DeclareParam p_org_x, 3
    DeclareParam p_screen, 4
	DeclareParam r_retVal, 5

    ; Setup stack frame
    SetupStackFrame  

	; Grab the screen from the param
	lda p_screen	
	tax

	mode8

	BEGIN_CRITICAL_SECTION

	; Remember Data bank
	phb
	pla
	sta l_databank

	; Set data bank to $00
	lda #$00
	pha
	plb

	; Scroll the screen
	
	; Set source and dest addresses	
	lda p_org_x
	rol
	dec
	sta l_srcpnt
	sta l_dstpnt
	lda p_org_y
	sta l_dstpnt + 1
	inc 
	sta l_srcpnt+1

	; Set number of lines
	ldy p_height
@2:	
		; Pointer to current screen
		ldx p_screen

		; Set source in VERA
		stz VERA_CTRL
		lda l_srcpnt	
		sta VERA_ADDR_L      		; set base address		
		lda l_srcpnt+1	
		clc
		adc f:screen_addrs_m, x	
		sta VERA_ADDR_M	
		lda f:screen_addrs_h, x
		ora #$10
		sta VERA_ADDR_H	

		; Set dest in VERA
		lda #$01
		sta VERA_CTRL
		lda l_dstpnt	
		sta VERA_ADDR_L      		; set base address		
		lda l_dstpnt+1	
		clc
		adc f:screen_addrs_m, x	
		sta VERA_ADDR_M	
		lda f:screen_addrs_h, x
		ora #$10
		sta VERA_ADDR_H	

		; Copy Source to Destination	
		ldx p_width		
	@1:		
			lda VERA_DATA0
			sta VERA_DATA1
			lda VERA_DATA0
			sta VERA_DATA1			
			dex
		bne @1		

		; Next line
		inc l_dstpnt + 1
		lda l_srcpnt+1
		inc
		sta l_srcpnt+1

		; Decrement line counter
		dey
	bne @2

	; Set Databank back to original
	lda l_databank
	pha
	plb

	END_CRITICAL_SECTION

	mode16

	; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

.segment "PALETTE"

default_palette:
	.word $0000,$0fff,$0800,$0afe,$0c4c,$00c5,$000a,$0ee7
	.word $0d85,$0640,$0f77,$0333,$0777,$0af6,$008f,$0bbb
	.word $0000,$0111,$0222,$0333,$0444,$0555,$0666,$0777
	.word $0888,$0999,$0aaa,$0bbb,$0ccc,$0ddd,$0eee,$0fff
	.word $0211,$0433,$0644,$0866,$0a88,$0c99,$0fbb,$0211
	.word $0422,$0633,$0844,$0a55,$0c66,$0f77,$0200,$0411
	.word $0611,$0822,$0a22,$0c33,$0f33,$0200,$0400,$0600
	.word $0800,$0a00,$0c00,$0f00,$0221,$0443,$0664,$0886
	.word $0aa8,$0cc9,$0feb,$0211,$0432,$0653,$0874,$0a95
	.word $0cb6,$0fd7,$0210,$0431,$0651,$0862,$0a82,$0ca3
	.word $0fc3,$0210,$0430,$0640,$0860,$0a80,$0c90,$0fb0
	.word $0121,$0343,$0564,$0786,$09a8,$0bc9,$0dfb,$0121
	.word $0342,$0463,$0684,$08a5,$09c6,$0bf7,$0120,$0241
	.word $0461,$0582,$06a2,$08c3,$09f3,$0120,$0240,$0360
	.word $0480,$05a0,$06c0,$07f0,$0121,$0343,$0465,$0686
	.word $08a8,$09ca,$0bfc,$0121,$0242,$0364,$0485,$05a6
	.word $06c8,$07f9,$0020,$0141,$0162,$0283,$02a4,$03c5
	.word $03f6,$0020,$0041,$0061,$0082,$00a2,$00c3,$00f3
	.word $0122,$0344,$0466,$0688,$08aa,$09cc,$0bff,$0122
	.word $0244,$0366,$0488,$05aa,$06cc,$07ff,$0022,$0144
	.word $0166,$0288,$02aa,$03cc,$03ff,$0022,$0044,$0066
	.word $0088,$00aa,$00cc,$00ff,$0112,$0334,$0456,$0668
	.word $088a,$09ac,$0bcf,$0112,$0224,$0346,$0458,$056a
	.word $068c,$079f,$0002,$0114,$0126,$0238,$024a,$035c
	.word $036f,$0002,$0014,$0016,$0028,$002a,$003c,$003f
	.word $0112,$0334,$0546,$0768,$098a,$0b9c,$0dbf,$0112
	.word $0324,$0436,$0648,$085a,$096c,$0b7f,$0102,$0214
	.word $0416,$0528,$062a,$083c,$093f,$0102,$0204,$0306
	.word $0408,$050a,$060c,$070f,$0212,$0434,$0646,$0868
	.word $0a8a,$0c9c,$0fbe,$0211,$0423,$0635,$0847,$0a59
	.word $0c6b,$0f7d,$0201,$0413,$0615,$0826,$0a28,$0c3a
	.word $0f3c,$0201,$0403,$0604,$0806,$0a08,$0c09,$0f0b