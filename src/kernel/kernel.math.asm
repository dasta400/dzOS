;******************************************************************************
; kernel.math.asm
;
; Kernel's Arithmetic routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 06 Aug 2022
;******************************************************************************
; CHANGELOG
;   - 06 Aug 2022 - Added F_KRN_DIV1616
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
; Arithmetic Routines
;==============================================================================
;------------------------------------------------------------------------------
KRN_MULTIPLY816_SLOW:
; Multiplies an 8-bit number by a 16-bit number (HL = A * DE)
; It does a slow multiplication by adding multiplier to itself as many
; times as multiplicand (e.g. 8 * 4 = 8+8+8+8)
; IN <= A = Multiplicand
;       DE = Multiplier
; OUT => HL = product
        ld      b, a                    ; counter = multiplicand
        ld      hl, 0                   ; initialise result
mult8loop:
        add     hl, de                  ; add multiplier to result
        djnz    mult8loop               ; decrease multiplicand. Is multiplicand = 0? No, do it again
        ret                             ; Yes, exit routine
;------------------------------------------------------------------------------
KRN_MULTIPLY1616:
; Multiplies two 16-bit numbers (HL = HL * DE)
; (c) 1993 by McGraw-Hill, Inc. (Z80 Assembly Language Subroutines)
; IN <= HL = Multiplicand
;       DE = Multiplier
; OUT => HL = product
        ld      C, L
        ld      B, H
        ld      HL, 0
        ld      A, 15
MLP:
        sla     E
        rl      D
        jr      nc, MLP1
        add     HL, BC
MLP1:
        add     HL, HL
        dec     A
        jr      nz, MLP
        or      D
        ret     p
        add     HL, BC
        ret
;------------------------------------------------------------------------------
KRN_DIV1616:
; Divides two 16-bit numbers (BC = BC / DE, HL = remainder)
; (c) https://map.grauw.nl/articles/mult_div_shifts.php
; IN <= BC = dividend
;       DE = divisor
; OUT => BC = quotient
;        HL = remainder
        ld      HL, 0
        ld      A, B
        ld      B, 8
div1616_loop1:
        rla
        adc     HL, HL
        sbc     HL, DE
        jr      nc, div1616_noadd1
        add     HL, DE
div1616_noadd1:
        djnz    div1616_loop1
        rla
        cpl
        ld      B, A
        ld      A, C
        ld      C, B
        ld      B, 8
div1616_loop2:
        rla
        adc     HL, HL
        sbc     HL, DE
        jr      nc, div1616_noadd2
        add     HL, DE
div1616_noadd2:
        djnz    div1616_loop2
        rla
        cpl
        ld      B, C
        ld      C, A
        ret