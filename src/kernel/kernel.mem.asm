;******************************************************************************
; kernel.mem.asm
;
; Kernel's Memory routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 2.0.0
; Created on 08 May 2019
; Last Modification 03 Jul 2022
;******************************************************************************
; CHANGELOG
;   - 20 Jun 2022: Shorter and faster routine for F_KRN_SETMEMRNG
;   - 03 Jul 2022: Added F_KRN_WHICH_RAMSIZE
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
; Memory Routines
;==============================================================================
;------------------------------------------------------------------------------
F_KRN_SETMEMRNG:        .EXPORT         F_KRN_SETMEMRNG
; Sets a value in a memory position range
; IN <= HL = start position
;       BC = number of bytes to set
;       A value to set
setmemrng_loop:
        ld      (HL), A
        cpi
        jp      pe, setmemrng_loop
        ret
;------------------------------------------------------------------------------
F_KRN_WHICH_RAMSIZE
; Check how much RAM we have
; OUT => Z set for 64 KB, cleare for 32 KB

; Test for 64 KB
        ; Write 1 byte to $FFFF
        ld      A, $AB
        ld      ($FFFF), A
        xor     A
        ; Read it back to see if it was stored
        ld      A, ($FFFF)
        cp      $AB
        ret
