.macro Screen_Init
    .out "Screen_Init"
    SetRetVal               ; Return Value   
    jsl screen_init         ; Init the multitasking scheduler
    FreeParams 1            ; Pop all the params off leaving return value in A  
.endmacro

; Clear a line
.macro Screen_Clear_Line screen, line
    .out "Screen_Clear_Line"
    SetRetVal               ; Return Value   
    SetParam screen
    SetParam line           ; The line to clear
    jsl screen_clear_line   ; 
    FreeParams 3            ; Pop all the params off leaving return value in A  
.endmacro

; Clear the screen
.macro Screen_Clear_Screen screen
    .out "Screen_Clear_Screen"
    SetRetVal               ; Return Value       
    SetParam screen
    jsl screen_clear_screen ; 
    FreeParams 2            ; Pop all the params off leaving return value in A  
.endmacro

; Put char/color at x/y
.macro Screen_Put_CharColor screen, xpos, ypos, charcolor
    .out "Screen_Put_CharColor"    
    SetRetVal                   ; Return Value 
    SetParam screen
    SetParam xpos               ; 
    SetParam ypos               ; 
    SetParam charcolor          ; color in high, char in low
    jsl screen_put_charcolor    ; 
    FreeParams 5                ; Pop all the params off leaving return value in A      
.endmacro

; Get char/color at x/y

; Set Active Screen - Make the specified screen active
.macro Screen_Set_Active screen
    .out "Screen_Set_Active"
    SetRetVal                   ; Return Value 
    SetParam screen             ; 
    jsl screen_set_active       ; 
    FreeParams 2                ; Pop all the params off leaving return value in A  
.endmacro

; Scroll the screen
.macro Screen_Scroll screen
    .out "Screen_Scroll"
    SetRetVal                   ; Return Value 
    SetParam screen             ; 
    jsl screen_scroll           ; 
    FreeParams 2                ; Pop all the params off leaving return value in A  
.endmacro

; Scroll a window
.macro Screen_Scroll_Window screen, org_x, org_y, width, height
    .out "Screen_Scroll_Window"
    SetRetVal                   ; Return Value 
    SetParam screen             ; 
    SetParam org_x              ;
    SetParam org_y              ;
    SetParam width              ;
    SetParam height             ;
    jsl screen_scroll_window    ; 
    FreeParams 6                ; Pop all the params off leaving return value in A  
.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Implement these later
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Get Line Length

; Set Line Length

; Set Char Address

; Get Char Address

; Load Charset