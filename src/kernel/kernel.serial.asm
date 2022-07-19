;******************************************************************************
; kernel.video.asm
;
; Kernel's Serial routines
; for dastaZ80's dzOS
; by David Asta (Jun 2022)
;
; Version 1.0.0
; Created on 06 Jun 2022
; Last Modification 06 Jun 2022
;******************************************************************************
; CHANGELOG
; 	-
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

;------------------------------------------------------------------------------
F_KRN_SERIAL_WRSTR:			.EXPORT		F_KRN_SERIAL_WRSTR
; Until I have the Video Board, I'll be using the serial port as I/O
; This subroutine CAN BE DELETED once Video Board is working
; Console output string
; Display a string of ASCII characters terminated with CR.
; HL = pointer to first character of the string
		ld	    a, (hl)			        ; Get character of the string
		or	    a			            ; is it 00h? (i.e. end of string)
		ret	    z			            ; if yes, then return
        rst     08h                     ; otherwise, print it
		inc	    hl			            ; pointer to next character of the string
		jr	    F_KRN_SERIAL_WRSTR      ; repeat (until character = 00h)
		ret
;------------------------------------------------------------------------------
F_KRN_SERIAL_RDCHARECHO:		.EXPORT		F_KRN_SERIAL_RDCHARECHO
; Read a character, with echo
; Read a character from Console and outputs to the Screen
; Read character is stored in register A
		call 	F_BIOS_SERIAL_CONIN_A
		call 	F_BIOS_SERIAL_CONOUT_A
; ToDo 	- Check for special characters
;	- Allow backspace
		ret
;------------------------------------------------------------------------------
F_KRN_SERIAL_EMPTYLINES:		.EXPORT		F_KRN_SERIAL_EMPTYLINES
; Output n empty lines
;	IN <= B = number of empty lines to print out
;	OUT => default output (e.g. screen, I/O)
loop_emptylines:
		ld		a, CR
		call	F_BIOS_SERIAL_CONOUT_A
		ld		a, LF
		call	F_BIOS_SERIAL_CONOUT_A
		djnz	loop_emptylines
		ret
;------------------------------------------------------------------------------
F_KRN_SERIAL_PRN_BYTES:		.EXPORT		F_KRN_SERIAL_PRN_BYTES
; Prints bytes
; Print n number of bytes as ASCII characters
;	IN <= B = number of bytes to print
;		  HL = start memory address where the bytes are
;	OUT => default output (e.g. screen, I/O)
		ld		a, (hl)					; get memory content pointed by HL into A
		cp		0						; is it null?
		jp		z, prnbytesend			; yes, exit routine
		cp		LF						; new line?
		jp		nz, nonewline			; no, contine normally
		ld		a, CR					; yes, print CR+LF
		call	F_BIOS_SERIAL_CONOUT_A
		ld		a, LF
nonewline:
		call	F_BIOS_SERIAL_CONOUT_A	; no, print character
		inc		hl						; pointer to next character
		djnz	F_KRN_SERIAL_PRN_BYTES	; all bytes printed? No, continue printing
prnbytesend:
		ret								; yes, exit routine
;------------------------------------------------------------------------------
F_KRN_SERIAL_PRN_BYTE:		.EXPORT		F_KRN_SERIAL_PRN_BYTE
; Print Byte
; Prints a single byte in hexadecimal notation.
;	IN <= A = the byte to be printed
;	OUT => default output (e.g. screen, I/O)
		push	bc
		; convert high nibble
		ld		b, a
		rrca							;move high nibble to low nibble
		rrca
		rrca
		rrca
		call	F_KRN_SERIAL_PRN_NIBBLE    	; prints high nibble
		;convert low nibble
		ld		a, b
		call	F_KRN_SERIAL_PRN_NIBBLE 	; prints low nibble
		pop	bc
		ret
;------------------------------------------------------------------------------
F_KRN_SERIAL_PRN_NIBBLE:
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
		call	F_BIOS_SERIAL_CONOUT_A	; print the nibble
		ret
;------------------------------------------------------------------------------
F_KRN_SERIAL_PRN_WORD:		.EXPORT		F_KRN_SERIAL_PRN_WORD
; Print Word
; Prints the 4 hexadecimal digits of a word in hexadecimal notation.
;	IN <= HL (the word to be printed)
;	OUT => default output (e.g. screen, I/O)
		ld		a, h
		call	F_KRN_SERIAL_PRN_BYTE
		ld		a, l
		call	F_KRN_SERIAL_PRN_BYTE
		ret