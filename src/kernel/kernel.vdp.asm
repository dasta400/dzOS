;******************************************************************************
; kernel.vdp.asm
;
; Kernel's VDP routines
; for dastaZ80's dzOS
; by David Asta (Aug 2023)
;
; Version 1.0.0
; Created on 17 Aug 2023
; Last Modification 17 Aug 2023
;******************************************************************************
; CHANGELOG
;     - 
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2023 David Asta
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

;-----------------------------------------------------------------------------
KRN_VDP_WRSTR:
; Displays a text in the VDP screen, starting at a specified XY position
; The text MUST be a zero terminated string
; IN <= B = Cursor X start position
;       C = Cursor Y start position
;       HL = Address of a zero terminated string

        ; Set cursor to starting position
        ld      A, B                    ; Set
        ld      (VDP_cursor_x), A       ;   initial values
        ld      A, C                    ;   for
        ld      (VDP_cursor_y), A       ;   XY cursor position
        ; Output character by character, until $00 is found,
        ;   meanwhile incrementing XY
_vdp_wrstr_loop:
        ld      A, (HL)                 ; get a character
        cp      0                       ; if terminator character found
        jr      z, _vdp_wrstr_end       ;   do not print anymore and exit
        push    HL
        call    F_BIOS_VDP_CHAROUT_ATXY ; output character at XY position
        pop     HL
        inc     HL                      ; next character in the string
        jr      _vdp_wrstr_loop
_vdp_wrstr_end:
        ret