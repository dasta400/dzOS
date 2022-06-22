;******************************************************************************
; equates.asm
;
; General Equates (.EQU)
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
; ROM positions
;==============================================================================
INITSIO2_END			.EQU	$01DF

BIOS_END				.EQU	$777
BIOS_JBLK_START			.EQU	BIOS_END + 1
BIOS_JBLK_END			.EQU	BIOS_JBLK_START + 255

KRN_START				.EQU	$0878
KRN_END					.EQU	$0EFF
KRN_DZOS_VERSION		.EQU	KRN_END - 15

KRN_JBLK_START			.EQU	KRN_END + 1
KRN_JBLK_END			.EQU	KRN_JBLK_START + 255

CLI_START				.EQU	$1000
CLI_END					.EQU	$1CEC

FREEROM_START			.EQU	CLI_END + 1
FREEROM_END				.EQU	$1FFF
FREEROM_SIZE			.EQU	FREEROM_END - FREEROM_START

;==============================================================================
; RAM positions
;==============================================================================
STACK_START				.EQU	$2000			    ; Top of the dastaZ80's Stack location
STACK_END				.EQU    STACK_START + 31	; Bottom of the dastaZ80's Stack location

BIOS_JBLK_COPY_START	.EQU	$2080
BIOS_JBLK_COPY_END		.EQU	$217F
KRN_JBLK_COPY_START		.EQU	$2120
KRN_JBLK_COPY_END		.EQU	$221F

SYSVARS_START			.EQU	$2220
SYSVARS_END				.EQU	SYSVARS_START + 328

CF_BUFFER_START			.EQU	$2370
CF_BUFFER_END			.EQU	CF_BUFFER_START + 511

FREERAM_START			.EQU	$2570
FREERAM_END				.EQU	$7FFF
FREERAM_TOTAL			.EQU	FREERAM_END - FREERAM_START + 1

;==============================================================================
; Key codes over Serial
;==============================================================================
CR						.EQU	$0D				; Carriage Return
LF						.EQU	$0A				; Line Feed
SPACE					.EQU	$20				; Space
ESC		                .EQU	$1B             ; Escape
CTRLC		            .EQU	$03             ; Ctrl + C
CLS		                .EQU	$0C             ; CLear Screen

;==============================================================================
; SIO/2
;==============================================================================
SIO_CH_A_CONTROL        .EQU	$80
SIO_CH_A_DATA           .EQU	$81
SIO_CH_B_CONTROL        .EQU	$82
SIO_CH_B_DATA		    .EQU	$83

SIO_BUFFER_SIZE			.EQU	$40
SIO_FULL_SIZE			.EQU	$30
SIO_EMPTY_SIZE			.EQU	5

SIO_RTS_HIGH            .EQU	$0E8
SIO_RTS_LOW	            .EQU	$0EA

;==============================================================================
; CompactFlash
;==============================================================================
CFLASH_PORT				.EQU	$10					; CompactFlash
; Command Block Registers (from ATA rev3.2 document)
CF_DATA					.EQU	CFLASH_PORT + $00	; Data (Read/Write)
CF_ERROR				.EQU	CFLASH_PORT + $01	; Error register (Read)
CF_FEATURES				.EQU	CFLASH_PORT + $01	; Features (Write)
CF_SECTORCNT			.EQU	CFLASH_PORT + $02	; Sector Count (Read/Write)
CF_SECTORNUM			.EQU	CFLASH_PORT + $03	; Sector Number (Read/Write)
CF_CYL_LO				.EQU	CFLASH_PORT + $04	; Cylinder Low (Read/Write)
CF_CYL_HI				.EQU	CFLASH_PORT + $05	; Cylinder High (Read/Write)
CF_DRIVEHEAD			.EQU	CFLASH_PORT + $06	; Drive/Head (Read/Write)
CF_STATUS				.EQU	CFLASH_PORT + $07	; Status (Read)
CF_CMD					.EQU	CFLASH_PORT + $07	; Command (Write)
CF_LBA0					.EQU	CFLASH_PORT + $03	; LBA Bits 0-7 (Read/Write)
CF_LBA1					.EQU	CFLASH_PORT + $04	; LBA Bits 8-15 (Read/Write)
CF_LBA2					.EQU	CFLASH_PORT + $05	; LBA Bits 16-23 (Read/Write)
CF_LBA3					.EQU	CFLASH_PORT + $06	; LBA Bits 24-27 (Read/Write)
; Commands
CF_COMMAND_IDENT_DRIVE	.EQU	$0EC				; Identify Drive
CF_CMD_SET_FEATURE		.EQU 	$0EF				; Set Features
CF_CMD_SET_FEAT_8BIT_ON	.EQU	$01					; Enable 8-bit data transfers
CF_CMD_READ_SECTOR		.EQU	$20					; Read Sector(s) (w/retry)
; Superblock offsets
CF_SBLOCK_SIGNATURE		.EQU	CF_BUFFER_START
CF_SBLOCK_DSKSTATE		.EQU	CF_BUFFER_START + $02
CF_SBLOCK_FSID			.EQU	CF_BUFFER_START + $03
CF_SBLOCK_SERNUM		.EQU	CF_BUFFER_START + $0B
CF_SBLOCK_LABEL			.EQU	CF_BUFFER_START + $10
CF_SBLOCK_DATECREA		.EQU	CF_BUFFER_START + $20
CF_SBLOCK_TIMECREA		.EQU	CF_BUFFER_START + $28
CF_SBLOCK_BYTESSEC		.EQU	CF_BUFFER_START + $2E
CF_SBLOCK_SECBLOCK		.EQU	CF_BUFFER_START + $30
CF_SBLOCK_NUMPARTITIONS	.EQU	CF_BUFFER_START + $31

		.END