    [bits 16]
	;--------------------------------------------------------------------;
    ; Graphics characters for border of sector.                          ;
    ;--------------------------------------------------------------------;
    VERTICAL_BAR    EQU     0BAh
    HORIZONTAL_BAR  EQU     0CDh
    UPPER_LEFT      EQU     0C9h
    UPPER_RIGHT     EQU     0BBh
    LOWER_LEFT      EQU     0C8h
    LOWER_RIGHT     EQU     0BCh
    TOP_T_BAR       EQU     0CBh
    BOTTOM_T_BAR    EQU     0CAh
    TOP_TICK        EQU     0D1h
    BOTTOM_TICK     EQU     0CFh

	    extern   WRITE_PATTERN
		extern	 SEND_CRLF
	    extern   GOTO_XY
		extern	 WRITE_PHANTOM
	    extern   LINES_BEFORE_SECTOR
	    extern   SECTOR_OFFSET

		global 	INIT_SEC_DISP
    ;----------------------------------------------------------------------;
    ; This procedure initializes the half-sector display.		   			;
    ;									   									;
    ; Uses:	    WRITE_PATTERN, SEND_CRLF, DISP_HALF_SECTOR		  			;
    ;		    WRITE_TOP_HEX_NUMBERS, GOTO_XY, WRITE_PHANTOM	   			;
    ; Reads:	    TOP_LINE_PATTERN, BOTTOM_LINE_PATTERN		   			;
    ;		    LINES_BEFORE_SECTOR 				   						;
    ; Writes:	    SECTOR_OFFSET					   						;
    ;----------------------------------------------------------------------;
    INIT_SEC_DISP:
	    PUSH    DX
	    XOR     DL,DL		    		; Move cursor into position
	    MOV     DH,[LINES_BEFORE_SECTOR]
	    CALL    GOTO_XY
	    CALL    WRITE_TOP_HEX_NUMBERS
	    LEA     DX,TOP_LINE_PATTERN
	    CALL    WRITE_PATTERN
	    CALL    SEND_CRLF
	    XOR     DX,DX		    		; Start at the beginning of the sector
	    MOV     [SECTOR_OFFSET],DX	    ; Set sector offset to 0
	    CALL    DISP_HALF_SECTOR
	    LEA     DX,BOTTOM_LINE_PATTERN
	    CALL    WRITE_PATTERN
	    CALL    WRITE_PHANTOM	    	; Write the phantom cursor
	    POP     DX
	    RET

	    extern   WRITE_CHAR_N_TIMES
		extern   WRITE_HEX
		extern	 WRITE_CHAR
	    extern   WRITE_HEX_DIGIT
		extern	 SEND_CRLF
    ;----------------------------------------------------------------------;
    ; This procedure writes the index numbers (0 through F) at the top of  ;
    ; the half-sector display.						   						;
    ;									   									;
    ; Uses:	    WRITE_CHAR_N_TIMES, WRITE_HEX, WRITE_CHAR		   			;
    ;		    WRITE_HEX_DIGIT, SEND_CRLF				   					;
    ;----------------------------------------------------------------------;
    WRITE_TOP_HEX_NUMBERS:
	    PUSH    CX
	    PUSH    DX
	    MOV     DL,' '		    ; Write 9 spaces for left side
	    MOV     CX,9
	    CALL    WRITE_CHAR_N_TIMES
	    XOR     DH,DH		    ; Start with 0
    HEX_NUMBER_LOOP:
	    MOV     DL,DH
	    CALL    WRITE_HEX
	    MOV     DL,' '
	    CALL    WRITE_CHAR
	    INC     DH
	    CMP     DH,10h		    ; Done yest?
	    JB	    HEX_NUMBER_LOOP
	    MOV     DL,' '		    ; Write hex numbers over ASCII window
	    MOV     CX,2
	    CALL 	WRITE_CHAR_N_TIMES
	    XOR     DL,DL
    HEX_DIGIT_LOOP:
	    CALL    WRITE_HEX_DIGIT
	    INC     DL
	    CMP     DL,10h
	    JB	    HEX_DIGIT_LOOP
	    CALL    SEND_CRLF
	    POP     DX
	    POP     CX
	    RET

	    global  DISP_HALF_SECTOR
	    extern  SEND_CRLF
    ;----------------------------------------------------------------------;
    ; This procedure displays half a sector (256 BYTES) 		   			;
    ;									   									;
    ;	    DS:DX   Offset into sector, in bytes--should be multiple of 16 ;
    ;									   									;
    ; Uses:	    DISP_LINE, SEND_CRLF				   						;
    ;----------------------------------------------------------------------;
    DISP_HALF_SECTOR:
	    PUSH 	CX
	    PUSH 	DX
	    MOV 	CX,16			   ; Display 16 lines
    HALF_SECTOR:
	    CALL    DISP_LINE
	    CALL    SEND_CRLF
	    ADD     DX,16
	    LOOP    HALF_SECTOR
	    POP     DX
	    POP     CX
	    RET

	    global  DISP_LINE
	    extern   WRITE_HEX
	    extern   WRITE_CHAR
	    extern   WRITE_CHAR_N_TIMES
    ;----------------------------------------------------------------------;
    ; This procedure displays one line of data, or 16 bytes, first in hex, ;
    ; then in ASCII.							   							;
    ;									   									;
    ;	DS:DX	    Offset into sector, in bytes			   				;
    ;									   									;
    ; Uses:	    WRITE_CHAR, WRITE_HEX, WRITE_CHAR_N_TIMES		   			;
    ; Reads:	    SECTOR						   							;
    ;----------------------------------------------------------------------;
    DISP_LINE:
		    PUSH    BX
		    PUSH    CX
		    PUSH    DX
		    MOV     BX,DX		   	; Offset is more useful in Bx
		    MOV     DL,' '
		    MOV     CX,3		   	; Write 3 spaces before line
		    CALL    WRITE_CHAR_N_TIMES
						   			; Write offset in hex
		    CMP     BX,100h		   	; Is first digit a 1?
		    JB	    WRITE_ONE		; No, white space already in DL
		    MOV     DL,'1'		   	; Yes, then place'1' into DL for output
    WRITE_ONE:
		    CALL    WRITE_CHAR
		    MOV     DL,BL		   	; Copy lower byte into DL for hex output
		    CALL    WRITE_HEX
									; Write separator
		    MOV     DL,' '
		    CALL    WRITE_CHAR
		    MOV     DL,VERTICAL_BAR	; Draw left side box
		    CALL    WRITE_CHAR
		    MOV     DL,' '
		    CALL    WRITE_CHAR
						   			; Now write out 16 bytes
		    MOV     CX,16		  	; Dump 16 bytes
		    PUSH    BX			   	; Save the offset for ASCII_LOOP
    HEX_LOOP:
		    MOV     DL,SECTOR[BX]	; Get one byte
		    CALL    WRITE_HEX		; Dump this byte in hex
		    MOV     DL,' '		    ; Write a space between numbers
		    CALL    WRITE_CHAR
		    INC     BX
		    LOOP    HEX_LOOP

		    MOV     DL,VERTICAL_BAR	; Write separator
		    CALL    WRITE_CHAR
		    MOV     DL,' '		    ; Add another space before characters
		    CALL    WRITE_CHAR
		    MOV     CX,16
		    POP     BX			    ; Get back offset into sector
    ASCII_LOOP:
		    MOV     DL,SECTOR[BX]
		    CALL    WRITE_CHAR
		    INC     BX
		    LOOP    ASCII_LOOP

		    MOV     DL,' '		   ; Draw right side of box
		    CALL    WRITE_CHAR
		    MOV     DL,VERTICAL_BAR
		    CALL    WRITE_CHAR

		    POP     DX
		    POP     CX
		    POP     BX
		    RET


		    extern   SECTOR

    TOP_LINE_PATTERN:
		    DB	    ' ',7
		    DB	    UPPER_LEFT,1
		    DB	    HORIZONTAL_BAR,12
		    DB	    TOP_TICK,1
		    DB	    HORIZONTAL_BAR,11
		    DB	    TOP_TICK,1
		    DB	    HORIZONTAL_BAR,11
		    DB	    TOP_TICK,1
		    DB	    HORIZONTAL_BAR,12
		    DB	    TOP_T_BAR,1
		    DB	    HORIZONTAL_BAR,18
		    DB	    UPPER_RIGHT,1
		    DB	    0

    BOTTOM_LINE_PATTERN:
		    DB	    ' ',7
		    DB	    LOWER_LEFT,1
		    DB	    HORIZONTAL_BAR,12
		    DB	    BOTTOM_TICK,1
		    DB	    HORIZONTAL_BAR,11
		    DB	    BOTTOM_TICK,1
		    DB	    HORIZONTAL_BAR,11
		    DB	    BOTTOM_TICK,1
		    DB	    HORIZONTAL_BAR,12
		    DB	    BOTTOM_T_BAR,1
		    DB	    HORIZONTAL_BAR,18
		    DB	    LOWER_RIGHT,1
		    DB	    0

