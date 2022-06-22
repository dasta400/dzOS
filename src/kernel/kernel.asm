;******************************************************************************
; kernel.asm
;
; Kernel
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 21 Jun 2022
;******************************************************************************
; CHANGELOG
; 	-
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2018-2022 David Asta
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
; Includes
;==============================================================================
#include "src/equates.inc"
#include "exp/BIOS.exp"
#include "exp/sysvars.exp"

		.ORG	KRN_START

        ; Kernel start up messages
		ld		HL, msg_dzos			; dzOS welcome message
		call	F_KRN_SERIAL_WRSTR
		ld		HL, dzos_version		; dzOS version
		call	F_KRN_SERIAL_WRSTR
        ld		HL, msg_bios_version	; BIOS version
		call	F_KRN_SERIAL_WRSTR
		ld		HL, msg_krn_version		; Kernel version
		call	F_KRN_SERIAL_WRSTR

		; output 2 empty lines
		ld		b, 2
		call	F_KRN_SERIAL_EMPTYLINES

		; Initialise CF card reader
		ld		hl, krn_msg_cf_init
		call	F_KRN_SERIAL_WRSTR
		call	F_BIOS_CF_INIT			
		ld		hl, krn_msg_OK
		call	F_KRN_SERIAL_WRSTR
		; Read Superblock
		call	F_KRN_DZFS_READ_SUPERBLOCK

		; Copy BIOS Jumpblocks from ROM to RAM
		ld		hl, krn_msg_cpybiosjblks
		call	F_KRN_SERIAL_WRSTR
		ld		hl, BIOS_JBLK_START			; pointer to address of start of BIOS Jumpblocks in ROM
		ld		de, BIOS_JBLK_COPY_START	; pointer to address of start of BIOS Jumpblocks in RAM
		ld		bc, 256						; jumpblocks are 256 bytes max.
		ldir								; copy from ROM to RAM
		ld		hl, krn_msg_OK
		call	F_KRN_SERIAL_WRSTR
		; Copy Kernel Jumpblocks from ROM to RAM
		ld		hl, krn_msg_cpykrnjblks
		call	F_KRN_SERIAL_WRSTR
		ld		hl, KRN_JBLK_START			; pointer to address of start of Kernel Jumpblocks in ROM
		ld		de, KRN_JBLK_COPY_START		; pointer to address of start of Kernel Jumpblocks in RAM
		ld		bc, 256						; jumpblocks are 256 bytes max.
		ldir								; copy from ROM to RAM
		ld		hl, krn_msg_OK
		call	F_KRN_SERIAL_WRSTR
		
		; output 1 empty line
		ld		b, 1
		call	F_KRN_SERIAL_EMPTYLINES

        jp		CLI_START				; transfer control to CLI

;==============================================================================
; Kernel Modules
;==============================================================================
#include "src/kernel/kernel.kbd.asm"
#include "src/kernel/kernel.serial.asm"
#include "src/kernel/kernel.mem.asm"
#include "src/kernel/kernel.string.asm"
#include "src/kernel/kernel.conv.asm"
#include "src/kernel/kernel.math.asm"
#include "src/kernel/kernel.dzfs.asm"

;==============================================================================
; Messages
;==============================================================================
msg_dzos:
		.BYTE	CR, LF
		.BYTE	"#####   ######   ####    ####  ", CR, LF
		.BYTE	"##  ##     ##   ##  ##   ##    ", CR, LF
		.BYTE	"##  ##   ##     ##  ##     ##  ", CR, LF
		.BYTE	"#####   ######   ####    ####  ", 0
msg_krn_version:
		.BYTE	CR, LF
		.BYTE	"Kernel v1.0.0", 0
krn_msg_cf_init:
		.BYTE	"....Initialising CompactFlash reader ", 0
krn_msg_cpybiosjblks:
		.BYTE	CR, LF
		.BYTE	"....Copying BIOS Jumblocks to RAM ", 0
krn_msg_cpykrnjblks:
		.BYTE	"....Copying Kernel Jumblocks to RAM ", 0
krn_msg_OK:
		.BYTE	"[ OK ]", CR, LF, 0
        
        .ORG	KRN_DZOS_VERSION
dzos_version:			.EXPORT		dzos_version
		.BYTE	"vYYYY.MM.DD.   ", 0    ; This is overwritten by Makefile with
                                        ; compilation date and compile number
;==============================================================================
; END of CODE
;==============================================================================
    	.ORG	KRN_END
		.BYTE	0
		.END