;----------------------------------------------------------------------
; VERA Text Mode Screen Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.p816

.include "screen.inc"
.include "io.inc"
.include "mac.inc"
.include "regs.inc"

.export screen_init, screen_clear_line, screen_get_color, screen_set_color
.export screen_get_char, screen_set_char, screen_set_char_color, screen_get_char_color
.export screen_set_position, screen_get_position, screen_clear_screen, screen_set_active

.import charpet

.segment "KVAR2" ; more KERNAL vars

char_addrs: 	
	set_charset_addr $0001f000
	set_charset_addr $0001f000
	set_charset_addr $0001f000
	set_charset_addr $0001f000
	set_charset_addr $0001f000 
screen_addrs:	
	set_screen_addr $0001b000
	set_screen_addr $00000000
	set_screen_addr $00004000
	set_screen_addr $00008000
	set_screen_addr $0000c000

; Screen
;
;.export data; [cpychr]
.export color;

pnt:	.res 2           ;$D1 pointer to row
color:	.res 1           ;    activ color nybble
;data:	.res 1           ;$D7
llen:	.res 1           ;$D9 x resolution

.segment "SCREEN"

;---------------------------------------------------------------
; Initialize screen
;
;---------------------------------------------------------------
.proc screen_init: near
        
    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order             
    SetLocalCount 0

    ; Declare parameters - reverse order        
    DeclareParam r_retVal, 0  

    ; Setup stack frame
    SetupStackFrame  

	mode8

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

	; Set the screen location to default
	lda #(screen_addr>>9)	
	sta VERA_L1_MAPBASE

	; Set the charset location to default
	lda #((charset_addr>>11)<<2)
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

	mode16

	; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

screen_load_defaults:
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
	DeclareLocal l_pnt, 0        
    SetLocalCount 1

    ; Declare parameters - reverse order       
	DeclareParam p_pline, 0
    DeclareParam r_retVal, 1  

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

	; Stuff the pointer into VERA
	lda l_pnt
	sta VERA_ADDR_L      		; set base address
	lda l_pnt+1
	clc
	adc #>screen_addr
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr		; auto-increment = 1
	sta VERA_ADDR_H

	; Store a space in the current color into the line
:	lda #' '
	sta VERA_DATA0     			; store space
	lda color       			; always clear to current foregnd color
	sta VERA_DATA0
	dey
	bne :-

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
    DeclareParam r_retVal, 0  

    ; Setup stack frame
    SetupStackFrame  
	
	; Clear all the lines on the screen
	ldx #$0000
    @1:          		
        Screen_Clear_Line ^X        		
        inx
        cpx #62
    bne @1    	

	; Exit the procedure
    FreeLocals
    ProcSuffix          

    rtl

.endproc

.A8
.I8

;---------------------------------------------------------------
; Calculate start of line
;
;   In:   .x   line
;   Out:  pnt  line location
;---------------------------------------------------------------
screen_set_position:
	stz pnt
	stx pnt+1
	rts

;---------------------------------------------------------------
; Retrieve start of line
;
;   In:   pmt  line
;   Out:  .x   line
;---------------------------------------------------------------
screen_get_position:
	ldx pnt+1
	rts	

;---------------------------------------------------------------
; Get single color
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;---------------------------------------------------------------
screen_get_color:
	phx ; preserve X (restored after branch)
	ldx #0
	tya
:
	cmp llen
	bcc :+
	sbc llen ; C=1
	inx
	bra :-
:
	sec
	rol
	bra ldapnt2

;---------------------------------------------------------------
; Get single character
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;---------------------------------------------------------------
screen_get_char:
	phx ; preserve X
	ldx #0
	tya
ldapnt0:
	cmp llen
	bcc ldapnt1
	sbc llen ; C=1
	inx
	bra ldapnt0
ldapnt1:
	asl
ldapnt2:
	sta VERA_ADDR_L
	lda pnt+1
:
	dex
	bmi ldapnt3
	inc
	bra :-
ldapnt3:
	plx ; restore X
	clc
	adc #<(>screen_addr)
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr
	sta VERA_ADDR_H
	lda VERA_DATA0
	rts


;---------------------------------------------------------------
; Set single color
;
;   In:   .a       color
;         .y       column
;         pnt      line location
;   Out:  -
;---------------------------------------------------------------
screen_set_color:
	pha
	phx ; preserve X (restored after branch)
	ldx #0
	tya
:
	cmp llen
	bcc :+
	sbc llen ; C=1
	inx
	bra :-
:
	sec
	rol
	bra stapnt2

;---------------------------------------------------------------
; Set single character
;
;   In:   .a       PETSCII/ISO
;         .y       column
;         pnt      line location
;   Out:  -
;---------------------------------------------------------------
screen_set_char:
	pha
	phx ; preserve X
	ldx #0
	tya
stapnt0:
	cmp llen
	bcc stapnt1
	sbc llen ; C=1
	inx
	bra stapnt0
stapnt1:
	asl
stapnt2:
	sta VERA_ADDR_L
	lda pnt+1
:
	dex
	bmi stapnt3
	inc
	bra :-
stapnt3:
	plx ; restore X
	clc
	adc #<(>screen_addr)
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr
	sta VERA_ADDR_H
	pla
	sta VERA_DATA0
	rts

;---------------------------------------------------------------
; Set single character and color
;
;   In:   .a       PETSCII/ISO
;         .x       color
;         .y       column
;         pnt      line location
;   Out:  -
;---------------------------------------------------------------
screen_set_char_color:
	jsr screen_set_char
	stx VERA_DATA0     ;set color
	rts

;---------------------------------------------------------------
; Get single character and color
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;         .x       color
;---------------------------------------------------------------
screen_get_char_color:
	jsr screen_get_char
	ldx VERA_DATA0     ;get color
	rts	

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
	FreeLocals
	RestoreStackFrame
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

.proc screen_set_active: near 
        
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

	; DO STUFF HERE

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