.include "mac.inc"

.export tmp
.export tmp2

.segment "ZPKERNAL"
    tmp:    .byte $00, $00    
    tmp2:   .byte $00, $00

.segment "KVAR"

.segment "KVECTORS";rem kernal/os indirects(20)

.segment "KVAR2"
