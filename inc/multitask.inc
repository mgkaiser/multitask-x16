max_tasks       = $20

.macro Multitask_Init
    SetRetVal               ; Return Value   
    jsl mt_init             ; Init the multitasking scheduler
    FreeParams 1            ; Pop all the params off leaving return value in A  
.endmacro

.macro Multitask_Done
    SetRetVal               ; Return Value   
    jsl mt_done             ; Shutdown the multitasking scheduler
    FreeParams 1            ; Pop all the params off leaving return value in A  
.endmacro

.macro Multitask_Start procAddr, procStack, dataBank
    .out "Multitask_Start"
    SetRetVal               ; Return Value       
    SetParamL f:procAddr    ; pointer to process                                   - Counts a 2 because long                 
    SetParam procStack      ; Stack for the process we are starting    
    SetParam dataBank       ; Databank for the process we are starting
    jsl mt_start            ; Start the process
    FreeParams 5            ; Pop all the params off leaving return value in A  
.endmacro

.macro Multitask_Kill procId
    SetRetVal               ; Return Value                
    SetParam procId         ; Process ID    
    jsl mt_kill             ; Kill the process
    FreeParams 2            ; Pop all the params off leaving return value in A  
.endmacro

.macro Multitask_find_proc_slot pTaskTable
    SetRetVal               ; Return Value                    
    rjsr find_proc_slot
    FreeParams 1            ; Pop all the params off leaving return value in A  
.endmacro