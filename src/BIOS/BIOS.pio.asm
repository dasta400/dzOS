;******************************************************************************
; BIOS.pio.asm
;
; BIOS' Parallel (PIO) routines
; for dastaZ80's dzOS
; by David Asta (July 2022)
;
; Version 1.0.0
; Created on 08 Jul 2022
; Last Modification 08 Jul 2022
;******************************************************************************
; CHANGELOG
;   -
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2022 David Asta
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

; -----------------------------------------------------------------------------
; Initialise PIO
F_BIOS_PIO_INIT:
        ; Set Port A as output (Mode 0)
        ld      A, $0F                  ; D7-D6 = 0 (output)
                                        ; D3-D0 must be 1111 to indicate Set Mode
        out     (PIO_A_CONTROL), A
        ; Set Port B as output (Mode 0)
        ld      A, $0F                  ; D7-D6 = 0 (output)
                                        ; D3-D0 must be 1111 to indicate Set Mode
