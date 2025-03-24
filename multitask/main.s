.p816

.include "mac.inc"
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
	brl mt_init
    brl mt_done
	brl mt_start
	brl mt_kill

.segment "DATA"

	currentTask: 	.byte $00
	oldIrq:		 	.word $0000	

	; 32 bytes to hold task table.  All, $00, not used yet
	taskTable: 
		.word $ffff, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
		.word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
