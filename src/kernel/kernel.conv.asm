;******************************************************************************
; kernel.conv.asm
;
; Kernel's Conversion routines
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
; This file is part of dzOS
; Copyright (C) 2017-2018 David Asta

; dzOS is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; dzOS is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with dzOS.  If not, see <http://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------

;==============================================================================
; Code Conversion Routines
;==============================================================================
;------------------------------------------------------------------------------
F_KRN_HEX2BIN:			.EXPORT		F_KRN_HEX2BIN
; Converts two ASCII characters (representing two hexadecimal digits)
; to one byte of binary data
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
F_KRN_BIN2HEX:			.EXPORT		F_KRN_BIN2HEX
; Converts one byte of binary data to two ASCII characters
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
