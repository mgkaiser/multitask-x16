.p816

.include "mac.inc"
.include "io.inc"
.include "i2c.inc"
.include "multitask.inc"
.include "screen.inc"
.include "console.inc"
.include "pipes.inc"

;;# TODO: "Critical Section" needs to be implemented without suspending interrupts.  If critical section is on, just don't task switch,  still process interrupts
;;# TODO: Stream devices: CONOUT as first device dumps content of pipe to a console
;;                        CONIN as second device dumps input from keyboard to "focused" pipe
;;# TODO: Far Malloc
;;# TODO: Native Mode FAT32

.export vec_reset_02

.import screen_init, screen_set_active, screen_clear_screen, screen_put_charcolor
.import ioinit, screen_init, screen_clear_line, screen_get_color
.import screen_set_color, screen_get_char, screen_set_char
.import screen_set_char_color, screen_get_char_color
.import screen_set_position, screen_get_position

.import i2c_restore, i2c_read_byte, i2c_write_byte

.import mt_init, mt_start

.import pipe_init, pipe_push, pipe_pop
.import pipe_conout, pipe_kbdin

.import console_init, console_charout

.segment "KERNAL_VAR"

character:  .word $00
character2: .word $00

console1:   .res .sizeof(struct_console)
console2:   .res .sizeof(struct_console)

.segment "KERNAL"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; We're always in 16 bit mode except when we aren't....
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vec_reset_02:
    
    BEGIN_CRITICAL_SECTION
    
    ; Native Mode
    modeNative
    mode16

    ; Setup stack    
    ldx #$01ff	
	txs      

    ; Start Interrupts       
    Multitask_Init   

    ; General IO Initialization
    mode8
    jsr ioinit           ;go initilize i/o devices
    mode16
    I2C_Restore    

    ; Initialize pages - Ends up in $00 and $01 because 16 bit
    stz $00    

    ; Initialize the screen driver 
    Screen_Init      

    ; Initialize 2 consoles        
    Console_Init console1, #$00, #$00, #$61, #$01, #40, #20, #10, #10
    Console_Init console2, #$00, #$00, #$61, #$01, #20, #10, #5, #38
    
    ; Init Pipes        
    Pipe_Init pipe_conout
    Pipe_Init pipe_kbdin            

    ; Clear the screen 
    Screen_Set_Active #1      
    Screen_Clear_Screen #1         

    ; Print test string    
    Console_CharOut console1, #$01
    Console_CharOut console1, #$02
    Console_CharOut console1, #$03
    Console_CharOut console1, #$04                          

    ; Start the 2nd thread    
    Multitask_Start thread, ^D       

    END_CRITICAL_SECTION    

    lda #'A'-1
    sta character
                        
    @99:                
        lda character
        inc
        and #$ff
        cmp #'Z' + 1
        bne @98
        lda #'A'
    @98:
        sta character             
        Console_CharOut console1, ^A                
        
        ;mode8	        
        ;sta $9fb9
        ;mode16            

        ;cop #$00     
    bra @99    
    
    ;ldx #$42
    ;ldy #$07    
    ;jsr i2c_read_byte   

.proc thread: near

    mode16    

    lda #'A'-1
    sta character2
        
    @1:                      
        lda character2
        inc
        and #$ff
        cmp #'O' + 1
        bne @2
        lda #'A'
    @2:
        sta character2
        Console_CharOut console2, ^A               

        I2C_Read_Byte #$4207
        beq @nokey
        mode8	        
        sta $9fba
        mode16
        @nokey:
        
        ;cop #$00        
    bra @1
    rtl
.endproc