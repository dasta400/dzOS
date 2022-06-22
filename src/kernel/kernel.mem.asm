;******************************************************************************
; kernel.mem.asm
;
; Kernel's Memory routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 08 May 2019
;******************************************************************************
; CHANGELOG
; 	-
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
F_KRN_SETMEMRNG:		.EXPORT		F_KRN_SETMEMRNG
; Sets a value in a memory position range
; IN <= HL contains the start position
;		DE contains the end position.
;		A value to set
; The routine will go from HL to DE and store in each position whatever value
; is in register A.
setmemrng_loop:
		ld		(hl), a					; put register A content in address pointed by HL
		inc		hl						; HL pointed + 1
		push	hl						; store HL value in Stack, because SBC destroys it
		sbc		hl, de					; substract DE from HL
		jp		z, end_setmemrng_loop	; if we reach the end position, jump out
		pop		hl						; restore HL value from Stack
		jp		setmemrng_loop			; no at end yet, continue loop
end_setmemrng_loop:
		pop		hl						; restore HL value from Stack
		ret