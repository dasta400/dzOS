;******************************************************************************
; kernel.conv.asm
;
; Kernel's Conversion routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 21 Jun 2022
;******************************************************************************
; CHANGELOG
;     -
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2019-2022 David Asta
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; -----------------------------------------------------------------------------

;==============================================================================
; Code Conversion Routines
;==============================================================================

;------------------------------------------------------------------------------
KRN_ASCIIADR_TO_HEX:
; Convert address (or any 2 bytes) from hex ASCII to its hex value
; (e.g. hex ASCII = 32 35 37 30 => hex value 2570)
;    IN <= IX = address of 1st digit
;    OUT => HL = converted hex value
;
        ; Convert 1st byte
        ld      H, (IX)                 ; H = hex ASCII value of 1st digit
        ld      L, (IX + 1)             ; L = hex ASCII value of 2nd digit
        call    F_KRN_ASCII_TO_HEX      ; A = hex value of HL
        push    AF                      ; Backup 1st converted byte
        ; Convert 2nd byte
        ld      H, (IX + 2)             ; H = hex ASCII value of 1st digit
        ld      L, (IX + 3)             ; L = hex ASCII value of 2nd digit
        call    F_KRN_ASCII_TO_HEX      ; A = hex value of HL
        ; Store converted bytes into HL
        pop     HL                      ; Restore 1st converted byte
        ld      L, A                    ; 2nd converted byte
        ret

;------------------------------------------------------------------------------
KRN_ASCII_TO_HEX:
; Converts two ASCII characters (representing two hexadecimal digits)
; to one byte in Hexadecimal
; (e.g. 0x33 and 0x45 are converted into 3E)
;    IN <= H = Most significant ASCII digit
;          L = Less significant ASCII digit
;    OUT => A = Converted binary data
        ld      A, L                    ; get low character
        call    a2hex                   ; convert it to hexadecimal
        ld      B, A                    ; save hex value in b
        ld      A, H                    ; get high character
        call    a2hex                   ; convert it to hexadecimal
        rrca                            ; shift hex value to upper 4 bits
        rrca
        rrca
        rrca
        or      B                       ; or in low hex value
        ret
a2hex: ; convert ascii digit to a hex digit
        sub     '0'                     ; subtract ascii offset
        cp      10                      ; is it a decimal digit?
        jr      c, a2hex1               ; yes, then return
        sub     7                       ; no, then subtract offset for letters
a2hex1:
        ret
;------------------------------------------------------------------------------
KRN_HEX_TO_ASCII:
; Converts one byte in Hexadecimal to two ASCII printable characters
; (e.g. 0x3E is converted into 33 and 45, which are the ASCII values of 3 and E)
;    IN <= A = binary data
;    OUT => H = Most significant ASCII digit
;            L = Less significant ASCII digit
        ; Convert High Nibble
        ld      B, A                    ; save original binary value
        and     0F0h                    ; get high nibble
        rrca                            ; move high nibble to low nibble
        rrca
        rrca
        rrca
        call    nascii                  ; convert high nibble to ASCII
        ld      H, A                    ; return high nibble in H
        ; Convert Low Nibble
        ld      A, B
        and     0Fh                     ; get low nibble
        call    nascii                  ; convert low nibble to ASCII
        ld      L, A                    ; return low nibble in H
        ret
nascii:
        cp      10
        jr      c, nas1                 ; jump if high nibble < 10
        add     A, 7                    ; else add 7 so after adding '0' the
                                        ; character will be in 'A'..'F'
nas1:
        add     A, '0'                  ; add ASCII 0 to make a character
        ret
