.p816

.include "mac.inc"
.include "io.inc"
.include "multitask.inc"
.include "screen.inc"
.include "console.inc"
.include "pipes.inc"

;;# TODO: "Critical Section" needs to be implemented without suspending interrupts.  If critical section is on, just don't task switch,  still process interrupts
;;# TODO: Stream devices: CONOUT as first device dumps content of pipe to a console
;;                        CONIN as second device dumps input from keyboard to "focused" pipe
;;# TODO: Far Malloc
;;# TODO: Native Mode FAT32
;;# TODO: Native Mode I2c

.export vec_reset_02

.import screen_init, screen_set_active, screen_clear_screen, screen_put_charcolor
.import ioinit, screen_init, screen_clear_line, screen_get_color
.import screen_set_color, screen_get_char, screen_set_char
.import screen_set_char_color, screen_get_char_color
.import screen_set_position, screen_get_position

.import i2c_read_byte, i2c_write_byte, i2c_batch_read, i2c_batch_write
.import i2c_read_first_byte, i2c_read_next_byte, i2c_read_stop, i2c_direct_read
.import i2c_write_first_byte, i2c_write_next_byte, i2c_write_stop
.import i2c_restore, i2c_mutex

.import mt_init, mt_start

.import pipe_init, pipe_push, pipe_pop
.import pipe_conout, pipe_kbdin

.import console_init, console_charout

.segment "KERNAL_VAR"

character:  .byte $00
character2: .byte $00

console1:   .res .sizeof(struct_console)
console2:   .res .sizeof(struct_console)

.segment "KERNAL"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Stuff in "drivers" are low level, call directly, never called from user programs
;;
;; Stuff above "drivers" are high level, uses params and stack frame, can be called by user programs
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
    jsr i2c_restore      ;release I2C pins and clear mutex flag    
    mode16

    ; Initialize pages - Ends up in $00 and $01 because 16 bit
    stz $00    

    ; Initialize the screen driver 
    Screen_Init      

    ; Initialize 2 consoles    
    Console_Init console1, #$00, #$00, #$61, #$01, #80, #60
    Console_Init console2, #$00, #$00, #$61, #$02, #80, #60
    
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
                        
    @99:                
        lda character
        inc
        sta character           
        Screen_Put_CharColor #1, #3, #7, ^A       
        
        ;mode8	        
        ;sta $9fb9
        ;mode16            

        cop #$00     
    bra @99    
    
    ;ldx #$42
    ;ldy #$07    
    ;jsr i2c_read_byte   

.proc thread: near
        
    @1:  

        mode16                
        lda character2
        inc 
        sta character2              
        Screen_Put_CharColor #1, #3, #3, ^A             

        ;mode8	        
        ;sta $9fba
        ;mode16
        
        cop #$00        
    bra @1
    rtl
.endproc