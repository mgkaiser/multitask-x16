.segment "JUMP"
	jmp init

.segment "DATA"

	.word $0000
	.word $0001
	.word $0002
	.word $0004

.segment "CODE"

init:
	lda $00
	rts