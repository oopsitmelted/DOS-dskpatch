	    [bits 16]
		global  WRITE_HEX
    ;--------------------------------------------------------------------;
    ; This procedure converts the byte in the DL register to hex and	 ;
    ; writes the two hex digits at the current cursor position. 	 ;
    ;									 ;
    ;	    DL	    Byte to be converted to hex.			 ;
    ;									 ;
    ; Uses:	    WRITE_HEX_DIGIT					 ;
    ;--------------------------------------------------------------------;
    WRITE_HEX:	    ; Entry point
	    PUSH    CX			    ; Save registers used in this procedure
	    PUSH    DX
	    MOV     DH,DL		    ; Make copy of byte
	    MOV     CX,4		    ; Get the upper nibble in DL
	    SHR     DL,CL
	    CALL    WRITE_HEX_DIGIT	    ; Display first hex digit
	    MOV     DL,DH		    ; Get lower nibble into DL
	    AND     DL,0Fh		    ; Remove the upper nibble
	    CALL    WRITE_HEX_DIGIT	    ; Display second hex digit
	    POP     DX
	    POP     CX
	    RET

	    global  WRITE_HEX_DIGIT
    ;--------------------------------------------------------------------;
    ; This procedure converts the lower 4 bits of DL to a hex digit and  ;
    ; writes it to the screen.						 ;
    ;									 ;
    ;	    DL	    Lower 4 bits contain number to be printed in hex.	 ;
    ;									 ;
    ; Uses:	    WRITE_CHAR						 ;
    ;--------------------------------------------------------------------;
    WRITE_HEX_DIGIT:
	    PUSH    DX			    ; Save registers used
	    CMP     DL,10		    ; Is this nibble <10?
	    JAE     HEX_LETTER		    ; No, convert to a letter
	    ADD     DL,"0"		    ; Yes, convert to a digit
	    JMP     WRITE_DIGIT	    ; Now write this character
    HEX_LETTER:
	    ADD     DL,"A"-10		    ; Convert to hex letter
    WRITE_DIGIT:
	    CALL    WRITE_CHAR		    ; Display the letter on the screen
	    POP     DX			    ; Restore old value of AX
	    RET

	    global  WRITE_CHAR
	    extern  CURSOR_RIGHT
    ;----------------------------------------------------------------------;
    ; This procedure outputs to the screen using the ROM BIOS		   ;
    ; routines, so that characters such as the backspace are treated as    ;
    ; any other character and are displayed.				   ;
    ;  This procedure must do a bit of work to update the cursor position. ;
    ;									   ;
    ;	    DL	    Byte to print on screen.				   ;
    ;									   ;
    ; Uses:	    CURSOR_RIGHT					   ;
    ;----------------------------------------------------------------------;
    WRITE_CHAR:
	    PUSH    AX
	    PUSH    BX
	    PUSH    CX
	    PUSH    DX
	    MOV     AH,9		    ; Call for output of character/attribute
	    MOV     BH,0		    ; Set to display page 0
	    MOV     CX,1		    ; Write only one character
	    MOV     AL,DL		    ; Character to write
	    MOV     BL,7		    ; Normal attribute
	    INT     10h 		   ; Write character and attribute
	    CALL    CURSOR_RIGHT	    ; Now move to next cursor position
	    POP     DX
	    POP     CX
	    POP     BX
	    POP     AX
	    RET

	    global  WRITE_DECIMAL
    ;---------------------------------------------------------------------;
    ; This procedure writes a 16-bit, unsigned number in decimal notation.;
    ;									  ;
    ;	    DX	    N : 16-bit, unsigned number.			  ;
    ;									  ;
    ; Uses:	    WRITE_HEX_DIGIT					  ;
    ;---------------------------------------------------------------------;
    WRITE_DECIMAL:
	    PUSH    AX			    ; Save registers used here
	    PUSH    CX
	    PUSH    DX
	    PUSH    SI
	    MOV     AX,DX
	    MOV     SI,10		    ; Will divide by 10 using SI
	    XOR     CX,CX		    ; Count of digits placed on stack
    NON_ZERO:
	    XOR     DX,DX		    ; Set upper word of N to 0
	    DIV     SI			    ; Calculate N/10 and (N mod 10)
	    PUSH    DX			    ; Push one digit onto the stack
	    INC     CX			    ; One more digit added
	    OR	    AX,AX		    ; N = 0 yet?
	    JNE     NON_ZERO		    ; Nope, continue
    WRITE_DIGIT_LOOP:
	    POP     DX			    ;Get the digits in reverse order
	    CALL    WRITE_HEX_DIGIT
	    LOOP    WRITE_DIGIT_LOOP
    END_DECIMAL:
	    POP     SI
	    POP     DX
	    POP     CX
	    POP     AX
	    RET

	    global  WRITE_CHAR_N_TIMES
    ;--------------------------------------------------------------------------;
    ; This procedure writes more than one copy of a character		       ;
    ;									       ;
    ;	    DL	    Character code					       ;
    ;	    CX	    Number of times to write the character		       ;
    ;									       ;
    ; Uses:	    WRITE_CHAR						       ;
    ;--------------------------------------------------------------------------;
    WRITE_CHAR_N_TIMES:
	    PUSH    CX
    N_TIMES:
	    CALL    WRITE_CHAR
	    LOOP    N_TIMES
	    POP     CX
	    RET

	    global  WRITE_PATTERN
    ;--------------------------------------------------------------------------;
    ; This procedure writes a line to the screen, base on the data in the      ;
    ; form								       ;
    ;									       ;
    ;	    DB	    {character, number of times to write character},0	       ;
    ; Where {x} means that x can be repeated any number of times	       ;
    ;	    DS:DX   Address of above data statement			       ;
    ;									       ;
    ; Uses:	    WRITE_CHAR_N_TIMES					       ;
    ;--------------------------------------------------------------------------;
    WRITE_PATTERN:
	    PUSH    AX
	    PUSH    CX
	    PUSH    DX
	    PUSH    SI
	    PUSHF			    ; Save the direction flag
	    CLD 			    ; Set direction flag for increment
	    MOV     SI,DX		    ; Move offset into SI register for LODSB
    PATTERN_LOOP:
	    LODSB			    ; Get character data into AL
	    OR	    AL,AL		    ; Is it the end of data (0h)?
	    JZ	    END_PATTERN 	    ; Yes, return
	    MOV     DL,AL		    ; No, set up to write character N times
	    LODSB			    ; Get the repeat count into AL
	    MOV     CL,AL		    ; And put in CX for WRITE_CHAR_N_TIMES
	    XOR     CH,CH		    ; Zero upper byte for CX
	    CALL    WRITE_CHAR_N_TIMES
	    JMP     PATTERN_LOOP
    END_PATTERN:
	    POPF			    ; Restore direction flag
	    POP     SI
	    POP     DX
	    POP     CX
	    POP     AX
	    RET

	    global  WRITE_HEADER
	    extern  HEADER_LINE_NO, HEADER_PART_1, HEADER_PART_2, DISK_DRIVE_NO
	    extern  CURRENT_SECTOR_NO, GOTO_XY, CLEAR_TO_END_OF_LINE
    ;----------------------------------------------------------------------;
    ; This procedure writes the header with disk-drive and sector number   ;
    ;									   ;
    ; Uses:	    GOTO_XY, WRITE_STRING, WRITE_CHAR, WRITE_DECIMAL	   ;
    ;		    CLEAR_TO_END_OF_LINE				   ;
    ; Reads:	    HEADER_LINE_NO, HEADER_PART_1, HEADER_PART_2	   ;
    ;		    DISK_DRIVE_NO, CURRENT_SECTOR_NO			   ;
    ;----------------------------------------------------------------------;
    WRITE_HEADER:
	    PUSH    DX
	    XOR     DL,DL		    ; Move cursor to header line number
	    MOV     DH,[HEADER_LINE_NO]
	    CALL    GOTO_XY
	    LEA     DX,HEADER_PART_1
	    CALL    WRITE_STRING
	    MOV     DL,[DISK_DRIVE_NO]
	    ADD     DL,'A'		    ; Print drives A, B, ...
	    CALL    WRITE_CHAR
	    LEA     DX,HEADER_PART_2
	    CALL    WRITE_STRING
	    MOV     DX,[CURRENT_SECTOR_NO]
	    CALL    WRITE_DECIMAL
	    CALL    CLEAR_TO_END_OF_LINE    ; Clear rest of sector number
	    POP     DX
	    RET

	    global  WRITE_STRING
    ;---------------------------------------------------------------------;
    ; This procedure writes a string of characters to the screen. The	  ;
    ; string must end with	DB	0				  ;
    ;									  ;
    ;	    DS:DX   Address of the string				  ;
    ;									  ;
    ; Uses:	    WRITE_CHAR						  ;
    ;---------------------------------------------------------------------;
    WRITE_STRING:
	    PUSH    AX
	    PUSH    DX
	    PUSH    SI
	    PUSHF			    ; Save direction flag
	    CLD 			    ; Set direction for increment (forward)
	    MOV     SI,DX		    ; Place address into SI for LODSB
    STRING_LOOP:
	    LODSB			    ; Get a character into the AL register
	    OR	    AL,AL		    ; Have we found 0 yet?
	    JZ	    END_OF_STRING	    ; Yes, we are done with the string
	    MOV     DL,AL		    ; No, write character
	    CALL    WRITE_CHAR
	    JMP     STRING_LOOP
    END_OF_STRING:
	    POPF			    ; Restore direction flag
	    POP     SI
	    POP     DX
	    POP     AX
	    RET

	    global  WRITE_PROMPT_LINE
	    extern  CLEAR_TO_END_OF_LINE, GOTO_XY, PROMPT_LINE_NO
    ;----------------------------------------------------------------------;
    ; This procedure writes the prompt line to the screen and clears the   ;
    ; end of the line.							   ;
    ;									   ;
    ;	    DS:DX   Address of the prompt-line message			   ;
    ;									   ;
    ; Uses:	    WRITE_STRING, CLEAR_TO_END_OF_LINE, GOTO_XY 	   ;
    ; Reads:	    PROMPT_LINE_NO					   ;
    ;----------------------------------------------------------------------;
    WRITE_PROMPT_LINE:
	    PUSH    DX
	    XOR     DL,DL		    ; Write the prompt line and
	    MOV     DH,[PROMPT_LINE_NO]	    ; move cursor there
	    CALL    GOTO_XY
	    POP     DX
	    CALL    WRITE_STRING
	    CALL    CLEAR_TO_END_OF_LINE
	    RET

	    global  WRITE_ATTRIBUTE_N_TIMES
	    extern  CURSOR_RIGHT
    ;---------------------------------------------------------------------;
    ; This procedure sets the attribute for N characters, starting at the ;
    ; current cursor position.						  ;
    ;									  ;
    ;	    CX	    Number of characters to set attribute for		  ;
    ;	    DL	    New attribute for characters			  ;
    ;									  ;
    ; Uses:	    CURSOR_RIGHT					  ;
    ;---------------------------------------------------------------------;
    WRITE_ATTRIBUTE_N_TIMES:
	    PUSH    AX
	    PUSH    BX
	    PUSH    CX
	    PUSH    DX
	    MOV     BL,DL		    ; Set attribute to new attribute
	    XOR     BH,BH		    ; Set display page to 0
	    MOV     DX,CX		    ; CX is used by BIOS routines
	    MOV     CX,1		    ; Set attribute for one character
    ATTR_LOOP:
	    MOV     AH,8		    ; Read character under cursor
	    INT     10h
	    MOV     AH,9		    ; Write attribute/character
	    INT     10h
	    CALL    CURSOR_RIGHT
	    DEC     DX			    ; Set attribute for N characters?
	    JNZ     ATTR_LOOP		    ; No, continue
	    POP     DX
	    POP     CX
	    POP     BX
	    POP     AX
	    RET