;------------------------------------------------------------------------------
KRN_BCD_TO_BIN:
; Converts 1 byte of BCD to 1 byte of hexadecimal
; (e.g. 12 is converted into 0x0C)
; (c) 1993 by McGraw-Hill, Inc. (Z80 Assembly Language Subroutines)
; IN <= A = BCD
; OUT => H = Hexadecimal

        ; MULTIPLY UPPER NIBBLE BY 10 AND SAVE IT
        ;  UPPER NIBBLE * 10 = UPPER NIBBLE * (8 + 2)
        ld      B, A                    ; SAVE ORIGINAL BCD VALUE IN B
        and     $0F0                    ; MASK OFF UPPER NIBBLE
        rrca                            ; SHIFT RIGHT 1 BIT
        ld      C, A                    ; C = UPPER NIBBLE * 8
        rrca                            ; SHIFT RIGHT 2 MORE TIMES
        rrca                            ; A = UPPER NIBBLE * 2
        add     A, C
        ld      C, A                    ; C = UPPER NIBBLE * (8+2)

        ; GET LOWER NIBBLE AND ADD IT TO THE
        ;  BINARY EQUIVALENT OF THE UPPER NIBBLE
        ld      A, B                    ; GET ORIGINAL VALUE BACK
        and     $0F                     ; MASK OFF UPPER NIBBLE
        add     A, C                    ; ADD TO BINARY UPPER NIBBLE
        ret

;------------------------------------------------------------------------------
KRN_BIN_TO_BCD4:
; Converts 1 byte of unsigned integer hexadecimal to 4-digit BCD
; (e.g. 0x80 is converted into H = 01, L = 28)
; IN <= A = unsigned integer
; OUT => H = hundreds digit
;        L = tens digit
        ld      H, 255                  ; counter. Start at -1
hundreds:
        inc     H                       ; add 1 to quotient
        sub     100                     ; subtract 100
        jr      nc, hundreds            ; still positive? Yes, loop again
        add     A, 100                  ; no, add the last 100 back

        ld      L, 255                  ; counter. Start at -1
tens:
        inc     L                       ; add 1 to quotient
        sub     10                      ; subtratc 10
        jr      nc, tens                ; still positive? Yes, loop again
        add     A, 10                   ; no, add the last 10 back

        ld      C, A                    ; save units digit in C
        ld      A, L
        rlca                            ; move the tens to high nibble of A
        rlca
        rlca
        rlca
        or      C                       ; or the units digit

        ld      L, A
        ret
;------------------------------------------------------------------------------
KRN_BIN_TO_BCD6:
; Converts 2 bytes of unsigned integer decimal to 6-digit BCD
; (e.g. 0xFFFF is converted into C = 6, D = 55, E = 35)
; https://de.comp.lang.assembler.x86.narkive.com/EjY9sEbE/z80-binary-to-ascii
;    IN <= HL = unsigned integer
;    OUT => CDE = 6-digit BCD
        ld      BC, 4096                ; counter
        ld      DE, 0
bin2bcdloop:
        add     HL, HL
        ld      A, E
        adc     A, A
        daa
        ld      E, A
        ld      A, D
        adc     A, A
        daa
        ld      D, A
        ld      A, C
        adc     A, A
        daa
        ld      C, A
        djnz    bin2bcdloop             ; all bits done? No, continue with more bits
        ret                             ; yes, exit routine
;------------------------------------------------------------------------------
KRN_BCD_TO_ASCII:
; Converts 6-digit BCD to hex ASCII string in a memory location
; (e.g. 512 is converted into 30 30 30 35 31 32)
; https://de.comp.lang.assembler.x86.narkive.com/EjY9sEbE/z80-binary-to-ascii
; IN <= DE = pointer to where the string will be stored
;       C = first 2 digits of 6-digit BCD to convert
;       H = next two digits of 6-digit BCD to convert
;       L = last 2 digits of 6-digit BCD to convert
; OUT => DE = pointer past end of ASCII string
        ld      A, C
        call    uppernibble
        ld      A, C
        call    lowernibble
        ld      A, H
        call    uppernibble
        ld      A, H
        call    lowernibble
        ld      A, L
        call    uppernibble
        ld      A, L
        jr      lowernibble
uppernibble:
        rra                             ; move high nibble to low nibble
        rra
        rra
        rra
