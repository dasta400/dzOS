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
;TODO - F_KRN_TRANSLT_TIME:
; In DZFS, file created/modified time is stored in 2 bytes in the format:
;   5 bits for hour (binary number of hours 0-23)
;   6 bits for minutes (binary number of minutes 0-59)
;   5 bits for seconds (binary number of seconds / 2)
; <-------- MSB --------> <-------- LSB -------->
; 07 06 05 04 03 02 01 00 07 06 05 04 03 02 01 00
; h  h  h  h  h  m  m  m  m  m  m  x  x  x  x  x
; This subroutine translates from that format into a human readable hh:mm:ss
; IN <= HL = address where the time to translate (source) is stored
;       DE = address where the translated time (result) will be stored


;------------------------------------------------------------------------------
KRN_ASCIIADR_TO_HEX:
; Convert address (or any 2 bytes) from hex ASCII to its hex value
; (e.g. hex ASCII = 32 35 37 30 => hex value 2570)
;    IN <= IX = address of 1st digit
;    OUT => HL = converted hex value
;
        ; Convert 1st byte
        ld        H, (IX)                    ; H = hex ASCII value of 1st digit
        ld        L, (IX + 1)                ; L = hex ASCII value of 2nd digit
        call    F_KRN_ASCII_TO_HEX        ; A = hex value of HL
        push    AF                        ; Backup 1st converted byte
        ; Convert 2nd byte
        ld        H, (IX + 2)                ; H = hex ASCII value of 1st digit
        ld        L, (IX + 3)                ; L = hex ASCII value of 2nd digit
        call    F_KRN_ASCII_TO_HEX        ; A = hex value of HL
        ; Store converted bytes into HL
        pop        HL                        ; Restore 1st converted byte
        ld        L, A                    ; 2nd converted byte
        ret

;------------------------------------------------------------------------------
KRN_ASCII_TO_HEX:
; Converts two ASCII characters (representing two hexadecimal digits)
; to one byte in Hexadecimal
; (e.g. 0x33 and 0x45 are converted into 3E)
;    IN <= H = Most significant ASCII digit
;          L = Less significant ASCII digit
;    OUT => A = Converted binary data
        ld        a, l                     ; get low character
        call    a2hex                    ; convert it to hexadecimal
        ld        b, a                    ; save hex value in b
        ld        a, h                    ; get high character
        call    a2hex                    ; convert it to hexadecimal
        rrca                            ; shift hex value to upper 4 bits
        rrca
        rrca
        rrca
        or        b                        ; or in low hex value
        ret
a2hex: ; convert ascii digit to a hex digit
        sub        '0'                        ; subtract ascii offset
        cp        10                        ; is it a decimal digit?
        jr        c, a2hex1                ; yes, then return
        sub        7                        ; no, then subtract offset for letters
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
        ld        b, a                    ; save original binary value
        and        0F0h                    ; get high nibble
        rrca                            ; move high nibble to low nibble
        rrca
        rrca
        rrca
        call    nascii                    ; convert high nibble to ASCII
        ld        h, a                    ; return high nibble in H
        ; Convert Low Nibble
        ld        a, b
        and     0Fh                        ; get low nibble
        call    nascii                    ; convert low nibble to ASCII
        ld        l, a                    ; return low nibble in H
        ret
nascii:
        cp        10
        jr        c, nas1                    ; jump if high nibble < 10
        add        a, 7                    ; else add 7 so after adding '0' the
                                        ; character will be in 'A'..'F'
nas1:
        add        a, '0'                    ; add ASCII 0 to make a character
        ret
;------------------------------------------------------------------------------
KRN_BIN_TO_BCD4:
; Converts 1 byte of unsigned integer hexadecimal to 4-digit BCD
; (e.g. 0x80 is converted into H = 01, L = 28)
; IN <= A = unsigned integer
; OUT => H = hundreds digit
;         L = tens digit
        ld        h, 255                    ; counter. Start at -1
hundreds:
        inc        h                        ; add 1 to quotient
        sub        100                        ; subtract 100
        jr        nc, hundreds            ; still positive? Yes, loop again
        add        a, 100                    ; no, add the last 100 back

        ld        l, 255                    ; counter. Start at -1
tens:
        inc        l                        ; add 1 to quotient
        sub        10                        ; subtratc 10
        jr        nc, tens                ; still positive? Yes, loop again
        add        a, 10                    ; no, add the last 10 back

        ld        c, a                    ; save units digit in C
        ld        a, l
        rlca                            ; move the tens to high nibble of A
        rlca
        rlca
        rlca
        or        c                        ; or the units digit

        ld        l, a
        ret
;------------------------------------------------------------------------------
KRN_BIN_TO_BCD6:
; Converts 2 bytes of unsigned integer decimal to 6-digit BCD
; (e.g. 0xFFFF is converted into C = 6, D = 55, E = 35)
; https://de.comp.lang.assembler.x86.narkive.com/EjY9sEbE/z80-binary-to-ascii
;    IN <= HL = unsigned integer
;    OUT => CDE = 6-digit BCD
        ld        bc, 4096                ; counter
        ld         de, 0
bin2bcdloop:
        add     hl, hl
        ld         a, e
        adc     a, a
        daa
        ld         e, a
        ld         a, d
        adc     a, a
        daa
        ld         d, a
        ld         a, c
        adc     a, a
        daa
        ld         c, a
        djnz     bin2bcdloop                ; all bits done? No, continue with more bits
        ret                                ; yes, exit routine
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
        ld         a, c
        call     uppernibble
        ld         a, c
        call    lowernibble
        ld         a, h
        call     uppernibble
        ld         a, h
        call     lowernibble
        ld         a, l
        call     uppernibble
        ld         a, l
        jr         lowernibble
uppernibble:
        rra                             ; move high nibble to low nibble
        rra
        rra
        rra
lowernibble:
        and     0Fh                     ; get low nibble
        add     a, 90h
        daa
        adc     a, 40h
        daa
        ld         (de), a
        inc     de
        ret
;------------------------------------------------------------------------------
KRN_BITEXTRACT:
; Bit Extraction
; Extracts a group of bits from a byte and returns the group in the LSB position
; IN <= E = byte from where to extract
;        D = number of bits to extract
;        A = start extraction at bit number
; OUT => A = extracted group of bits
        and        00000111b                ; only allow 0 through 7
        jr        z, bitex                ; if shifted not needed, then start extraction
        ld        b, a                    ; B = start extraction at bit number
bitexshift:
        srl        e                        ; shift E right 1-bit position
        djnz    bitexshift                ; continue shifting until reached start position
bitex:
        ; if bits to extract is 0, then exit routine
        ld        a, d
        or        a
        ret        z
        dec        a
        and        00000111b                ; only allow 0 through 7
        ld        c, a                    ; BC = index into mask array
        ld        b, 0
        ld        hl, maskarray            ; Hl = base address of the mask array
        add        hl, bc                    ; position inside the mask array
        ld        a, e                    ; A = byte to extract
        and        (hl)                    ; mask off unwanted bits
        ret

maskarray:
        .BYTE    00000001b
        .BYTE    00000011b
        .BYTE    00000111b
        .BYTE    00001111b
        .BYTE    00011111b
        .BYTE    00111111b
        .BYTE    01111111b
        .BYTE    11111111b

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
