;******************************************************************************
; kernel.string.asm
;
; Kernel's String routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 12 Sep 2019
;******************************************************************************
; CHANGELOG
;   - 12 Sep 2023 - Added F_KRN_STRCHR
;                   Added F_KRN_STRCHRNTH
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2019-2023 David Asta
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
; String Routines
;==============================================================================
;------------------------------------------------------------------------------
KRN_IS_PRINTABLE:
; Checks if a character is a printable ASCII character
; IN <=  A = contains character to check
; OUT => C = flag is set if character is printable
        cp      SPACE                   ; first printable character in ASCII table
        jr      nc, _is_printable
        ccf
        ret
_is_printable:
        cp      $7F                     ; last + 1 printable character in ASCII table
        ret
;------------------------------------------------------------------------------
KRN_IS_NUMERIC:
; Checks if a character is numeric (0..9)
; In ASCII table numbers go from 0 to 9, in Hex 30 to 39
; IN <=  A = contains character to check
; OUT => C = flag is set if character is numeric
        cp      $30                     ; C flag not set if A >= $30
        jr      nc, _is_numeric
        ccf
        ret
_is_numeric:
        cp      $3A                     ; C flag set if A < $3A
        ret
;------------------------------------------------------------------------------
KRN_TOUPPER:
; Convert to Uppercase
; Converts character in register A to uppercase.
; IN <=  A = character to convert
; OUT => A = uppercased character
        cp      'a'                     ; nothing to do if is not lower case
        ret     c
        cp      'z' + 1                 ; > 'z'?
        ret     nc
        and     $5F                     ; convert to upper case
        ret
;------------------------------------------------------------------------------
KRN_STRCMP:
; Compare 2 strings
;IN <=  A length of string 1
;       HL = pointer to start of string 1
;        B = length of string 2
;       DE = pointer to start of string 2
; OUT => if str1 = str2, Z flag set and C flag not set
;        if str1 != str2 and str1 longer than str2, Z flag not set and C flag not set
;        if str1 != str2 and str1 shorter than str2, Z flag not set and C flag set
;
        ; Determine which is the shorter string
        cp      B                       ; compare length str2 to length str1
        jr      c, _strcmp              ; str2 shorter than str1? yes
        ld      A, B                    ; no, str1 is shorter
        ; Compare string (through length of shorter)
_strcmp:
        ld      B, A                    ; counter = length of shorter string (number of bytes to compare)
        ex      DE, HL                  ; DE = str1, HL = str2
        ; In the next loop we need to increment the pointer to the
        ; next byte, so before we enter the loop, we decrement
        dec     HL
        dec     DE
_strcmploop:
        inc     HL                      ; pointer to next byte of str2
        inc     DE                      ; pointer to next byte of str1
        ld      A, (DE)                 ; byte from str1
        cp      (HL)                    ; is it same as in str2?
        ret     nz                      ; no, return with flags set
        djnz    _strcmploop             ; yes, continue comparing
        ret                             ; comparison has finished, return
;------------------------------------------------------------------------------
KRN_STRCPY:
; Copy n characters from string 1 to string 2
; IN <= HL = pointer to start of string 1
;       DE = pointer to start of string 2
;        B = number of characters to copy
        ld      A, (DE)                 ; 1 character from original string
        ld      (HL), A                 ; copy it to destination string
        inc     DE                      ; pointer to next destination character
        inc     HL                      ; pointer to next original character
        djnz    KRN_STRCPY              ; all characters copied (i.e. B=0)? No, continue copying
        ret                             ; yes, exit routine
;------------------------------------------------------------------------------
KRN_STRLEN:
; Returns the length of a string, terminated with a specified character
; IN <= HL = pointer to start of string
;        A = terminating character
; OUT => B = length of string
        ld      B, 0                    ; reset length counter
_strlen:
        cp      (HL)                    ; is it the terminating character?
        ret     z                       ; Yes, return
        inc     HL                      ; No, point to next character in string
        inc     B                       ;     and increment counter
        jp      _strlen                 ; continue loop
;------------------------------------------------------------------------------
KRN_STRLENMAX:
; Returns the length of a string, terminated with a specified character
; but only check up to a maximum of characters
; IN <= HL = pointer to start of string
;        A = terminating character
;        B = maximum length to be checked
; OUT => B = length of string
        ld      E, 0                    ; reset temporary length counter
_lenmax:
        cp      (HL)                    ; is it the terminating character?
        jp      z, _lenmax_end          ; yes, jump out of loop
        inc     HL                      ; No, point to next character in string
        inc     E                       ;     and increment counter
        djnz    _lenmax                 ; loop if we didn't yet check maximum length
_lenmax_end:
        ld      B, E                    ; move temporary counter to output register
        ret
;------------------------------------------------------------------------------
KRN_INSTR:
; Locates the first occurrence of a character within a string
; IN <= HL = pointer to start of string
;        B = character to search in string
;        D = character that marks end of string (terminating Char)
; OUT => E = position of character in string
;        Carry Flag = Set if character found
        push    HL
        ld      E, 0                    ; initialise position counter
        ld      C, 0                    ; initialise counter terminating Char
_instr:
        ld      A, (HL)                 ; get character
        cp      D                       ; is it the terminating Char?
        jr      z, _instr_notfound      ; yes, exit
        cp      B                       ; no, is it the one we're looking for?
        jr      z, _instr_found         ; yes, exit
        inc     HL                      ; no, next character
        inc     E                       ; position +1
        jr      _instr

_instr_found:
        scf                             ; Set Carry flag to indicate found
        jr      _instr_end
_instr_notfound
        xor     A                       ; Clear Carry flag to indicate not found
_instr_end:
        pop     HL
        ret
;------------------------------------------------------------------------------
KRN_STRCHR:
; Finds the first occurrence of a character in a string terminated by a
;   specified character
; IN <= HL = pointer to the zero terminated string
;        D = character that marks end of string (terminating Char)
;        E = character to search for
; OUT => HL = Pointer to the found character
;        Carry Flag = Set if character found
        ld      A, (HL)                 ; get character
        cp      E                       ; if it's the character we are searching
        jr      z, _char_found          ;   end search
        cp      D                       ; if it's the terminating character
        jr      z, _not_found           ;   end search
        inc     HL                      ; otherwise point to next character in
        jr      KRN_STRCHR              ;   string and search again
_not_found:
        xor     A                       ; Clear Carry flag to indicate not found
        ret                             ; and exit
_char_found:
        scf                             ; Set Carry flag to indicate found
        ret                             ; and exit
;------------------------------------------------------------------------------
KRN_STRCHRNTH:
; Finds the nth occurrence of a character in a string terminated by a
;   specified character
; IN <= HL = pointer to the zero terminated string
;        D = character that marks end of string (terminating Char)
;        E = character to search for
;        B = occurrence number (nth)
; OUT => HL = Pointer to the found character
;        Carry Flag = Set if character found
        ld      A, (HL)                 ; get character
        inc     HL                      ; point to next character in string
        cp      E                       ; if it's the character we are searching
        jr      z, _nthchar_found       ;   end search
        cp      D                       ; if it's the terminating character
        jr      z, _nth_not_found       ;   end search
        jr      KRN_STRCHRNTH           ; otherwise, search for more
_nth_not_found:
        xor     A                       ; Clear Carry flag to indicate not found
        ret                             ; and exit
_nthchar_found:
        djnz    KRN_STRCHRNTH           ; if it wasn't the nth, search for more
        dec     HL                      ; decrement to point to right character
        scf                             ; Set Carry flag to indicate found
        ret                             ; and exit