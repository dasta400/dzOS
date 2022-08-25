;******************************************************************************
; kernel.math.asm
;
; Kernel's Arithmetic routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 15 Aug 2022
;******************************************************************************
; CHANGELOG
;   - 06 Aug 2022 - Added F_KRN_DIV1616
;   - 15 Aug 2022 - Added CRC-16/BUYPASS
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
KRN_MULTIPLY816_SLOW:   ;ToDo - Change IN and OUT, and all places were is called, to instead use SYSVARS
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
KRN_MULTIPLY1616:       ;ToDo - Change IN and OUT, and all places were is called, to instead use SYSVARS
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
KRN_DIV1616:            ;ToDo - Change IN and OUT, and all places were is called, to instead use SYSVARS
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
;==============================================================================
; Generates a CRC-16/BUYPASS, a 16-bit cyclic redundancy check (CRC) based on
;   the IBM Binary Synchronous Communications protocol (BSC or Bisync).
; Uses the polynomial X^16 + X^15 + X^2 + 1
; (c) 1993 by McGraw-Hill, Inc. (Z80 Assembly Language Subroutines)
;==============================================================================
;------------------------------------------------------------------------------
KRN_CRC16_INI:  ; ICRC16
; Initialises the CRC to 0 and the polynomial to the appropriate bit pattern
; OUT => 0 (initial CRC value) in memory locations CRC (LSB) and CRC+1 (MSB),
;        CRC polynomial in memory locations PLY (LSB) and PLY+1 (MSB)
        ld      HL, 0                   ; CRC = 0
        ld      (MATH_CRC), HL
        ld      HL, $8005               ; PLY = $8005
        ld      (MATH_polynomial), HL   ; $8005 IS FOR X^16 + X^15 + X^2 + 1
                                        ; A 1 IS IN EACH BIT POSITION
                                        ;   FOR WHICH A POWER APPEARS IN
                                        ;   THE FORMULA (BITS 0, 2 AND 15)
        ret
;------------------------------------------------------------------------------
KRN_CRC16_GEN:  ; CRC16
; Combines the previous CRC with the CRC generated from the current data byte.
; IN <= A = data byte
;       previous CRC in CRC (LSB) and CRC+1 (MSB)
;       CRC polynomial in PLY (LSB) and PLY+1 (MSB)
; OUT => CRC with current data byte included in CRC (LSB) and CRC+1 (MSB)
;
        ; LOOP THROUGH EACH BIT GENERATING THE CRC
        ld      B, 8                    ; 8 BITS PER BYTES
        ld      DE, (MATH_polynomial)   ; GET POLYNOMIAL
        ld      HL, (MATH_CRC)          ; GET CURRENT CRC VALUE
_CRCLP:
        ld      C, A                    ; SAVE DATA C
        and     10000000b               ; GET BIT 7 OF DATA
        xor     H                       ; EXCLUSIVE OR BIT 7 WITH BIT 15 OF CRC
        ld      H, A
        add     HL, HL                  ; SHIFT CRC LEFT
        jr      nc, _CRCLP1             ; JUMP IF BIT 7 OF EXCLUSIVE-OR WAS 0

        ; BIT 7 WAS 1, SO EXCLUSIVE-OR CRC WITH POLYNOMIAL
        ld      A, E                    ; GET LOW BYTE OF POLYNOMIAL
        xor     L                       ; EXCLUSIVE-OR WITH LOW BYTE OF CRC
        ld      L, A
        ld      A, D                    ; GET HIGH BYTE OF POLYNOMIAL
        xor     H                       ; EXCLUSIVE-OR WITH HIGH BYTE OF CRC
        ld      H, A
_CRCLP1:
        ld      A, C                    ; RESTORE DATA
        rla                             ; SHIFT NEXT DATA BIT TO BIT 7
        djnz    _CRCLP                  ; DECREMENT BIT COUNTER
                                        ;   JUMP IF NOT THROUGH 8 BITS
        ld      (MATH_CRC), HL         ; SAVE UPDATED CRC
        ret
