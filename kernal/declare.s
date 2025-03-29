.include "mac.inc"
.include "pipes.inc"

.export pipe_conout
.export pipe_kbdin

;.export tmp
;.export tmp2

.segment "ZPKERNAL"
;    tmp:    .byte $00, $00    
;    tmp2:   .byte $00, $00

.segment "KVAR"
    PIPE_SIZE = .sizeof(pipe)
    pipe_conout:    .res PIPE_SIZE
    pipe_kbdin:     .res PIPE_SIZE

.segment "KVAR2"
