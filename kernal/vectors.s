.p816

.include "mac.inc"

.import vec_reset_02
.import mt_scheduler


.segment "SIGNATURE"

.segment "VECTORS_816"
.word $0001             ; Reserved
.word $0002             ; Reserved
.word mt_scheduler      ; COP           -- Hook this as API handler
.word $0004             ; BRK
.word $0005             ; ABORT
.word $0006             ; NMI
.word $0007             ; Reserved
.word mt_scheduler      ; IRQ

.segment "VECTORS_02"
.word $0011             ; Reserved
.word $0012             ; Reserved
.word $0013             ; COP
.word $0014             ; Reserved
.word $0015             ; ABORT
.word $0016             ; NMI
.word vec_reset_02      ; Reset
.word $0018             ; IRQ