lowernibble:
        and     0Fh                     ; get low nibble
        add     A, 90h
        daa
        adc     A, 40h
        daa
        ld      (DE), A
        inc     DE
        ret
;------------------------------------------------------------------------------
KRN_BITEXTRACT:
; Bit Extraction
; Extracts a group of bits from a byte and returns the group in the LSB position
; IN <= E = byte from where to extract
;        D = number of bits to extract
;        A = start extraction at bit number
; OUT => A = extracted group of bits
        and     00000111b               ; only allow 0 through 7
        jr      z, bitex                ; if shifted not needed, then start extraction
        ld      B, A                    ; B = start extraction at bit number
bitexshift:
        srl     E                       ; shift E right 1-bit position
        djnz    bitexshift              ; continue shifting until reached start position
bitex:
        ; if bits to extract is 0, then exit routine
        ld      A, D
        or      A
        ret     z
        dec     A
        and     00000111b               ; only allow 0 through 7
        ld      C, A                    ; BC = index into mask array
        ld      B, 0
        ld      HL, maskarray           ; HL = base address of the mask array
        add     HL, BC                  ; position inside the mask array
        ld      A, E                    ; A = byte to extract
        and     (HL)                    ; mask off unwanted bits
        ret

maskarray:
        .BYTE   00000001b
        .BYTE   00000011b
        .BYTE   00000111b
        .BYTE   00001111b
        .BYTE   00011111b
        .BYTE   00111111b
        .BYTE   01111111b
        .BYTE   11111111b

;------------------------------------------------------------------------------
KRN_BIN_TO_ASCII:
; Convert a 16-bit signed binary number (-32768 to 32767) to ASCII data
; (e.g. 32767 is converted into 33 32 37 36 37)
; (c) 1993 by McGraw-Hill, Inc. (Z80 Assembly Language Subroutines)
; IN <= D = High byte of value to convert
;       E = Low byte of value to convert
; OUT => ASCII data in SYSVARS.CLI_buffer_pgm
;        The 1st byte of the buffer is the length, followed by the characters
;
        ld      HL, CLI_buffer_pgm
        ; SAVE PARAMETERS
        ld      (CLI_buffer_pgm + 6), HL    ; STORE THE BUFFER POINTER
        ex      DE, HL
        ld      A, 0
        ld      (CLI_buffer_pgm + 8), A     ; CURRENT BUFFER LENGTH IS 0
        ld      A, H
        ld      (CLI_buffer_pgm + 9), A     ; SAVE SIGN OF VALUE
        or      A                           ; SET FLAGS FROM VALUE
        jp      p, bn2dec_cnvert            ; JUMP IF VALUE IS POSITIVE
        ex      DE, HL                      ; ELSE TAKE ABSOLUTE VALUE (0 - VALUE)
        ld      HL, 0
        or      A                           ; CLEAR CARRY
        sbc     HL, DE                      ; SUBTRACT VALUE FROM 0

        ; CONVERT VALUE TO A STRING
bn2dec_cnvert:
        ; HL = HL DIV 10 (DIVIDEND, QUOTIENT)
        ; DE = HL MOD 10 (REMAINDER)
        ld      E, 0                        ; REMAINDER = 0
        ld      B, 16                       ; 16 BITS IN DIVIDEND
        or      A                           ; CLEAR CARRY TO START
