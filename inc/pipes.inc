PIPE_LEN=16

.struct pipe
    buffer  .res 16
    head    .word
    tail    .word
.endstruct

.macro Pipe_Init pPipe
    .out "Pipe_Init"
    SetRetVal               ; Return Value                
    SetParamL f:pPipe       ; pointer to pipe       - Counts a 2 because long
    jsl pipe_init           ; Kill the process
    FreeParams 3            ; Pop all the params off leaving return value in A  
.endmacro

.macro Pipe_Push pPipe, value 
    .out "Pipe_Push"
    SetRetVal               ; Return Value                
    SetParamL f:pPipe       ; pointer to pipe       - Counts a 2 because long
    SetParam value          ; The value to push
    jsl pipe_push
    FreeParams 4            ; Pop all the params off leaving return value in A  
.endmacro

.macro Pipe_Pop
    .out "Pipe_Pop"
    SetRetVal               ; Return Value                
    SetParamL f:pPipe       ; pointer to pipe       - Counts a 2 because long
    jsl pipe_pop
    FreeParams 3            ; Pop all the params off leaving return value in A
.endmacro 