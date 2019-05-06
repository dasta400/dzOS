;******************************************************************************
; kernel.asm
;
; Kernel
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 03 Jan 2018
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
; Includes
;==============================================================================
#include "src/equates.asm"
#include "exp/BIOS.exp"
#include "exp/sysconsts.exp"

        .ORG	KRN_START
krn_welcome:
		; Kernel start up messages
		ld		hl, msg_dzos
		call	F_KRN_WRSTR

		ld		hl, MSG_BIOS_VERSION
		call	F_KRN_WRSTR
		ld		a, (BIOS_BUILD)
		call	F_BIOS_CONOUT
		ld		a, (BIOS_BUILD + 1)
		call	F_BIOS_CONOUT
		ld		a, (BIOS_STATUS)
		call	F_BIOS_CONOUT
		ld		a, (BIOS_STATUS + 1)
		call	F_BIOS_CONOUT
		
		ld		hl, msg_krn_version
		call	F_KRN_WRSTR
		ld		a, (KERNEL_BUILD)
		call	F_BIOS_CONOUT
		ld		a, (KERNEL_BUILD + 1)
		call	F_BIOS_CONOUT
		ld		a, (KERNEL_STATUS)
		call	F_BIOS_CONOUT
		ld		a, (KERNEL_STATUS + 1)
		call	F_BIOS_CONOUT

		; output 2 extra empty lines
		ld		a, CR
		call	F_BIOS_CONOUT
		ld		a, LF
		call	F_BIOS_CONOUT
		ld		a, CR
		call	F_BIOS_CONOUT
		ld		a, LF
		call	F_BIOS_CONOUT

		; Initialise CF card reader
		ld		hl, krn_msg_cf_init
		call	F_KRN_WRSTR
		call	F_BIOS_CF_INIT			
		ld		hl, krn_msg_cf_rdy
		call	F_KRN_WRSTR

		jp		CLI_START				; transfer control to CLI
;==============================================================================
; String Routines
;==============================================================================
;------------------------------------------------------------------------------
F_KRN_WRSTR:			.EXPORT		F_KRN_WRSTR
; Output string
; Display a string of ASCII characters terminated with CR.
; HL = pointer to the string.
		ld	    a, (hl)			        ; Get character of the string
		or	    a			            ; is it 00h? (i.e. end of string)
		ret	    z			            ; if yes, then return on terminator
		call	F_BIOS_CONOUT		    ; otherwise, print it
		inc	    hl			            ; pointer to next character of the string
		jr	    F_KRN_WRSTR		        ; continue (until 00h)
		ret
;------------------------------------------------------------------------------
F_KRN_RDCHARECHO:		.EXPORT		F_KRN_RDCHARECHO
; Read a character, with echo
; Read a character from Console and outputs to the Screen
; Read character is stored in register A
		call 	F_BIOS_CONIN
		call 	F_BIOS_CONOUT
; ToDo 	- Check for special characters
;	- Allow backspace
		ret
;------------------------------------------------------------------------------
F_KRN_TOUPPER:			.EXPORT		F_KRN_TOUPPER
; Convert to Uppercase
; Converts character in register A to uppercase.
		cp		'a'						; nothing to do if is not lower case
		ret		c
		cp		'z' + 1					; > 'z'?
		ret		nc
		and		5Fh						; convert to upper case
		ret
;------------------------------------------------------------------------------
F_KRN_GET_BYTE_BIN_ECHO:		.EXPORT		F_KRN_GET_BYTE_BIN_ECHO
; Get Byte (with echo) and convert it to binary
; Gets a single hexadecimal byte from standard input
; converts it to binary
; and stores it in A
		push	hl						; backup HL
		call	F_KRN_RDCHARECHO		; get 1st char of byte
		ld		h, a					; and store it in H
		call	F_KRN_RDCHARECHO		; get 2nd char of byte
		ld		l, a					; and store it in L
		call	F_KRN_HEX2BN			; convert contents of HL to a binary number in A
		pop		hl						; restore HL
		ret
;------------------------------------------------------------------------------
F_KRN_PRN_BYTE:			.EXPORT		F_KRN_PRN_BYTE
; Print Byte
; Prints a single byte in hexadecimal notation.
;	IN <= A (the byte to be printed)
;	OUT => default output (e.g. screen, I/O)
		push	bc
		; convert high nibble
		ld		b, a
		rrca							;move high nibble to low nibble
		rrca
		rrca
		rrca
		call	F_KRN_PRN_NIBBLE    	; prints high nibble
		;convert low nibble
		ld		a, b
		call	F_KRN_PRN_NIBBLE   		; prints low nibble
		pop	bc
		ret
;------------------------------------------------------------------------------
F_KRN_PRN_NIBBLE:
; Print Nibble
; Prints a single hexadecimal nibble in hexadecimal notation.
;	IN <= LSB of A
;	OUT => default output (e.g. screen, I/O)
		and		0fh						; remove hight nibble
		cp		10						; is it a digit?
		jr		c, print_nibble			; yes, print it
		add		a, 7					; no, add offset for letters
print_nibble:
		add		a, 30h					; add offset for digits (30 to 39 in hex is 0 to 9 in dec)
		call	F_BIOS_CONOUT			; print the nibble
		ret
;------------------------------------------------------------------------------
F_KRN_PRN_WORD:			.EXPORT		F_KRN_PRN_WORD
; Print Word
; Prints the 4 hexadecimal digits of a word in hexadecimal notation.
;	IN <= HL (the word to be printed)
;	OUT => default output (e.g. screen, I/O)
		ld		a, h
		call	F_KRN_PRN_BYTE
		ld		a, l
		call	F_KRN_PRN_BYTE
		ret
;------------------------------------------------------------------------------
F_KRN_PRINTABLE:		.EXPORT		F_KRN_PRINTABLE
; Checks if a character is a printable ASCII character
;	IN <= A contains character to check
;	OUT => C flag is set when a character is printable.
		cp		SPACE
		jr		nc, is_printable
		ccf
		ret
is_printable:
		cp		7fh
		ret
;==============================================================================
; Memory Routines
;==============================================================================
F_KRN_SETMEMRNG:		.EXPORT		F_KRN_SETMEMRNG
; Sets a value in a Memory position range
; IN <= HL contains the start position, DE contains the end position.
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
;==============================================================================
; Code Conversion Routines
;==============================================================================
F_KRN_HEX2BN:			.EXPORT		F_KRN_HEX2BN
; Converts two ASCII characters (representing two hexadecimal digits)
; to one byte of binary data
;	IN <= H = More significant ASCII digit
; 		  L = Less significant ASCII digit
; 	OUT => A = Binary data
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
;==============================================================================
; Messages
;==============================================================================
msg_krn_version:
		.BYTE	"Kernel v1.0.0.", 0
msg_dzos:
		.BYTE	CR, LF
		.BYTE	"#####   ######   ####    ####  ", CR, LF
		.BYTE	"##  ##     ##   ##  ##  ##     ", CR, LF
		.BYTE	"##  ##    ##    ##  ##   ####  ", CR, LF
		.BYTE	"##  ##   ##     ##  ##      ## ", CR, LF
		.BYTE	"#####   ######   ####    ####  ", CR, LF, 0
krn_msg_cf_init:
		.BYTE	"....Initialising CompactFlash reader ", 0
krn_msg_cf_rdy:
		.BYTE	"[ OK ]", CR, LF, 0
;==============================================================================
; END of CODE
;==============================================================================
    	.ORG	KRN_END
		        .BYTE	0
		.END