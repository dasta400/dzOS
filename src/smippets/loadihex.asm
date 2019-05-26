;******************************************************************************
; loadihex.asm
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

;------------------------------------------------------------------------------
;	loadihex - Load Intel HEX file into memory
;------------------------------------------------------------------------------
CLI_CMD_LOADIHEX:
; IMPORTANT NOTE: Checksum is not implemented
;
; Intel HEX record structure
;	A record (line of text) consists of six fields that appear in order
;	from left to right
;		START CODE; one character, an ASCII colon.
;		BYTE COUNT; 2 hex digits, indicating number of bytes in data field.
;		ADDRESS; 4 hex digits, representing the 16-bit beginning memory
;		  address offset of the data
;		RECORD TYPE; 2 hex digits, defining the meaning of the data field.
;			00 = data
;			01 = end of file
;			02 = Extended Segment Address
;			03 = Start Segment Address
;			04 = Extended Linear Address
;			05 = Start Linear Address
;		DATA; a sequence of n bytes of data, represented by 2n hex digits.
;		CHECKSUM; 2 hex digits, a computed value that can be used to verify
;		  the record has no errors. It is computed by summing the decoded
;		  byte values and extracting the LSB of the sum and then calculating
;		  the two's complement of the LSB.
;
; Used registers
; 	A = Received iHEX bytes
; 	D = byte count from iHEX
; 	HL = pointer to memory address

		ld		hl, msg_rcvhex
		call	F_KRN_WRSTR
		ld		c, 0					; initilise C, to store checksum
start_ihexload:
		; Start code (1 byte)
		call	F_KRN_RDCHARECHO		; get START CODE (1 char)
		cp		':'						; is it colon?
		jp		nz, ihexload_error		; no, show error and return
		; Byte count (1 byte)
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		d, a					; store it in D
		; Address (2 bytes)
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		h, a
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		l, a
	; HL contains now the address from iHex file
		; Record type (1 byte)
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		cp		01h						; is it End Of File?
		jp		z, ihexload_end 		; yes, show finished message and end
		cp		00h						; no, is it Data?
		jp		nz, ihexload_error		; no, show error and return
		; Data (n bytes, where n is equal to BYTE COUNT)
get_data:
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		(hl), a					; store byte in memory
		inc		hl						; increment memory address pointer
		dec		d						; decrement byte count counter
		ld		a, d					; copy D to A to make compare
		cp		0						; did we loaded all bytes?
		jp		nz, get_data			; no, get more data
		; Checksum (1 byte)
	; Checksum is not implemented, we just read the byte and discard it
		call	F_KRN_RDCHARECHO		; get START CODE (1 char)
		call	F_KRN_RDCHARECHO		; get START CODE (1 char)
		; CRLF (1 byte)
		call	F_BIOS_CONIN 			; get CR
		ld		hl, msg_crc_ok
		call	F_KRN_WRSTR
		jp		start_ihexload			; and get next line
ihexload_error:							; invalid Intel HEX file
		ld		hl, error_1003
		call	F_KRN_WRSTR
		ret
ihexload_end: 							; RECORD TYPE = End Of File (01), then last byte must be FF
	; Checksum is not implemented, we just read the byte and discard it
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		hl, msg_crc_ok
		call	F_KRN_WRSTR
		ld		hl, msg_endhex			; yes, show success message
		call	F_KRN_WRSTR
		ret