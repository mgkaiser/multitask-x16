.p816

.include "multitask.inc"
.include "regs.inc"

; from process.s
.import mt_init
.import mt_done
.import mt_start
.import mt_kill

.export currentTask
.export oldIrq
.export taskTable

; Room for 21 jumps unless we expand the cfg
.segment "JUMP"
	jmp mt_init
    jmp mt_done
	jmp mt_start
	jmp mt_kill

.segment "DATA"

	currentTask: .byte $00
	oldIrq:		 .word $0000

	; 32 bytes to hold task table.  All, $00, not used yet
	taskTable: 
		.word $ffff, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
		.word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