bn2dec_dvloop:
        ; SHIFT THE NEXT BIT OF THE QUOTIENT INTO BIT 0 OF THE DIVIDEND
        ; SHIFT NEXT MOST SIGNIFICANT BIT OF DIVIDEND INTO
        ;   LEAST SIGNIFICANT BIT OF REMAINDER
        ; HL HOLDS BOTH DIVIDEND AND QUOTIENT. QUOTIENT IS SHIFTED
        ;   IN AS THE DIVIDEND IS SHIFTED OUT
        ; E IS THE REMAINDER
    
        ; DO A 24-BIT SHIFT LEFT, SHIFTING
        ;   CARRY TO L, L TO H, H TO E
        rl      L                           ; CARRY (NEXT BIT OF QUOTIENT) TO BIT 0
        rl      H                           ; SHIFT HIGH BYTE
        rl      E                           ; SHIFT NEXT BIT OF DIVIDEND

        ; IF REMAINDER IS 10 OR MORE, NEXT BIT OF
        ;   QUOTIENT IS 1 (THIS BIT IS PLACED IN CARRY)
        ld      A, E
        sub     10                          ; SUBTRACT 10 FROM REMAINDER
        ccf                                 ; COMPLEMENT CARRY
                                            ;   (THIS IS NEXT BIT OF QUOTIENT)
        jr      nc, bn2dec_deccnt           ; JUMP IF REMAINDER IS LESS THAN 10
        ld      E, A                        ; OTHERWISE REMAINDER = DIFFERENCE
                                            ;   BETWEEN PREVIOUS REMAINDER AND 10
bn2dec_deccnt:
        djnz    bn2dec_dvloop               ; CONTINUE UNTIL ALL BITS ARE DONE

        ; SHIFT LAST CARRY INTO QUOTIENT
        rl      L                           ; LAST BIT OF QUOTIENT TO BIT 0
        rl      H

        ; INSERT THE NEXT CHARACTER IN ASCII
bn2dec_chins:
        ld      A, E
        add     A, '0'                      ; CONVERT 0...9 TO ASCII '0'...'9'
        call    bn2dec_insert

        ; IF QUOTIENT IS NOT 0 THEN KEEP DIVIDING
        ld      A, H
        or      L
        jr      nz, bn2dec_cnvert
bn2dec_exit:
        ld      A, (CLI_buffer_pgm + 9)
        or      A
        jp      p, bn2dec_pos               ; BRANCH IF ORIGINAL VALUE WAS POSITIVE
        ld      A, '-'                      ; ELSE
        call    bn2dec_insert               ;   PUT A MINUS SIGN IN FRONT
bn2dec_pos:
        ret                                 ; RETURN
bn2dec_insert:
        push    HL                          ; SAVE HL
        push    AF                          ; SAVE CHARACTER TO INSERT
    
        ; MOVE ENTIRE BUFFER UP 1 BYTE IN MEMORY
        ld      HL, (CLI_buffer_pgm + 6)    ; GET BUFFER POINTER
        ld      D, H                        ; HL = SOURCE (CURRENTR END OF BUFFER)
        ld      E, L
        inc     DE                          ; DE = DESTINATION (CURRENT END + 1)
        ld      (CLI_buffer_pgm + 6), DE    ; STORE NEW BUFFER POINTER
        ld      A, (CLI_buffer_pgm + 8)
        or      A                           ; TEST FOR CURLEN = 0
        jr      z, bn2dec_exitmr            ; JUMP IF ZERO (NOTHING TO MOVE,
                                            ;   JUST STORE THE CHARACTER)
        ld      C, A                        ; BC = LOOP COUNTER
        ld      B, 0
        lddr                                ; MOVE ENTIRE BUFFER UP 1 BYTE
bn2dec_exitmr:
        ld      A, (CLI_buffer_pgm + 8)     ; INCREMENT CURRENT LENGTH By 1
        inc     A
        ld      (CLI_buffer_pgm + 8), A
        ld      (HL), A                     ; UPDATE LENGTH BYTE OF BUFFER
        ex      DE, HL                      ; HL POINTS TO FIRST CHARACTER IN BUFFER
        pop	AF                              ; GET CHARACTER TO INSERT
        ld      (HL), A                     ; INSERT CHARACTER AT FRONT OF BUFFER
        pop	HL                              ; RESTORE HL
        ret

