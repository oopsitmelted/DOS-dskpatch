	[bits 16]
	CR	    EQU     13			    ;Carriage return
    LF	    EQU     10			    ;Line feed

		global	SEND_CRLF
    ;--------------------------------------------------------------------;
    ; This routine just sends a carriage-return/line-feed pair to the	 ;
    ; display, using the DOS routines so that scrolling will be handled  ;
    ; correctly.							 ;
    ;--------------------------------------------------------------------;
    SEND_CRLF:
	    PUSH    AX
	    PUSH    DX
	    MOV     AH,2
	    MOV     DL,CR
	    INT     21h
	    MOV     DL,LF
	    INT     21h
	    POP     DX
	    POP     AX
	    RET

	    global  CLEAR_SCREEN
    ;--------------------------------------------------------------------;
    ; This procedure clears the entire screen.				 ;
    ;--------------------------------------------------------------------;

    CLEAR_SCREEN:
	    PUSH    AX
	    PUSH    BX
	    PUSH    CX
	    PUSH    DX
	    XOR     AL,AL		    ; Blank entire window
	    XOR     CX,CX		    ; Upper left corner is at (0,0)
	    MOV     DH,24		    ; Bottom line of screen is line 24
	    MOV     DL,79		    ; Right side is at column 79
	    MOV     BH,7		    ; Use normal attribute for blanks
	    MOV     AH,6		    ; Call for SCROLL_UP function
	    INT     10h 		    ; Clear the window
	    POP     DX
	    POP     CX
	    POP     BX
	    POP     AX
	    RET

	    global  GOTO_XY
    ;--------------------------------------------------------------------;
    ; This procedure moves the cursor					 ;
    ;									 ;
    ;	    DH	    Row (Y)						 ;
    ;	    DL	    Column (X)						 ;
    ;									 ;
    ;--------------------------------------------------------------------;
    GOTO_XY:
	    PUSH    AX
	    PUSH    BX
	    MOV     BH,0		    ; Display page 0
	    MOV     AH,2		    ; Call for SET CURSOR POSITION
	    INT     10h
	    POP     BX
	    POP     AX
	    RET

	    global  CURSOR_RIGHT
    ;---------------------------------------------------------------------;
    ; This procedure moves the cursor one position to the right or to the ;
    ; next line if the cursor was at the end of a line. 		  ;
    ;									  ;
    ; Uses:	    SEND_CRLF						  ;
    ;---------------------------------------------------------------------;
    CURSOR_RIGHT:
	    PUSH    AX
	    PUSH    BX
	    PUSH    CX
	    PUSH    DX
	    MOV     AH,3		    ; Read the current cursor position
	    MOV     BH,0		    ; On page 0
	    INT     10h 		    ; Read cursor position
	    MOV     AH,2		    ; Set new cursor position
	    INC     DL			    ; Set column to next position
	    CMP     DL,79		    ; Make sure column <= 79
	    JBE     OK
	    CALL    SEND_CRLF		    ; Go to next line
	    JMP     DONE
    OK:     
		INT     10h
    DONE:   
		POP     DX
	    POP     CX
	    POP     BX
	    POP     AX
	    RET

	    global  CLEAR_TO_END_OF_LINE
    ;---------------------------------------------------------------------;
    ; This procedure clears  the line from the current cursor position to ;
    ; the end of that line.						  ;
    ;---------------------------------------------------------------------;
    CLEAR_TO_END_OF_LINE:
	    PUSH    AX
	    PUSH    BX
	    PUSH    CX
	    PUSH    DX
	    MOV     AH,3		    ; Read current cursor position
	    XOR     BH,BH		    ; on page 0
	    INT     10h 		    ; Now have (X,Y) in DL, DH
	    MOV     AH,6		    ; Set up to clear to end of line
	    XOR     AL,AL		    ; Clear window
	    MOV     CH,DH		    ; All on same line
	    MOV     CL,DL		    ; Start at the cursor position
	    MOV     DL,79		    ; And stop at the end of the line
	    MOV     BH,7		    ; Use normal attribute
	    INT     10h
	    POP     DX
	    POP     CX
	    POP     BX
	    POP     AX
	    RET