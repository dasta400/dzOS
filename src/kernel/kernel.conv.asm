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
; 	-
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
;TODO - F_KRN_TRANSLT_TIME:			.EXPORT		F_KRN_TRANSLT_TIME
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
F_KRN_ASCIIADR_TO_HEX:		.EXPORT		F_KRN_ASCIIADR_TO_HEX
; Convert address (or any 2 bytes) from hex ASCII to its hex value
; (e.g. hex ASCII = 32 35 37 30 => hex value 2570)
;	IN <= IX = address of 1st digit
;	OUT => HL = converted hex value
;
		; Convert 1st byte
		ld		H, (IX)					; H = hex ASCII value of 1st digit
		ld		L, (IX + 1)				; L = hex ASCII value of 2nd digit
		call	F_KRN_ASCII_TO_HEX		; A = hex value of HL
		push	AF						; Backup 1st converted byte
		; Convert 2nd byte
		ld		H, (IX + 2)				; H = hex ASCII value of 1st digit
		ld		L, (IX + 3)				; L = hex ASCII value of 2nd digit
		call	F_KRN_ASCII_TO_HEX		; A = hex value of HL
		; Store converted bytes into HL
		pop		HL						; Restore 1st converted byte
		ld		L, A					; 2nd converted byte
		ret

;------------------------------------------------------------------------------
F_KRN_ASCII_TO_HEX:			.EXPORT		F_KRN_ASCII_TO_HEX
; Converts two ASCII characters (representing two hexadecimal digits)
; to one byte in Hexadecimal
; (e.g. 0x33 and 0x45 are converted into 3E)
;	IN <= H = Most significant ASCII digit
; 		  L = Less significant ASCII digit
; 	OUT => A = Converted binary data
		ld		a, l 					; get low character
		call	a2hex					; convert it to hexadecimal
		ld		b, a					; save hex value in b
		ld		a, h					; get high character
		call	a2hex					; convert it to hexadecimal
		rrca							; shift hex value to upper 4 bits
		rrca
		rrca
		rrca
		or		b						; or in low hex value
		ret
a2hex: ; convert ascii digit to a hex digit
		sub		'0'						; subtract ascii offset
		cp		10						; is it a decimal digit?
		jr		c, a2hex1				; yes, then return
		sub		7						; no, then subtract offset for letters
a2hex1:
		ret
;------------------------------------------------------------------------------
F_KRN_HEX_TO_ASCII:			.EXPORT		F_KRN_HEX_TO_ASCII
; Converts one byte in Hexadecimal to two ASCII printable characters
; (e.g. 0x3E is converted into 33 and 45, which are the ASCII values of 3 and E)
;	IN <= A = binary data
;	OUT => H = Most significant ASCII digit
;	 	   L = Less significant ASCII digit
		; Convert High Nibble
		ld		b, a					; save original binary value
		and		0F0h					; get high nibble
		rrca							; move high nibble to low nibble
		rrca
		rrca
		rrca
		call	nascii					; convert high nibble to ASCII
		ld		h, a					; return high nibble in H
		; Convert Low Nibble
		ld		a, b
		and 	0Fh						; get low nibble
		call	nascii					; convert low nibble to ASCII
		ld		l, a					; return low nibble in H
		ret
nascii:
		cp		10
		jr		c, nas1					; jump if high nibble < 10
		add		a, 7					; else add 7 so after adding '0' the
										; character will be in 'A'..'F'
nas1:
		add		a, '0'					; add ASCII 0 to make a character
		ret
;------------------------------------------------------------------------------
F_KRN_BIN_TO_BCD4:			.EXPORT		F_KRN_BIN_TO_BCD4
; Converts 1 byte of unsigned integer to 4-digit
; IN <= A = unsigned integer
; OUT => H = hundreds digit
;		 L = tens digit
		ld		h, 255					; counter. Start at -1