;------------------------------------------------------------------------------
KRN_DEC_TO_BIN:
; Convert an ASCII string consisting of the length of the number (in bytes),
;   a possible ASCII - or + sign, and a series of ASCII digits to two bytes
;   of binary data. Note that the length is an ordinary binary number, not an
;   ASCII number.
; (e.g. 33 32 37 36 37 is converted into 7FFF)
; (c) 1993 by McGraw-Hill, Inc. (Z80 Assembly Language Subroutines)
; IN <= HL = address of input buffer
; OUT => HL = converted two bytes of binary data
;
        ; INITIALIZE - SAVE LENGTH, CLEAR SIGN AND VALUE
        ld      A, (HL)                     ; SAVE LENGTH IN B
        ld      B, A
        inc     HL                          ; POINT TO BYTE AFTER LENGTH
        sub     A
        ld      (tmp_byte), A               ; ASSUME NUMBER IS POSITIVE
        ld      DE, 0                       ; START WITH VALUE = 0

        ; CHECK FOR EMPTY BUFFER
        or      B                           ; IS BUFFER LENGTH ZERO?
        jr      z, dec2bn_erexit                   ; YES, EXIT WITH VALUE = 0

        ; CHECK FOR MINUS OR PLUS SIGN IN FRONT
dec2bn_init1:
        ld      A, (HL)                     ; GET FIRST CHARACTER
        cp      '-'                         ; IS IT A MINUS SIGN?
        jr      nz, dec2bn_plus             ; NO, BRANCH
        ld      A, $0FF
        ld      (tmp_byte), A               ; YES, MAKE SIGN OF NUMBER NEGATIVE
        jr      dec2bn_skip

dec2bn_plus:
        cp      '+'                         ; IS FIRST CHARACTER A PLUS SIGN?
        jr      nz, dec2bn_chkdig           ; NO, START CONVERSION
dec2bn_skip:
        inc     HL                          ; SKIP OVER THE SIGN BYTE
        dec     B                           ; DECREMENT COUNT
        jr      z, dec2bn_erexit                   ; ERROR EXIT IF ONLY A SIGN IN BUFFER

        ; CONVERSION LOOP
        ;  CONTINUE UNTIL THE BUFFER IS EMPTY
        ;  OR A NON-NUMERIC CHARACTER IS FOUND
dec2bn_cnvert:
        ld      A, (HL)                     ; GET NEXT CHARACTER
dec2bn_chkdig:
        sub     '0'
        jr      c, dec2bn_erexit                   ; ERROR IF < '0' (NOT A DIGIT)
        cp      9 + 1
        jr      nc, dec2bn_erexit                  ; ERROR IF > '9' (NOT A DIGIT)
        ld      C, A                        ; CHARACTER IS DIGIT, SAVE IT

        ; VALID DECIMAL DIGIT SO
        ;   VALUE := VALUE * 10
        ;    = VALUE * (8 + 2)
        ;    = (VALUE * 8) + (VALUE * 2)
        push    HL                          ; SAVE BUFFER POINTER
        ex      DE, HL                      ; HL = VALUE
        add     HL, HL                      ; * 2
        ld      E, L                        ; SAVE TIMES 2 IN DE
        ld      D, H
        add     HL, HL                      ; * 4
        add     HL, HL                      ; * 8
        add     HL, DE                      ; VALUE = VALUE * (8 + 2)

        ; ADD IN THE NEXT DIGIT
        ;  VALUE := VALUE + DIGIT
        ld      E, C                        ; MOVE NEXT DIGIT TO E
        ld      D, 0                        ;  HIGH BYTE IS 0
        add     HL, DE                      ; ADD DIGIT TO VALUE
        ex      DE, HL                      ; DE = VALUE
        pop     HL                          ; POINT TO NEXT CHARACTER
        inc     HL
        djnz    dec2bn_cnvert               ; CONTINUE CONVERSION

        ; CONVERSION IS COMPLETE, CHECK SIGN
        ex      DE, HL                      ; HL = VALUE
        ld      A, (tmp_byte)
        or      A
        jr      z, dec2bn_okexit            ; JUMP IF THE VALUE WAS POSITIVE
        ex      DE, HL                      ; ELSE REPLACE VALUE WITH -VALUE
        ld      HL, 0
        or      A                           ; CLEAR CARRY
        sbc     HL, DE                      ; SUBTRACT VALUE FROM 0

        ; NO ERRORS, EXIT WITH CARRY CLEAR
