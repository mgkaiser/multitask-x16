# 65816 Kernal

## Screen

## Console

## Multitasking

## Pipes
``` 
PIPE_LEN=16

.struct pipe
    head    .word
    tail    .word
    buffer  .res 16    
.endstruct
```
### Pipe_Init
#### Overview
Initiaizes the pipe structure.
#### Input
* pPipe - A long (32-bit) pointer to the pipe struture
#### Output
* retVal - Not meaningful

### Pipe_Push
#### Overview
Adds a byte into the pipe.
#### Input
* pPipe - A long (32-bit) pointer to the pipe struture
* value - Passed as 16 bits, but only low byte is pushed to pipe
#### Output
* retVal - Not Meaningful
* CarryFlag - Set if the pipe is full, cleared if the value was accepted

### Pipe_Pop
#### Overview
Removes a byte from the pip
#### Input
* pPipe - A long (32-bit) pointer to the pipe struture
#### Output
* retVal - The byte removed from the pipe.  Returned as 16 bits, but only low byte is meaningful
* CarryFlag - Set if the pipe is empty, cleared if a value was returned

## I2C

## Fat32