	    [bits 16]
		global  DISPATCHER
	    extern  READ_BYTE
		extern	EDIT_BYTE
	    extern  WRITE_PROMPT_LINE
	    extern  EDITOR_PROMPT
    ;--------------------------------------------------------------------;
    ; This is the central dispatcher. During normal editing and viewing, ;
    ; this procedure reads characters from the keyboard and if the char  ;
    ; is a command key (such as a cursor key), DISPATCHER calls the	 	;
    ; procedures that do the actual work. This dispatching is done for	 ;
    ; special keys listed in the DISPACH_TABLE, where the procedure	 	;
    ; addresses are stored just after the key names.			 		;
    ; If the character is not a special key, then it should be placed	 ;
    ; directly into the sector buffer -- this is the editing mode.	 	;
    ;									 								;
    ; Uses:	Read_Byte, Edit_Byte, Write_Prompt_Line 		 			;
    ; Reads:	EDITOR_PROMPT						 					;
    ;--------------------------------------------------------------------;
    DISPATCHER:
	    PUSH    AX
	    PUSH    BX
	    PUSH    DX
    DISPATCH_LOOP:
	    CALL    READ_BYTE		    ; Read character into AX
	    OR	    AH,AH		    	; AH = 0 if no character read, -1
					    			; for an extended code.
	    JZ	    NO_CHARS_READ	    ; No character read, try again
	    JS	    SPECIAL_KEY 	    ; Read extended code
	    MOV     DL,AL
	    CALL    EDIT_BYTE		    ; Was normal character, edit byte
	    JMP     DISPATCH_LOOP	    ; Read another character
    SPECIAL_KEY:
	    CMP     AL,68		    	; F10--exit?
	    JE	    END_DISPATCH	    ; Yes leave
					    			; Use BX to look through table
	    LEA     BX,DISPATCH_TABLE
    SPECIAL_LOOP:
	    CMP     byte [BX], 0		; End of table?
	    JE	    NOT_IN_TABLE	    ; Yes, key was not in the table
	    CMP     AL,[BX]		    	; Is it this table entry?
	    JE	    DISPATCH		    ; Yes, then dispatch
	    ADD     BX,3		    	; No, try next entry
	    JMP     SPECIAL_LOOP	    ; Check next table entry

    DISPATCH:
	    INC     BX			    	; Point to adress of procedure
	    CALL    word [BX]	    	; Call procedure
	    JMP     DISPATCH_LOOP	    ; Wait for another key

    NOT_IN_TABLE:			    	; Do nothing,just read next character
	    JMP     DISPATCH_LOOP

    NO_CHARS_READ:
	    LEA     DX,EDITOR_PROMPT
	    CALL    WRITE_PROMPT_LINE	; Erase any invalid characters typed
	    JMP     DISPATCH_LOOP	    ; Try again

    END_DISPATCH:
	    POP     DX
	    POP     BX
	    POP     AX
	    RET

	    extern  NEXT_SECTOR		      ; In DISK_IO.ASM
	    extern  PREVIOUS_SECTOR	      ; In DISK_IO.ASM
	    extern  PHANTOM_UP
		extern	PHANTOM_DOWN		  ; In PHANTOM.ASM
	    extern  PHANTOM_LEFT
		extern	PHANTOM_RIGHT
	    extern  WRITE_SECTOR		  ; In DISK_IO.ASM

    ;--------------------------------------------------------------------;
    ; This table contains the legal extended ASCII keys and the address  ;
    ; of the procedures that should be called when each key is pressed.  ;
    ;	    The format of the table is					 ;
    ;	    DB	    72			  ;Extended code for cursor up	 ;
    ;	    DW	    OFFSET CGROUP:PHANTOM_UP				 ;
    ;--------------------------------------------------------------------;
    DISPATCH_TABLE:
	    DB	    59				       ; F1
	    DW	    PREVIOUS_SECTOR
	    DB	    60				       ; F2
	    DW	    NEXT_SECTOR
	    DB	    72				       ; Cursor up
	    DW	    PHANTOM_UP
	    DB	    80				       ; Cursor down
	    DW	    PHANTOM_DOWN
	    DB	    75				       ; Cursor left
	    DW	    PHANTOM_LEFT
	    DB	    77				       ; Cursor right
	    DW	    PHANTOM_RIGHT
	    DB	    88				       ; Shift F5
	    DW	    WRITE_SECTOR
	    DB	    0				       ; End of the table