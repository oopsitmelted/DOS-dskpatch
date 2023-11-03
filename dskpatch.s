        [bits 16]
        RESB 100h

	    extern  CLEAR_SCREEN
        extern  READ_SECTOR
	    extern  INIT_SEC_DISP
        extern  WRITE_HEADER
	    extern  WRITE_PROMPT_LINE
        extern  DISPATCHER

..start:
	    CALL    CLEAR_SCREEN
	    CALL    WRITE_HEADER
	    CALL    READ_SECTOR
	    CALL    INIT_SEC_DISP
	    LEA     DX,EDITOR_PROMPT
	    CALL    WRITE_PROMPT_LINE
	    CALL    DISPATCHER
	    INT     20h

	    global  SECTOR_OFFSET, CURRENT_SECTOR_NO, DISK_DRIVE_NO
    ;----------------------------------------------;
    ; SECTOR_OFFSET is offset of the half	   ;
    ; sector display into the full sector. It must ;
    ; be a multiple of 16, and not greater than 256;
    ;----------------------------------------------;
    SECTOR_OFFSET           DW	    0
    CURRENT_SECTOR_NO	    DW	    0		    ; Initially sector 0
    DISK_DRIVE_NO	        DB	    0		    ; Initially Drive A:

	    global  LINES_BEFORE_SECTOR, HEADER_LINE_NO
	    global  HEADER_PART_1, HEADER_PART_2
        global  PROMPT_LINE_NO, EDITOR_PROMPT
    ;----------------------------------------------;
    ; LINE_BEFORE_SECTOR is the number of lines    ;
    ; at the top of the screen before the half-    ;
    ; sector display.				   ;
    ;----------------------------------------------;
    LINES_BEFORE_SECTOR     DB	    2
    HEADER_LINE_NO	        DB	    0
    HEADER_PART_1	        DB	    'Disk ',0
    HEADER_PART_2	        DB	    '         Sector ',0
    PROMPT_LINE_NO	        DB	    21
    EDITOR_PROMPT	        DB	    'Press function key, or enter'
			                DB	    ' character or hex byte: ',0

	    global  SECTOR
    ;----------------------------------------------;
    ; The entire sector (up to 8192 bytes) is	   ;
    ; stored in this part of memory.		   ;
    ;----------------------------------------------;
    SECTOR                  DB	    8192  DUP (0)