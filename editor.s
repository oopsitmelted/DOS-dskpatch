        [bits 16]
            extern   SECTOR
            extern   SECTOR_OFFSET
            extern   PHANTOM_CURSOR_X
            extern   PHANTOM_CURSOR_Y

    ;----------------------------------------------------------------------;
    ; This procedure writes one byte to SECTOR, at the memory location     ;
    ; pointed to by the phantom cursor.                                    ;
    ;                                                                      ;
    ;       DL      Byte to write to SECTOR                                ;
    ;                                                                      ;
    ; The offset is calculated by                                          ;
    ; OFFSET = SECTOR_OFFSET + (16 * PHANTOM_CURSOR_Y) + PHANTOM_CURSOR_X  ;
    ;                                                                      ;
    ; Reads:    PHANTOM_CURSOR_X, PHANTOM_CURSOR_Y, SECTOR_OFFSET          ;
    ; Writes:   SECTOR                                                     ;
    ;----------------------------------------------------------------------;
    WRITE_TO_MEMORY:
            PUSH    AX
            PUSH    BX
            PUSH    CX
            MOV     BX,[SECTOR_OFFSET]
            MOV     AL,[PHANTOM_CURSOR_Y]
            XOR     AH,AH
            MOV     CL,4                    ; Multiply PHANTOM_CURSOR_Y by 16
            SHL     AX,CL
            ADD     BX,AX                   ; BX = SECTOR_OFFSET + (16 * Y)
            MOV     AL,[PHANTOM_CURSOR_X]
            XOR     AH,AH
            ADD     BX,AX                   ; That's the address!
            MOV     SECTOR[BX],DL           ; Now, store the byte
            POP     CX
            POP     BX
            POP     AX
            RET


            global  EDIT_BYTE
            extern  SAVE_REAL_CURSOR, RESTORE_REAL_CURSOR, MOV_TO_HEX_POSITION, MOV_TO_ASCII_POSITION
            extern  WRITE_PHANTOM, WRITE_PROMPT_LINE, CURSOR_RIGHT, WRITE_HEX, WRITE_CHAR
            extern  EDITOR_PROMPT
    ;----------------------------------------------------------------------;
    ; This procedure changes a byte in memory and on the screen.           ;
    ;                                                                      ;
    ;       DL      Byte to write into SECTOR, and change on screen        ;
    ;                                                                      ;
    ; Uses:         SAVE_REAL_CURSOR, RESTORE_REAL_CURSOR                  ;
    ;               MOV_TO_HEX_POSITION, MOV_TO_ASCII_POSITION             ;
    ;               WRITE_PHANTOM, WRITE_PROMPT_LINE, CURSOR_RIGHT         ;
    ;               WRITE_HEX, WRITE_CHAR, WRITE_TO_MEMORY                 ;
    ; Reads:        EDITOR_PROMPT                                          ;
    ;----------------------------------------------------------------------;
    EDIT_BYTE:
            PUSH    DX
            CALL    SAVE_REAL_CURSOR
            CALL    MOV_TO_HEX_POSITION     ; Move to the hex number in the
            CALL    CURSOR_RIGHT            ; hex window
            CALL    WRITE_HEX               ; Write the new number
            CALL    MOV_TO_ASCII_POSITION   ; Move to the char. in the ASCII window
            CALL    WRITE_CHAR              ; Write the new character
            CALL    RESTORE_REAL_CURSOR     ; Move cursor back where it belongs
            CALL    WRITE_PHANTOM           ; Rewrite the phantom cursor
            CALL    WRITE_TO_MEMORY         ; Save this new byte in SECTOR
            LEA     DX,EDITOR_PROMPT
            CALL    WRITE_PROMPT_LINE
            POP     DX
            RET