;******************************************************************************
; kernel.string.asm
;
; Kernel's String routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 08 May 2019
;******************************************************************************
; CHANGELOG
;   -
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2019 David Asta
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
; IN <= A contains character to check
; OUT => C flag is set if character is printable
        cp      SPACE                   ; first printable character in ASCII table
        jr      nc, is_printable
        ccf
        ret
is_printable:
        cp      $7F                     ; last + 1 printable character in ASCII table
        ret
;------------------------------------------------------------------------------
KRN_IS_NUMERIC:
; Checks if a character is numeric (0..9)
; IN <= A contains character to check
; OUT => C flag is set if character is numeric
        cp      $30                     ; first numeric character in ASCII table
        jr      nc, is_numeric
        ccf
        ret
is_numeric:
        cp      $3A                     ; last + 1 numeric character in ASCII table
        ret
;------------------------------------------------------------------------------
KRN_TOUPPER:
; Convert to Uppercase
; Converts character in register A to uppercase.
; IN <= A = character to convert
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
;       HL pointer to start of string 1
;       B length of string 2
;       DE pointer to start of string 2
; OUT => if str1 = str2, Z flag set and C flag not set
;        if str1 != str2 and str1 longer than str2, Z flag not set and C flag not set
;        if str1 != str2 and str1 shorter than str2, Z flag not set and C flag set
;
        ; Determine which is the shorter string
        cp      B                       ; compare length str2 to length str1
        jr      c, strcmp               ; str2 shorter than str1? yes
        ld      A, B                    ; no, str1 is shorter
        ; Compare string (through length of shorter)
strcmp:
        ld      B, A                    ; counter = length of shorter string (number of bytes to compare)
        ex      DE, HL                  ; DE = str1, HL = str2
        ; In the next loop we need to increment the pointer to the
        ; next byte, so before we enter the loop, we decrement
        dec     HL
        dec     DE
strcmploop:
        inc     HL                      ; pointer to next byte of str2
        inc     DE                      ; pointer to next byte of str1
        ld      A, (DE)                 ; byte from str1
        cp      (HL)                    ; is it same as in str2?
        ret     nz                      ; no, return with flags set
        djnz    strcmploop              ; yes, continue comparing
        ret                             ; comparison has finished, return
;------------------------------------------------------------------------------
KRN_STRCPY:
; Copy n characters from string 1 to string 2
; IN <= HL pointer to start of string 1
;       DE pointer to start of string 2
;       B number of characters to copy
        ld      A, (DE)                 ; 1 character from original string
        ld      (HL), A                 ; copy it to destination string
        inc     DE                      ; pointer to next destination character
        inc     HL                      ; pointer to next original character
        djnz    KRN_STRCPY              ; all characters copied (i.e. B=0)? No, continue copying
        ret                             ; yes, exit routine
;------------------------------------------------------------------------------
KRN_STRLEN:
; Returns the length of a string, terminated with a specified character
; IN <= HL pointer to start of string
;       A terminating character
; OUT => B length of string
        ld      B, 0                    ; reset length counter
strlen:
        cp      (HL)                    ; is the character the end of the string?
        ret     z                       ; Yes, return
        inc     HL                      ; No, point to next character in string
        inc     B                       ;     and increment counter
        jp      strlen                  ; continue loop