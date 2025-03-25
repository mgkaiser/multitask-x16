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

.macro Multitask_Start procAddr, procBank, procStack, dataBank
    SetRetVal               ; Return Value                
    SetParam procAddr       ; Address of the process we are starting      
    SetParam procBank       ; Bank of the process we are starting    
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