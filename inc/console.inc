.struct struct_console
    cur_x       .word
    cur_y       .word
    cur_color   .word
    cur_screen  .word
    con_width   .word
    con_height  .word
.endstruct

.macro Console_Init pConsole, cur_x, cur_y, cur_color, cur_screen, con_width, con_height
    .out "Console_Init"    
    SetRetVal                   ; Return Value 
    SetParamL f:pConsole
    SetParam cur_x
    SetParam cur_y
    SetParam cur_color    
    SetParam cur_screen
    SetParam con_width   
    SetParam con_height
    jsl console_init
    FreeParams 9
.endmacro

.macro Console_CharOut pConsole, ch
    .out "Console_CharOut"    
    SetRetVal                   ; Return Value 
    SetParamL f:pConsole
    SetParam ch  
    jsl console_charout
    FreeParams 4
.endmacro

; # TODO: Chose color
.macro Console_SetColor pConsole, color
    .out "Console_SetColor"   
    SetRetVal                   ; Return Value 
    SetParamL f:pConsole
    SetParam color  
    jsl console_setcolor
    FreeParams 4
.endmacro

; # TODO: Move Cursor
.macro Console_GotoXY pConsole, new_x, new_y
    .out "Console_GotoXY"    
    SetRetVal                   ; Return Value 
    SetParamL f:pConsole
    SetParam new_x
    SetParam new_y  
    jsl console_setcolor
    FreeParams 5
.endmacro