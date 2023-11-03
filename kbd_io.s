[bits 16]
    BS      EQU     8                       ;Backspace character
    CR      EQU     13                      ;Carriage-return character
    ESK     EQU     27                      ;Escape character

            global  STRING_TO_UPPER
    ;-----------------------------------------------------------------------;
    ; This procedure converts the string, using the DOS format for strings, ;
    ; to all uppercase letters.                                             ;
    ;                                                                       ;
    ;       DS:DX   Adress of string buffer                                 ;
    ;-----------------------------------------------------------------------;
    STRING_TO_UPPER:
            PUSH    AX
            PUSH    BX
            PUSH    CX
            MOV     BX,DX
            INC     BX                      ;Point to character count
            MOV     CL,[BX]                 ;Character count in 2nd byte of buffer
            XOR     CH,CH                   ;Clear upper byte count
    UPPER_LOOP:
            INC     BX                      ;Point to next character in buffer
            MOV     AL,[BX]
            CMP     AL,'a'                  ;See if it is a lowercase letter
            JB      NOT_LOWER               ;Nope
            CMP     AL,'z'
            JA      NOT_LOWER
            ADD     AL,'A'-'a'              ;Convert to uppercase letter
            MOV     [BX],AL
    NOT_LOWER:
            LOOP    UPPER_LOOP
            POP     CX
            POP     BX
            POP     AX
            RET

    ;----------------------------------------------------------------------;
    ; This procedure converts a character from ASCII (hex) to a nibble (4  ;
    ; bits).                                                               ;
    ;           AL      Character to convert                               ;
    ; Returns:  AL      Nibble                                             ;
    ;           CF      Set for error, cleared otherwise                   ;
    ;----------------------------------------------------------------------;

    CONVERT_HEX_DIGIT:
            CMP     AL,'0'                  ; Is it a legal digit?
            JB      BAD_DIGIT               ; Nope
            CMP     AL,'9'                  ; Not sure yet
            JA      TRY_HEX                 ; Might be hex digit
            SUB     AL,'0'                  ; Is decimal digit, convert to nibble
            CLC                             ; Clear the carry, no error
            RET
    TRY_HEX:
            CMP     AL,'A'                  ; Not sure yest
            JB      BAD_DIGIT               ; Not hex
            CMP     AL,'F'                  ; Not sure yet
            JA      BAD_DIGIT               ; Not hex
            SUB     AL,'A'- 10              ; Is hex convert to nibble
            CLC                             ; Clear the carry, no error
            RET
    BAD_DIGIT:
            STC                             ; Set the carry, error
            RET

            global  HEX_TO_BYTE
    ;----------------------------------------------------------------------;
    ; This procedure converts the two characters at DS:DX  from hex to one ;
    ; byte .                                                               ;
    ;                                                                      ;
    ;           DS:DX   Adress of two characters for hex number            ;
    ; Returns:                                                             ;
    ;           AL      Byte                                               ;
    ;           CF      Set for error, clear if no error                   ;
    ;                                                                      ;
    ; Uses:             CONVERT_HEX_DIGIT
    ;----------------------------------------------------------------------;

    HEX_TO_BYTE:
            PUSH    BX
            PUSH    CX
            MOV     BX,DX                   ; Put adress in BX for indirect addr
            MOV     AL,[BX]                 ; Get first digit
            CALL    CONVERT_HEX_DIGIT
            JC      BAD_HEX                 ; Bad hex digit if carry set
            MOV     CX,4                    ; Now multiply by 16
            SHL     AL,CL
            MOV     AH,AL                   ; Retain a copydow
            INC     BX                      ; Get second digit
            MOV     AL,[BX]
            CALL    CONVERT_HEX_DIGIT
            JC      BAD_HEX                 ; Bad hex digit if carry set
            OR      AL,AH                   ; Combine two nibbles
            CLC                             ; Clear carry for no error
    DONE_HEX:
            POP     CX
            POP     BX
            RET
    BAD_HEX:
            STC                             ; Set carry for error
            JMP     DONE_HEX

            global  READ_STRING
            extern  WRITE_CHAR
    ;----------------------------------------------------------------------;
    ; This procedure performs a function very similar to the DOS 0Ah       ;
    ; function. But this function will return a special character if a     ;
    ; function or keypad key is pressed--no return for these keys. And     ;
    ; ESK will erase the input and start over again.                       ;
    ;                                                                      ;
    ;       DS:DX   Address for keyboard buffer. The first byte must       ;
    ;               contain the maximum number of characters to read (plus ;
    ;               one for the return). And the second byte will be used  ;
    ;               by this procedure to return the number of characters   ;
    ;               actually read.                                         ;
    ;                       0       No characters read                     ;
    ;                       -1      One special character read             ;
    ;                       otherwise number actually read (not including  ;
    ;                               enter key)                             ;
    ; Uses:         BACK_SPACE, WRITE_CHAR                                 ;
    ;----------------------------------------------------------------------;
    READ_STRING:
            PUSH    AX
            PUSH    BX
            PUSH    SI
            MOV     SI,DX                   ; Use SI for index register and
    START_OVER:
            MOV     BX,2                    ; BX for offset to beginning of buffer
            MOV     AH,7                    ; Call for input with no checking
            INT     21h                     ; for CTRL - BREAK and no echo
            OR      AL,AL                   ; Is character extended ASCII?
            JZ      EXTENDED                ; Yes, read the extended character
    NOT_EXTENDED:                           ; Entnd char is error unless buf empty
            CMP     AL,CR                   ; Is this a carriage return?
            JE      END_INPUT               ; Yes, we are done with input
            CMP     AL,BS                   ; Is it a backspace character
            JNE     NOT_BS                  ; Nope
            CALL    BACK_SPACE              ; Yes, delete character
            CMP     BL,2                    ; Is buffer empty?
            JE      START_OVER              ; Yes, can now read extended ASCII again
            JMP     READ_NEXT_CHAR          ; No, continue reading normal characters
    NOT_BS: CMP     AL,ESK                  ; Is it an ESK--purge buffer?
            JE      PURGE_BUFFER            ; Yes, then purge the buffer
            CMP     BL,[SI]                 ; Check to see if buffer is full
            JA      BUFFER_FULL             ; Buffer is full
            MOV     [SI+BX],AL              ; Else save char in buffer
            INC     BX                      ; Point to next free character in buffer
            PUSH    DX
            MOV     DL,AL                   ; Echo character to screen
            CALL    WRITE_CHAR
            POP     DX
    READ_NEXT_CHAR:
            MOV     AH,7
            INT     21h
            OR      AL,AL                   ; An extended ASCII char is not valid
                                            ; when the buffer is not empty
            JNE     NOT_EXTENDED            ; Char is valid
            MOV     AH,7
            INT     21h                     ; Throw out the extended character

    ;----------------------------------------------;
    ; Signal an error condition by sending a beep  ;
    ; character to the display; chr$(7).           ;
    ;----------------------------------------------;
    SIGNAL_ERROR:
            PUSH    DX
            MOV     DL,7                     ; Sound the bell by writing chr$(7)
            MOV     AH,2
            INT     21h
            POP     DX
            JMP     READ_NEXT_CHAR   ; Now read next character

    ;------------------------------------------------;
    ; Empty the string buffer and erase all the      ;
    ; characters displayed on the secreen.           ;
    ;------------------------------------------------;
    PURGE_BUFFER:
            PUSH    CX
            MOV     CL,[SI]                 ; Backspace over maximum number of
            XOR     CH,CH
    PURGE_LOOP:                             ; characters in buffer. BACK_SPACE
            CALL    BACK_SPACE              ; will keep the cursor from moving too
            LOOP    PURGE_LOOP              ; far back
            POP     CX
            JMP     START_OVER              ; Can now read extended ASCII characters
                                            ; since the buffer is empty

    ;-----------------------------------------------;
    ; The buffer was full, so can't read another    ;
    ; character. Send a beep to alert use of        ;
    ; buffer-full condition.                        ;
    ;-----------------------------------------------;
    BUFFER_FULL:
            JMP     SIGNAL_ERROR      ; If buffer full, just beep

    ;----------------------------------------------;
    ; Read the extended ASCII code and place this  ;
    ; in buffer as the only character, then        ;
    ; return -1 as the number opf characters read. ;
    ;----------------------------------------------;
    EXTENDED:                               ; Read an extended ASCII code
            MOV     AH,7
            INT     21h
            MOV     [SI+2],AL               ; Place just this char in buffer
            MOV     BL,0FFh                 ; Num chars read = -1 for special
            JMP     END_STRING

    ;----------------------------------------------;
    ; Save the count of the number of characters   ;
    ; read and return                              ;
    ;----------------------------------------------;
    END_INPUT:                              ; Done with input
            SUB     BL,2                    ; Count of characters read
    END_STRING:
            MOV     [SI+1],BL               ; Return number of chars read
            POP     SI
            POP     BX
            POP     AX
            RET

            global  READ_BYTE

    ;----------------------------------------------------------------------;
    ; This procedure reads either a single ASCII character or a two-digit  ;
    ; hex number. This is just a test version of READ_BYTE.                ;
    ;                                                                      ;
    ; Returns byte in       AL      Character code (unless AH=0)           ;
    ;                       AH      1 if read ASCII char                   ;
    ;                               0 if no characters read                ;
    ;                               -1 if read a special key               ;
    ;                                                                      ;
    ; Uses:     HEX_TO_BYTE, STRING_TO_UPPER, READ_STRING                  ;
    ; Reads:    KEYBOARD_INPUT, etc.                                       ;
    ; Writes:   KEYBOARD_INPUT, etc.                                       ;
    ;----------------------------------------------------------------------;
    READ_BYTE:
            PUSH    DX
            MOV     byte [CHAR_NUM_LIMIT],3        ; Allow only two characters (plus Enter)
            LEA     DX,KEYBOARD_INPUT
            CALL    READ_STRING
            CMP     byte [NUM_CHARS_READ],1        ; See how many characters
            JE      ASCII_INPUT             ; Just one, treat as ASCII character
            JB      NO_CHARACTERS           ; Only Enter key hit
            CMP     byte [NUM_CHARS_READ],0FFh   ; Special function key?
            JE      SPECIAL_KEY             ; Yes
            CALL    STRING_TO_UPPER         ; No, convert string to uppercase
            LEA     DX,CHARS                ; Adress of string to convert
            CALL    HEX_TO_BYTE             ; Convert string from hex to byte
            JC      NO_CHARACTERS           ; Error, so return 'no characters read'
            MOV     AH,1                    ; Signal read one character
    DONE_READ:
            POP DX
            RET
    NO_CHARACTERS:
            XOR     AH,AH                   ; Set to 'no characters read'
            JMP     DONE_READ
    ASCII_INPUT:
            MOV     AL,[CHARS]                ; Load character read
            MOV     AH,1                    ; Signal read one character
            JMP     DONE_READ
    SPECIAL_KEY:
            MOV     AL,CHARS[0]             ; Return the scan code
            MOV     AH,0FFh                 ; Signal special key with -1
            JMP     DONE_READ

            global  READ_DECIMAL
    ;----------------------------------------------------------------------;
    ; This procedure takes the output buffer of READ_STRING and converts   ;
    ; the string of decimal digits to a word.                              ;
    ;                                                                      ;
    ;               AX      Word converted from decimal                    ;
    ;               CF      Set if error, clear if no error                ;
    ;                                                                      ;
    ; Uses:     READ_STRING                                                ;
    ; Reads:    KEYBOARD_INPUT, etc.                                       ;
    ; Writes:   KEYBOARD_INPUT, etc.                                       ;
    ;----------------------------------------------------------------------;
    READ_DECIMAL:
            PUSH    BX
            PUSH    CX
            PUSH    DX
            MOV     byte [CHAR_NUM_LIMIT],6        ; Max number is 5 digits (65535)
            LEA     DX,KEYBOARD_INPUT
            CALL    READ_STRING
            MOV     CL,[NUM_CHARS_READ]       ; Get number of characters read
            XOR     CH,CH                   ; Set upper byte of count to 0
            CMP     CL,0                    ; Return error if no characters read
            JLE     BAD_DECIMAL_DIGIT       ; No chars read, signal error
            XOR     AX,AX                   ; Start with number set to 0
            XOR     BX,BX                   ; Start at beginning of string
    CONVERT_DIGIT:
            MOV     DX,10                   ; Multiply number by 10
            MUL     DX                      ; Multiply AX by 10
            JC      BAD_DECIMAL_DIGIT       ; CF set if MUL overflowed one word
            MOV     DL,CHARS[BX]            ; Get the next digit
            SUB     DL,'0'                  ; And convert to a nibble (4 bits)
            JS      BAD_DECIMAL_DIGIT       ; Bad digit if < 0
            CMP     DL,9                    ; Is this a bad digit?
            JA      BAD_DECIMAL_DIGIT       ; Yes
            ADD     AX,DX                   ; No, so add it to number
            INC     BX                      ; Point to next character
            LOOP    CONVERT_DIGIT           ; Get the next digit
    DONE_DECIMAL:
            POP     DX
            POP     CX
            POP     BX
            RET
    BAD_DECIMAL_DIGIT:
            STC                             ; Set carry to signal error
            JMP     DONE_DECIMAL

            global  BACK_SPACE
            extern  WRITE_CHAR
    ;----------------------------------------------------------------------;
    ; This procedure deletes characters, one at a time, from the buffer and;
    ; the screen when the buffer is not empty.  BACK_SPACE simply returns  ;
    ; when the buffer is empty.                                            ;
    ;                                                                      ;
    ;       DS:SI+BX        Most recent character still in buffer          ;
    ;                                                                      ;
    ; Uses:     WRITE_CHAR                                                 ;
    ;----------------------------------------------------------------------;
    BACK_SPACE:
            PUSH    AX
            PUSH    DX
            CMP     BX,2                    ; Is buffer empty?
            JE      END_BS                  ; Yes, read the next character
            DEC     BX                      ; Remove one character from buffer
            MOV     AH,2                    ; Remove character from screen
            MOV     DL,BS
            INT     21h
            MOV     DL,20h                  ; Write space there
            CALL    WRITE_CHAR
            MOV     DL,BS                   ; Back up again
            INT     21h
    END_BS: POP     DX
            POP     AX
            RET

    KEYBOARD_INPUT:
    CHAR_NUM_LIMIT  DB      0               ; Length of input buffer
    NUM_CHARS_READ  DB      0               ; Number of characters read
    CHARS           DB      80 DUP (0)      ; A buffer for keyboard input