hundreds:
		inc		h						; add 1 to quotient
		sub		100						; subtract 100
		jr		nc, hundreds			; still positive? Yes, loop again
		add		a, 100					; no, add the last 100 back

		ld		h, 255					; counter. Start at -1
tens:
		inc		l						; add 1 to quotient
		sub		10						; subtratc 10
		jr		nc, tens				; still positive? Yes, loop again
		add		a, 10					; no, add the last 10 back

		ld		c, a					; save units digit in C
		ld		a, l
		rlca							; move the tens to high nibble of A
		rlca
		rlca
		rlca
		or		c						; or the units digit

		ld		l, a
		ret
;------------------------------------------------------------------------------
F_KRN_BIN_TO_BCD6:			.EXPORT		F_KRN_BIN_TO_BCD6
; Converts 2 bytes of unsigned integer to 6-digit BCD
; (e.g. 0xFFFF is converted into C = 6, D = 55, E = 35)
; https://de.comp.lang.assembler.x86.narkive.com/EjY9sEbE/z80-binary-to-ascii
;	IN <= HL = unsigned integer
;	OUT => CDE = 6-digit BCD
		ld		bc, 4096				; counter
		ld 		de, 0
bin2bcdloop:
		add 	hl, hl
		ld 		a, e
		adc 	a, a
		daa
		ld 		e, a
		ld 		a, d
		adc 	a, a
		daa
		ld 		d, a
		ld 		a, c
		adc 	a, a
		daa
		ld 		c, a
		djnz 	bin2bcdloop				; all bits done? No, continue with more bits
		ret								; yes, exit routine
;------------------------------------------------------------------------------
F_KRN_BCD_TO_ASCII:		.EXPORT		F_KRN_BCD_TO_ASCII
; Converts 6-digit BCD to ASCII string in a memory location
; https://de.comp.lang.assembler.x86.narkive.com/EjY9sEbE/z80-binary-to-ascii
;	IN <= DE = pointer to where the string will be stored
;		  HL = 6-digit BCD
;	OUT => DE = pointer to where the string is stored
		ld 		a, c
		call 	uppernibble
		ld 		a, c
		call	lowernibble
		ld 		a, h
		call 	uppernibble
		ld 		a, h
		call 	lowernibble
		ld 		a, l
		call 	uppernibble
		ld 		a, l
		jr 		lowernibble
uppernibble:
		rra 							; move high nibble to low nibble
		rra
		rra
		rra
lowernibble:
		and 	0Fh 					; get low nibble
		add 	a, 90h
		daa
		adc 	a, 40h
		daa
		ld 		(de), a
		inc 	de
		ret
;------------------------------------------------------------------------------
F_KRN_BITEXTRACT:	.EXPORT		F_KRN_BITEXTRACT
; Bit Extraction
; Extracts a group of bits from a byte and returns the group in the LSB position
; IN <= E = byte from where to extract
;		D = number of bits to extract
;		A = start extraction at bit number
; OUT => A = extracted group of bits
		and		00000111b				; only allow 0 through 7
		jr		z, bitex				; if shifted not needed, then start extraction
		ld		b, a					; B = start extraction at bit number
bitexshift:
		srl		e						; shift E right 1-bit position
		djnz	bitexshift				; continue shifting until reached start position
bitex:
		; if bits to extract is 0, then exit routine
		ld		a, d
		or		a
		ret		z
		dec		a
		and		00000111b				; only allow 0 through 7
		ld		c, a					; BC = index into mask array
		ld		b, 0
		ld		hl, maskarray			; Hl = base address of the mask array
		add		hl, bc					; position inside the mask array
		ld		a, e					; A = byte to extract
		and		(hl)					; mask off unwanted bits
		ret

maskarray:
		.BYTE	00000001b
		.BYTE	00000011b
		.BYTE	00000111b
		.BYTE	00001111b
		.BYTE	00011111b
		.BYTE	00111111b
		.BYTE	01111111b
		.BYTE	11111111b