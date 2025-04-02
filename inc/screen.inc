.struct screen
    screen_addr     .dword
    charset_addr    .dword
    color           .byte
    llen            .byte    
.endstruct

.macro Screen_Init
    .out "Screen_Init"
    SetRetVal               ; Return Value   
    jsl screen_init         ; Init the multitasking scheduler
    FreeParams 1            ; Pop all the params off leaving return value in A  
.endmacro

; Clear a line
.macro Screen_Clear_Line line
    .out "Screen_Clear_Line"
    SetRetVal               ; Return Value   
    SetParam line           ; The line to clear
    jsl screen_clear_line   ; 
    FreeParams 2            ; Pop all the params off leaving return value in A  
.endmacro

; Clear the screen
.macro Screen_Clear_Screen
    .out "Screen_Clear_Screen"
    SetRetVal               ; Return Value       
    jsl screen_clear_screen ; 
    FreeParams 1            ; Pop all the params off leaving return value in A  
.endmacro

; Put char at x/y
; Put color at x/y

; Get char at x/y
; Get color at x/y

; Put char/color at x/y
.macro Screen_Put_CharColor
    .out "Screen_Put_CharColor"
    SetRetVal                   ; Return Value 
    SetParam xpos               ; 
    SetParam ypos               ; 
    SetParam charcolor          ; color in high, char in low
    jsl screen_put_charcolor    ; 
    FreeParams 4                ; Pop all the params off leaving return value in A  
.endmacro

; Get char/color at x/y

; Get default color

; Set default color

; Get Line Length

; Set Line Length

; Set Screen Address

; Get Screen Address

; Set Char Address

; Get Char Address

; Load Charset

; Set Active Screen

; Get Active Screen

; Init Screen Data