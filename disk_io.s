
		[bits 16]
		extern   SECTOR
	    extern   DISK_DRIVE_NO
	    extern   CURRENT_SECTOR_NO

		global READ_SECTOR
    ;--------------------------------------------------------------------;
    ; This procedure reads one sector (512 bytes) into SECTOR.		 	;
    ;									 								;
    ; Reads:	    CURRENT_SECTOR_NO, DISK_DRIVE_NO			 		;
    ; Writes:	    SECTOR						 						;
    ;--------------------------------------------------------------------;
    READ_SECTOR:
	    PUSH    AX
	    PUSH    BX
	    PUSH    CX
	    PUSH    DX
	    MOV     AL,[DISK_DRIVE_NO]	    ; Drive number
	    MOV     CX,1		    		; Read only 1 sector
	    MOV     DX,[CURRENT_SECTOR_NO]  ; Logical sector number
	    LEA     BX,[SECTOR]		    	; Where to store this sector
	    INT     25h 		    		; Read the sector
	    POPF			    			; Discard flags put on stack by DOS
	    POP     DX
	    POP     CX
	    POP     BX
	    POP     AX
	    RET

	    global  WRITE_SECTOR
    ;--------------------------------------------------------------------;
    ; This procedure writes the sector back to the disk 		 		;
    ;									 								;
    ; Reads:	    DISK_DRIVE_NO, CURRENT_SECTOR_NO, SECTOR		 	;
    ;--------------------------------------------------------------------;
    WRITE_SECTOR:
	    PUSH    AX
	    PUSH    BX
	    PUSH    CX
	    PUSH    DX
	    MOV     AL,[DISK_DRIVE_NO]	    ; Drive number
	    MOV     CX,1		    		; Write 1 sector
	    MOV     DX,[CURRENT_SECTOR_NO]  ; Logical sector
	    LEA     BX,[SECTOR]
	    INT     26h 		    		; Write the sector to disk
	    POPF			    			; Discard the flag information
	    POP     DX
	    POP     CX
	    POP     BX
	    POP     AX
	    RET

	    extern	INIT_SEC_DISP 
		extern	WRITE_HEADER
	    extern  WRITE_PROMPT_LINE
	    extern  CURRENT_SECTOR_NO
		extern  EDITOR_PROMPT

		global	PREVIOUS_SECTOR
    ;--------------------------------------------------------------------;
    ; This procedure reads the previous sector, if possible.		 	;
    ;									 								;
    ; Uses:	    WRITE_HEADER, READ_SECTOR, INIT_SEC_DISP		 		;
    ;		    WRITE_PROMPT_LINE					 					;
    ; Reads:	    CURRENT_SECTOR_NO, EDITOR_PROMPT			 		;
    ; Writes:	    CURRENT_SECTOR_NO					 				;
    ;--------------------------------------------------------------------;
    PREVIOUS_SECTOR:
	    PUSH    AX
	    PUSH    DX
	    MOV     AX,[CURRENT_SECTOR_NO]    ; Get current sector number
	    OR	    AX,AX		    		; Don't decrement if already 0
	    JZ	    DONT_DECREMENT_SECTOR
	    DEC     AX
	    MOV     [CURRENT_SECTOR_NO],AX    ; Save new sector number
	    CALL    WRITE_HEADER
	    CALL    READ_SECTOR
	    CALL    INIT_SEC_DISP	    	; Display new sector
	    LEA     DX,[EDITOR_PROMPT]
	    CALL    WRITE_PROMPT_LINE
    DONT_DECREMENT_SECTOR:
	    POP     DX
	    POP     AX
	    RET

	    extern   INIT_SEC_DISP
		extern   WRITE_HEADER
	    extern   WRITE_PROMPT_LINE
	    extern   CURRENT_SECTOR_NO
		extern   EDITOR_PROMPT

		global NEXT_SECTOR
    ;--------------------------------------------------------------------;
    ; Reads next sector.						 						;
    ;									 								;
    ; Uses:	    WRITE_HEADER, READ_SECTOR, INIT_SEC_DISP		 		;
    ;		    WRITE_PROMPT_LINE					 					;
    ; Reads:	    CURRENT_SECTOR_NO, EDITOR_PROMPT					;
    ; Writes:	    CURRENT_SECTOR_NO					 				;
    ;--------------------------------------------------------------------;
    NEXT_SECTOR:
	    PUSH    AX
	    PUSH    DX
	    MOV     AX,[CURRENT_SECTOR_NO]
	    INC     AX			    		; Move to next sector
	    MOV     [CURRENT_SECTOR_NO],AX
	    CALL    WRITE_HEADER
	    CALL    READ_SECTOR
	    CALL    INIT_SEC_DISP	    	; Display new sector
	    LEA     DX,[EDITOR_PROMPT]
	    CALL    WRITE_PROMPT_LINE
	    POP     DX
	    POP     AX
	    RET