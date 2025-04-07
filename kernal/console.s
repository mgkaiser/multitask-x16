.p816

.include "screen.inc"
.include "console.inc"
.include "io.inc"
.include "mac.inc"
.include "regs.inc"

.import screen_put_charcolor, screen_scroll, screen_scroll_window

.export console_init, console_charout

.segment "CONSOLE_JUMP" 

.segment "CONSOLE_VAR" 

cur_x:      .res 2
cur_y:      .res 2
cur_color:  .res 1
cur_screen: .res 2

.segment "CONSOLE"
.proc console_init: near
    mode16

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order         
    SetLocalCount 0

    ; Declare parameters - reverse order        
    DeclareParam org_y, 0
    DeclareParam org_x, 1
    DeclareParam con_height, 2
    DeclareParam con_width, 3  
    DeclareParam cur_screen, 4
    DeclareParam cur_color, 5
    DeclareParam cur_y, 6
    DeclareParam cur_x, 7
    DeclareParam pConsole, 8       ; Skip 2 because long param    
    DeclareParam r_retVal, 10    

    ; Setup stack frame
    SetupStackFrame       

    ; Setup the structure
    ldy #struct_console::cur_x
    lda cur_x
    sta [pConsole], y

    ldy #struct_console::cur_y
    lda cur_y
    sta [pConsole], y

    ldy #struct_console::cur_color
    lda cur_color
    sta [pConsole], y

    ldy #struct_console::cur_screen
    lda cur_screen
    sta [pConsole], y

    ldy #struct_console::con_width
    lda con_width    
    sta [pConsole], y

    ldy #struct_console::con_height
    lda con_height
    sta [pConsole], y

    ldy #struct_console::org_x
    lda org_x
    sta [pConsole], y

    ldy #struct_console::org_y
    lda org_y
    sta [pConsole], y

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc

.proc console_charout: near
    mode16

    ; Save working registers
    ProcPrefix 
    ProcFar 

    ; Create local variable - Number in descending order - Number in descending order         
    DeclareLocal l_height, 10
	DeclareLocal l_width, 9
    DeclareLocal l_realx, 8        
	DeclareLocal l_realy, 7
    DeclareLocal l_orgx, 6        
	DeclareLocal l_orgy, 5
    DeclareLocal l_v, 4
    DeclareLocal l_s, 3
    DeclareLocal l_c, 2
    DeclareLocal l_x, 1        
	DeclareLocal l_y, 0
    SetLocalCount 11

    ; Declare parameters - reverse order        
    DeclareParam char, 0
    DeclareParam pConsole, 1       ; Skip 2 because long param    
    DeclareParam r_retVal, 3    

    ; Setup stack frame
    SetupStackFrame

    ; Unpack struct into locals
    ldy #struct_console::cur_x
    lda [pConsole], y
    sta l_x

    ldy #struct_console::cur_y
    lda [pConsole], y
    sta l_y

    ldy #struct_console::cur_color
    lda [pConsole], y
    sta l_c

    ldy #struct_console::cur_screen
    lda [pConsole], y
    sta l_s

    ldy #struct_console::org_x
    lda [pConsole], y
    sta l_orgx

    ldy #struct_console::org_y
    lda [pConsole], y
    sta l_orgy

    ldy #struct_console::con_height
    lda [pConsole], y
    sta l_height

    ldy #struct_console::con_width
    lda [pConsole], y
    sta l_width

    ; Deal with control codes

        ; CR
        ; LF
        ; ANSI???

    ; Translate ASCII to Screen Code
    mode8
    ;if ((ch >= 0x40 && ch <= 0x5F) ch -= 0x40;
    lda char
    cmp #$40
    blt skip1
        cmp #$60
        bge skip1
            sec
            sbc #$40
            bra done
skip1:
    ;if (ch >= 0xa0 && ch <= 0xbf)) ch -= 0x40;
    cmp #$a0
    blt skip2
        cmp #$c0
        bge skip2
            sec
            sbc #$40
            bra done
skip2:            
	;else if (ch >= 0xc0 && ch <= 0xdf) ch -= 0x80;
    cmp #$c0
    blt skip3
        cmp #$e0
        bge skip3
            sec
            sbc #$80
            bra done
skip3:    
	;else if (ch >= 0 && ch <= 0x1f) ch += 0x80;
    cmp #$00
    blt skip4
        cmp #$20
        bge skip4
            clc
            adc #$80
            bra done
skip4:        
	;else if ((ch >= 0x60 && ch <= 0x7F) ch += 0x40;	
    cmp #$60
    blt skip5
        cmp #$80
        bge skip5
            clc
            adc #$40
            bra done    

skip5:
    ;else if (ch >= 0x90 && ch <= 0x9f)) ch += 0x40;	
    cmp #$90
    blt skip6
        cmp #$a0
        bge skip6
            clc
            adc #$40
            bra done        
skip6:

done:    
    mode16
    
    ; Combine it with color
    sta l_v
    lda l_c
    xba
    ora l_v
    tax    

    ; Add origin x to x
    lda l_x
    clc
    adc l_orgx
    sta l_realx

    ; Add origin y to y
    lda l_y
    clc
    adc l_orgy
    sta l_realy

    ; Put the character to the screen
    Screen_Put_CharColor ^^l_s, ^^l_realx, ^^l_realy, ^X

    ; x=x+1
    inc l_x

    ; if x >= max width    
    lda l_width
    cmp l_x
    bne @1
        ; y=y+1
        inc l_y

        ; x=0
        lda #$0000
        sta l_x
@1:

    ; if y >= max height    
    lda l_height    
    cmp l_y
    bne @2
        ; scroll                
        Screen_Scroll_Window ^^l_s, ^^l_orgx, ^^l_orgy, ^^l_width, ^^l_height

        ; y= max_height-1
        dec
        sta l_y

@2:    

    ; Locals back to struct
    ldy #struct_console::cur_x
    lda l_x
    sta [pConsole], y

    ldy #struct_console::cur_y
    lda l_y
    sta [pConsole], y

    ; Exit the procedure
    FreeLocals
    ProcSuffix      

    rtl

.endproc