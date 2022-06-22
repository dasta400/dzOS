;******************************************************************************
; kernel_jblks.asm
;
; Kernel Jumpblocks
; for dastaZ80's dzOS
; by David Asta (Apr 2019)
;
; Version 1.0.0
; Created on 25 Apr 2019
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
; Includes
;==============================================================================
#include "src/equates.inc"
#include "exp/kernel.exp"

		.ORG	KRN_JBLK_START

		jp			F_KRN_SERIAL_WRSTR
		jp			F_KRN_SERIAL_RDCHARECHO
		jp			F_KRN_SERIAL_EMPTYLINES
		jp			F_KRN_SERIAL_PRN_BYTES
		jp			F_KRN_SERIAL_PRN_BYTE
		jp			F_KRN_SERIAL_PRN_WORD
		jp			F_KRN_TOUPPER
		; jp		F_KRN_GET_BYTE_BIN_ECHO
		jp			F_KRN_PRINTABLE
		jp			F_KRN_STRCMP
		jp			F_KRN_STRCPY
		jp			F_KRN_STRLEN
		; jp		F_KRN_SETMEMRNG
		; jp		F_KRN_ASCII2HEX
		; jp		F_KRN_HEX2ASCII
		; jp		F_KRN_BIN2BCD4
		; jp		F_KRN_BIN2BCD6
		; jp		F_KRN_BCD2ASCII
		; jp		F_KRN_BITEXTRACT
		jp			F_KRN_ASCIIADR_TO_HEX
		; jp			F_KRN_TRANSLT_TIME
		; jp			F_KRN_TRANSLT_DATE

		jp			F_KRN_DZFS_READ_SUPERBLOCK
		jp			F_KRN_DZFS_GET_FILE_BATENTRY
		jp			F_KRN_DZFS_LOAD_FILE_TO_RAM
		; jp			F_KRN_DZFS_FORMAT_DISK

		.ORG	KRN_JBLK_END
		.BYTE	0
		.END