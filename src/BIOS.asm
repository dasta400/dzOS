;******************************************************************************
; BIOS.asm
;
; BIOS (Basic Input/Output System)
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
#include "src/initACIA.asm"
;#include "src/equates.asm"		; this include is already in initACIA.asm
#include "exp/sysconsts.exp"

		.ORG	BIOS_START
;==============================================================================
; General Routines
;==============================================================================
F_BIOS_CBOOT:
; Cold Boot
;		LD		HL, STACK_END			; Bottom of the dastaZ80's Stack location
; 		^ included in initACIA.asm
		call	F_BIOS_WBOOT			; Proceed as if in Warm Boot
		jp		KRN_START				; transfer control to Kernel
		ret
;------------------------------------------------------------------------------
F_BIOS_WBOOT:			.EXPORT			F_BIOS_WBOOT
; Warm Boot
		call	F_BIOS_WIPE_RAM			; wipe (with zeros) the entire RAM, except the Stack area
		call	F_BIOS_CLRSCR			; Clear screen
		ret
;==============================================================================
; Video Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_CLRSCR:			.EXPORT		F_BIOS_CLRSCR
; Clear all contents from the screen
		ret
;==============================================================================
; I/O Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_CONIN:			.EXPORT		F_BIOS_CONIN
; Console input
; Read character from Console and store it in register A.
		rst		10h						; get character in A, using subroutine ininitACIA.asm
		ret
;------------------------------------------------------------------------------
F_BIOS_CONOUT:			.EXPORT		F_BIOS_CONOUT
; Console output
; Write the character in register A to the Console.
		rst		08h						; print character in A, using subroutine ininitACIA.asm
		ret
;==============================================================================
; RAM Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_WIPE_RAM:
; Sets zeros (00h) in all RAM addresses after the SysVars area
		ld		hl, SYSVARS_END + 1		; start address to wipe
		ld		de, FREERAM_END			; end address to wipe
		ld		a, 0					; 00h is the value that will written in all RAM addresses
wiperam_loop:
		ld		(hl), a					; put register A content in address pointed by HL
		inc		hl						; increment pointer
		push	hl						; store HL value in Stack, because SBC destroys it
		sbc		hl, de					; substract DE from HL
		jr		z, wiperam_end			; if we reach the end position, jump out
		pop		hl						; restore HL
		jr		wiperam_loop			; no at end yet, continue loop
wiperam_end:
		pop		hl						; restore HL value from Stack
		ret
;==============================================================================
; CompactFlash IDE Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_CF_INIT:			.EXPORT		F_BIOS_CF_INIT
; Initialise CF IDE card
; Sets CF card to 8-bit data transfer mode
		; Loop until status register bit 7 (busy) is 0
		call	F_BIOS_CF_BUSY		; wait until CF is ready
		ld		a, CF_CMD_SET_FEAT_8BIT_ON	; mask for 8-bit mode enable
		out		(CF_FEAUTURES), a	; send mask to Features register
		call	F_BIOS_CF_BUSY		; wait until CF is ready
		ld		a, CF_CMD_SET_FEATURE	; mask for set feature command
		out		(CF_CMD), a			; send mask to Command register
		call	F_BIOS_CF_BUSY		; wait until CF is ready
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_BUSY:			.EXPORT			F_BIOS_CF_BUSY
; Check CF busy bit (0=ready, 1=busy)
		in		a, (CF_STATUS)		; read status register
		and		10000000b			; mask busy bit
		jp		nz, F_BIOS_CF_BUSY	; if bit is set (i.e. is busy), loop again
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_READ_SEC:			.EXPORT			F_BIOS_CF_READ_SEC
; Read a Sector (512 bytes) from CF card into RAM
		call	F_BIOS_CF_BUSY		; wait until CF is ready
		ld		a, CF_CMD_READ_SECTOR	; mask for read sector(s)
		out		(CF_CMD), a			; send mask to Command register
		call	F_BIOS_CF_BUSY		; wait until CF is ready
		ld		hl, CF_BUFFER_START	; Sector data will be stored at the CF buffer in RAM
		ld		b, 0h				; 256 words (512 bytes) will be read
cf_read_sector_loop:
		; read 1st 256 bytes
		call	F_BIOS_CF_BUSY		; wait until CF is ready
		in		a, (CF_DATA)		; Read byte from Data
		ld		(hl), a				; read byte is stored in RAM
		inc		hl					; increment RAM pointer
		; read 2nd 256 bytes
		call	F_BIOS_CF_BUSY		; wait until CF is ready
		in		a, (CF_DATA)		; Read byte from Data
		ld		(hl), a				; read byte is stored in RAM
		inc		hl					; increment RAM pointer
		djnz	cf_read_sector_loop	; did B went back to 0 (i.e. 256 times)? No, continue loop
		ret							; yes, exit routine
;==============================================================================
; Messages
;==============================================================================
MSG_BIOS_VERSION:				.EXPORT			MSG_BIOS_VERSION
		.BYTE	"BIOS v1.0.0.", 0
;==============================================================================
; END of CODE
;==============================================================================
		.ORG	BIOS_END
				.BYTE	0
		.END