dec2bn_okexit:
        or      A                           ; CLEAR CARRY
        ret

        ; AN ERROR. EXIT WITH CARRY SET
dec2bn_erexit:
        ex      DE, HL                      ; HL = VALUE
        scf                                 ; SET CARRY TO INDICATE ERROR
        ret
;------------------------------------------------------------------------------
KRN_PKEDDATE_TO_DMY:
; Extracts day, month and year from a packed date (used by DZFS to store dates)
; IN <= HL = packed date
; OUT => A = day
;        B = month
;        C = year

        ld      (tmp_addr1), HL         ; backup input packed date

        ; Extract year,
        ;   by shifting right 9 places
        srl     H
        ld      L, H
        ld      H, 0
        push    HL                      ; backup year
    
        ; Extract month,
        ;   by shifting left 7 places (to get rid of the year bits)
        ;   and shifting right 12 places
        ld      HL, (tmp_addr1)             ; restore input packed date

        xor     A
        srl     H
        rr      L
        rra
        ld      H, L
        ld      L, A

        ld      A, H
        rra
        rra
        rra
        rra
        and     15
        ld      L, A
        ld      H, 0                    ; L = month
        push    HL                      ; backup month

        ; Extract day,
        ;   by shifting left 11 places (to get rid of the year and month bits)
        ;   and shifting right 11 places
        ld      HL, (tmp_addr1)         ; restore input packed date

        call    _shift_left_11
        call    _shift_right_11         ; L = day

        ; Prepare outputs
        ld      A, L                    ; A = day
        pop     HL                      ; restore month
        ld      B, L                    ; B = month
        pop     HL                      ; restore year
        ld      C, L                    ; C = year
        ret
;------------------------------------------------------------------------------
KRN_PKEDTIME_TO_HMS:
; Extracts hour, minutes and seconds from a packed time (used by DZFS to store times)
; IN <= HL = packed time
; OUT => A = hour
;        B = minutes
;        C = seconds

        ld      (tmp_addr1), HL         ; backup input packed time

        ; Extract hour,
        ;   by shifting right 11 places
        call    _shift_right_11         ; L = hour
        push    HL                      ; backup hour

        ; Extract minutes,
        ;   by shifting left 5 places (to get rid of the hour bits)
        ;   and shifting right 10 places
        ld      HL, (tmp_addr1)         ; restore input packed time

        add     HL, HL
        add     HL, HL
        add     HL, HL
        add     HL, HL
        add     HL, HL

        call    _shift_right_10         ; L = minutes
        push    HL                      ; backup minutes

        ; Extract seconds,
        ;   by shifting left 11 places (to get rid of the hour and minutes bits)
        ;   and shifting right 10 places
        ld      HL, (tmp_addr1)         ; restore input packed time

        call    _shift_left_11
        call    _shift_right_10         ; L = seconds

        ; Prepare outputs
        ld      C, L                    ; C = seconds
        pop     HL                      ; restore minutes
        ld      B, L                    ; B = minutes
        pop     HL                      ; restore hour
        ld      A, L                    ; A = hour
        ret
_shift_left_11:
; Shift HL left 11 places
        ld      A, L
        add     A, A
        add     A, A
        add     A, A
        ld      H, A
        ld      L, 0
        ret
_shift_right_10:
; Shift HL right 10 places
        srl     H
        srl     H
        ld      L, H
        ld      H, 0
        ret
_shift_right_11:
; Shift HL right 11 places
        ld      A, H
        rra
        rra
        rra
        and     31
        ld      L, A
        ld      H, 0
        ret
