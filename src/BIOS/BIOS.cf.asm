;******************************************************************************
; BIOS.cf.asm
;
; BIOS' CompactFlash routines
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
; CompactFlash Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_CF_INIT:			.EXPORT		F_BIOS_CF_INIT
; Initialise CF IDE card
; Sets CF card to 8-bit data transfer mode
		; Loop until status register bit 7 (busy) is 0
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		a, CF_CMD_SET_FEAT_8BIT_ON	; mask for 8-bit mode enable
		out		(CF_FEATURES), a			; send mask to Features register
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		a, CF_CMD_SET_FEATURE		; mask for set feature command
		out		(CF_CMD), a					; send mask to Command register
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_DISKINFO:		.EXPORT			F_BIOS_CF_DISKINFO
; Executes an "Identify Drive" command
		call	F_BIOS_CF_BUSY				; loop until CF card is ready
		ld		a, CF_COMMAND_IDENT_DRIVE	; mask for Identidy Drive
		out		(CF_CMD), a					; send mask to Command register
		call	F_BIOS_CF_BUSY				; loop until CF card is ready
		ld		hl, CF_BUFFER_START			; Sector data will be stored at the CF buffer in RAM
		ld		b, 0h						; 256 words (512 bytes) will be read
		call	F_BIOS_CF_READ_512B
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_BUSY:			.EXPORT			F_BIOS_CF_BUSY
; Check CF busy bit (0=ready, 1=busy)
		in		a, (CF_STATUS)				; read status register
		and		10000000b					; mask busy bit
		jp		nz, F_BIOS_CF_BUSY			; if bit is set (i.e. is busy), loop again
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_SET_LBA:
; Set sector count and LBA address
; IN <= E = sector address LBA 0 (bits 0-7)
;		D = sector address LBA 1 (bits 8-15)
;		C = sector address LBA 2 (bits 16-23)
;		B = sector address LBA 3 (bits 24-27)
		call	F_BIOS_CF_BUSY				; loop until CF card is ready
		
		ld		a, 1
		out		(CF_SECTORCNT), a			; 1 sector at at a time (512 bytes)
		call	F_BIOS_CF_BUSY				; loop until CF card is ready
		
		ld		a, e						; sector address LBA 0
		out		(CF_LBA0), a				; LBA Bits 0-7
		call	F_BIOS_CF_BUSY				; loop until CF card is ready
		
		ld		a, d						; sector address LBA 1
		out		(CF_LBA1), a				; LBA Bits 8-15
		call	F_BIOS_CF_BUSY				; loop until CF card is ready
		
		ld		a, c						; sector address LBA 2
		out		(CF_LBA2), a				; LBA Bits 16-23
		call	F_BIOS_CF_BUSY				; loop until CF card is ready

		ld		a, b						; sector address LBA 3
		and     0fh                     	; only bits 0 to 3 are LBA 3
		or      $e0                     	; mask to select as drive 0 (master)
		out		(CF_LBA3), a				; LBA Bits 24-27
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_READ_SEC:			.EXPORT			F_BIOS_CF_READ_SEC
; Read a Sector (512 bytes) from CF card into RAM buffer
; IN <= E = sector address LBA 0 (bits 0-7)
;		D = sector address LBA 1 (bits 8-15)
;		C = sector address LBA 2 (bits 16-23)
;		B = sector address LBA 3 (bits 24-27)
		; set LBA addresses
		call	F_BIOS_CF_SET_LBA
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		a, CF_CMD_READ_SECTOR		; mask for read sector(s)
		out		(CF_CMD), a					; send mask to Command register
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		hl, CF_BUFFER_START			; Sector data will be stored at the CF buffer in RAM
		ld		b, 0h						; 256 words (512 bytes) will be read
F_BIOS_CF_READ_512B:
; Read 2 bytes each time, 256 times
; Hence, 512 bytes are read in total
		; 1st byte
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		in		a, (CF_DATA)				; Read byte from Data
		ld		(hl), a						; read byte is stored in RAM
		inc		hl							; increment RAM pointer
		; 2nd byte
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		in		a, (CF_DATA)				; Read byte from Data
		ld		(hl), a						; read byte is stored in RAM
		inc		hl							; increment RAM pointer
		
		djnz	F_BIOS_CF_READ_512B			; did B went back to 0 (i.e. 256 times)? No, continue loop
		ret									; yes, exit routine
;------------------------------------------------------------------------------
F_BIOS_CF_WRITE_SEC:			.EXPORT			F_BIOS_CF_WRITE_SEC
; Write a Sector (512 bytes) from RAM buffer into CF card
; IN <= E = sector address LBA 0 (bits 0-7)
;		D = sector address LBA 1 (bits 8-15)
;		C = sector address LBA 2 (bits 16-23)
;		B = sector address LBA 3 (bits 24-27)
		; set LBA addresses
		call	F_BIOS_CF_SET_LBA
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		A, CF_CMD_WRITE_SECTOR		; mask for write sector(s)
		out		(CF_CMD), A					; send mask to Command register
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		HL, CF_BUFFER_START			; Sector data is stored at the CF buffer in RAM
		ld		B, 0h						; 256 words (512 bytes) will be written
F_BIOS_CF_WRITE_512B:
; Write 2 bytes each time, 256 times
; Hence, 512 bytes are written in total
		; 1st byte
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		A, (HL)						; A = byte to be written
		out		(CFLASH_PORT), A			; write to CF
		inc		HL
		; 2nd byte
		call	F_BIOS_CF_BUSY				; wait until CF is ready
		ld		A, (HL)						; A = byte to be written
		out		(CFLASH_PORT), A			; write to CF
		inc		HL

		djnz	F_BIOS_CF_WRITE_512B		; did B went back to 0 (i.e. 256 times)? No, continue loop
		ret									; yes, exit routine