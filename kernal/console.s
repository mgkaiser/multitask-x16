.p816

.include "screen.inc"
.include "console.inc"
.include "io.inc"
.include "mac.inc"
.include "regs.inc"

.import screen_put_charcolor

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
    DeclareParam con_height, 0
    DeclareParam con_width, 1   
    DeclareParam cur_screen, 2
    DeclareParam cur_color, 3
    DeclareParam cur_y, 4
    DeclareParam cur_x, 5
    DeclareParam pConsole, 6       ; Skip 2 because long param    
    DeclareParam r_retVal, 8    

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
    DeclareLocal l_v, 4
    DeclareLocal l_s, 3
    DeclareLocal l_c, 2
    DeclareLocal l_x, 1        
	DeclareLocal l_y, 0
    SetLocalCount 5

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

    ; Deal with control codes

        ; CR
        ; LF
        ; ANSI???

    ; Translate ASCII to Screen Code
    lda char
    sta l_v

    ; Combine it with color
    lda l_c
    xba
    ora l_v
    tax

    ; Put the character to the screen
    Screen_Put_CharColor ^^l_s, ^^l_x, ^^l_y, ^X

    ; x=x+1
    inc l_x

    ; if x >= max width
    ldy #struct_console::con_width
    lda [pConsole], y 
    cmp l_x
    bne @1
        ; y=y+1
        inc l_y

        ; x=0
        lda #$0000
        sta l_x
@1:

    ; if y >= max height
    ;   scroll
    ;   y= max_height

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