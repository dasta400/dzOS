;******************************************************************************
; equates.asm
;
; General Equates (.EQU)
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
; versions
;==============================================================================
BIOS_MAJOR				.EQU	'0'
BIOS_MINOR				.EQU	'1'
BIOS_PATCH				.EQU	'0'

;==============================================================================
; I/O Devices
;==============================================================================
IODEV_CFLASH			.EQU	10h				; CompactFlash

;==============================================================================
; Screen
;==============================================================================
CR						.EQU	0Dh				; Carriage Return
LF						.EQU	0Ah				; Line Feed
;CLRSCR					.EQU	0Ch				; Clear screen
SPACE					.EQU	20h				; Space

;==============================================================================
; ROM positions
;==============================================================================
INITACIA_START			.EQU	0000h
INITACIA_END			.EQU	00FFh

BIOS_START				.EQU	0100h
BIOS_END				.EQU	023Fh
BIOS_JBLK_START			.EQU	0240h
BIOS_JBLK_END			.EQU	033Fh

KRN_START				.EQU	0340h
KRN_END					.EQU	073Fh
KRN_JBLK_START			.EQU	0740h
KRN_JBLK_END			.EQU	083Fh

CLI_START				.EQU	0840h
CLI_END					.EQU	107Fh

SYSCONSTS_START			.EQU	1080h
SYSCONSTS_END			.EQU	108Bh

;==============================================================================
; RAM positions
;==============================================================================
STACK_START				.EQU	2000h			; Top of the dastaZ80's Stack location
STACK_END				.EQU    207Fh			; Bottom of the dastaZ80's Stack location

BIOS_JBLK_COPY_START	.EQU	2080h
BIOS_JBLK_COPY_END		.EQU	217Fh
KRN_JBLK_COPY_START		.EQU	2180h
KRN_JBLK_COPY_END		.EQU	227Fh

SYSVARS_START			.EQU	2280h
SYSVARS_END				.EQU	237Fh

CF_BUFFER_START			.EQU	2380h
CF_BUFFER_END			.EQU	257Fh

FREERAM_START			.EQU	2580h
FREERAM_END				.EQU	7FFFh

;==============================================================================
; CompactFlash
;==============================================================================
; Command Block Registers
CF_DATA					.EQU	IODEV_CFLASH + 00h	; Data (Read/Write)
CF_ERROR				.EQU	IODEV_CFLASH + 01h	; Error register (Read)
CF_FEAUTURES			.EQU	IODEV_CFLASH + 01h	; Features (Write)
CF_SECTORCNT			.EQU	IODEV_CFLASH + 02h	; Sector Count (Read/Write)
CF_SECTORNUM			.EQU	IODEV_CFLASH + 03h	; Sector Number (Read/Write)
CF_CYL_LO				.EQU	IODEV_CFLASH + 04h	; Cylinder Low (Read/Write)
CF_CYL_HI				.EQU	IODEV_CFLASH + 05h	; Cylinder High (Read/Write)
CF_DRIVEHEAD			.EQU	IODEV_CFLASH + 06h	; Drive/Head (Read/Write)
CF_STATUS				.EQU	IODEV_CFLASH + 07h	; Status (Read)
CF_CMD					.EQU	IODEV_CFLASH + 07h	; Command (Write)
CF_LBA0					.EQU	IODEV_CFLASH + 03h	; LBA Bits 0-7 (Read/Write)
CF_LBA1					.EQU	IODEV_CFLASH + 04h	; LBA Bits 8-15 (Read/Write)
CF_LBA2					.EQU	IODEV_CFLASH + 05h	; LBA Bits 16-23 (Read/Write)
CF_LBA3					.EQU	IODEV_CFLASH + 06h	; LBA Bits 24-27 (Read/Write)

; Commands
CF_CMD_SET_FEATURE		.EQU 	0efh				; Set Features
CF_CMD_SET_FEAT_8BIT_ON	.EQU	01h					; Enable 8-bit data transfers
CF_CMD_READ_SECTOR		.EQU	20h					; Read Sector(s) (w/retry)

;==============================================================================
; ACIA Buffers
;==============================================================================
SER_BUFSIZE				.EQU	3FH
SER_FULLSIZE			.EQU	30H
SER_EMPTYSIZE			.EQU	5
serBuf					.EQU	SYSVARS_START
serInPtr				.EQU	serBuf + SER_BUFSIZE
serRdPtr				.EQU	serInPtr + 2
serBufUsed				.EQU	serRdPtr + 2
ACIA_BUFFERS_END		.EQU	serBufUsed + 1

		.END
