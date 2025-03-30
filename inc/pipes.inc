.struct pipe
    head    .word
    tail    .word
    buffer  .res 16    
.endstruct

.macro Pipe_Init pPipe
    .out "Pipe_Init"
    SetRetVal               ; Return Value                
    SetParamL f:pPipe       ; pointer to pipe       - Counts a 2 because long
    jsl pipe_init           ; Kill the process
    FreeParams 3            ; Pop all the params off leaving return value in A  
.endmacro
