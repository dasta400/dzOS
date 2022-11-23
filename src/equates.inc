;******************************************************************************
; equates.inc
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
;   -
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

ROMRAM_PAGING               .EQU    $38

;==============================================================================
; ROM positions
;==============================================================================
INITSIO2_END                .EQU    $01D9

BIOS_END                    .EQU    $133F
BIOS_JBLK_START             .EQU    BIOS_END + 1
BIOS_JBLK_END               .EQU    BIOS_JBLK_START + 127

KRN_START                   .EQU    BIOS_JBLK_END + 1
KRN_END                     .EQU    $267F
KRN_DZOS_VERSION            .EQU    KRN_END - 15

KRN_JBLK_START              .EQU    KRN_END + 1
KRN_JBLK_END                .EQU    KRN_JBLK_START + 255

CLI_START                   .EQU    KRN_JBLK_END + 1
CLI_END                     .EQU    $3B3F

BOOSTRAP_START              .EQU    CLI_END + 1
BOOSTRAP_END                .EQU    BOOSTRAP_START + 255

FREEROM_START               .EQU    BOOSTRAP_END + 1
FREEROM_END                 .EQU    $3FFF
FREEROM_SIZE                .EQU    FREEROM_END - FREEROM_START

;==============================================================================
; RAM positions
;==============================================================================
STACK_START                 .EQU    $4000               ; Top of the dastaZ80's Stack location
STACK_END                   .EQU    STACK_START + 31    ; Bottom of the dastaZ80's Stack location

SYSVARS_START               .EQU    STACK_END + 1
SYSVARS_END                 .EQU    SYSVARS_START + 348

RESERVED_START              .EQU    SYSVARS_END + 1
RESERVED_END                .EQU    RESERVED_START + (511 - 349)

DISK_BUFFER_START           .EQU    RESERVED_END + 1
DISK_BUFFER_END             .EQU    DISK_BUFFER_START + 511

FREERAM_START               .EQU    DISK_BUFFER_END + 1
FREERAM_END                 .EQU    $FFFF
FREERAM_TOTAL               .EQU    FREERAM_END - FREERAM_START + 1

START_HIGHRAM               .EQU    $8000

;==============================================================================
; Key codes over Serial
;==============================================================================
; CTRLC                   .EQU    $03     ; Ctrl + C
BSPACE                      .EQU    $08     ; Backspace
TAB                         .EQU    $09
LF                          .EQU    $0A     ; Line Feed
CLS                         .EQU    $80     ; Clear Screen (Break/Pause key)
CR                          .EQU    $0D     ; Carriage Return
ESC                         .EQU    $1B     ; Escape
SPACE                       .EQU    $20     ; Space

;==============================================================================
; SIO/2
;==============================================================================
; Port mapping
SIO_CH_A_CONTROL            .EQU    $80
SIO_CH_A_DATA               .EQU    $81
SIO_CH_B_CONTROL            .EQU    $82
SIO_CH_B_DATA               .EQU    $83

SIO_BUFFER_SIZE             .EQU    $40
SIO_FULL_SIZE               .EQU    $30
SIO_EMPTY_SIZE              .EQU    5

SIO_RTS_HIGH                .EQU    $0E8
SIO_RTS_LOW	                .EQU    $0EA

; Write Registers
SIO_WR0                     .EQU    $00
SIO_WR1                     .EQU    $01
SIO_WR2                     .EQU    $02
SIO_WR3                     .EQU    $03
SIO_WR4                     .EQU    $04
SIO_WR5                     .EQU    $05

SIO_N81                     .EQU    $C4     ; 8 bits, no parity, 1 stop bit, 115,200 bps
SIO_ENRX                    .EQU    $C1     ; 8 bits per Rx character, disable Auto Enables (RTS/CTS flow control), enable RX
SIO_ENTX                    .EQU    $68     ; 8 bits per Tx character, enable TX, disable DTR & RTS
SIO_INT_ALLRX               .EQU    $1C     ; Interrupt on all Rx characters (parity irrelevant), enable Status Affects Vector
SIO_IVT                     .EQU    $60     ; Interrupt Vector Table Address
SIO_CH_RESET                .EQU    $18     ; Channel Reset

;==============================================================================
; ANSI Terminal colours
;==============================================================================
ANSI_COLR_BLK               .EQU    0
ANSI_COLR_RED               .EQU    1
ANSI_COLR_GRN               .EQU    2
ANSI_COLR_YLW               .EQU    3
ANSI_COLR_BLU               .EQU    4
ANSI_COLR_MGT               .EQU    5
ANSI_COLR_CYA               .EQU    6
ANSI_COLR_WHT               .EQU    7
ANSI_COLR_GRY               .EQU    8

;==============================================================================
; dastaZ80 File System (DZFS )
;==============================================================================
DZFS_SIGNATURE              .EQU    $BAAB   ; in little-endian will become ABBA ;-)
DZFS_BYTES_PER_SECTOR       .EQU    $0200
DZFS_SECTORS_PER_BLOCK      .EQU    $40
; Superblock offsets
DZFS_SBLOCK_SIGNATURE       .EQU    DISK_BUFFER_START
DZFS_SBLOCK_NOTUSED         .EQU    DISK_BUFFER_START + $02
DZFS_SBLOCK_FSID            .EQU    DISK_BUFFER_START + $03
DZFS_SBLOCK_SERNUM          .EQU    DISK_BUFFER_START + $0B
DZFS_SBLOCK_NOTUSED2        .EQU    DISK_BUFFER_START + $0F
DZFS_SBLOCK_LABEL           .EQU    DISK_BUFFER_START + $10
DZFS_SBLOCK_DATECREA        .EQU    DISK_BUFFER_START + $20
DZFS_SBLOCK_DATECREA_DD     .EQU    DZFS_SBLOCK_DATECREA
DZFS_SBLOCK_DATECREA_MM     .EQU    DZFS_SBLOCK_DATECREA + 2
DZFS_SBLOCK_DATECREA_YYYY   .EQU    DZFS_SBLOCK_DATECREA + 4
DZFS_SBLOCK_TIMECREA        .EQU    DISK_BUFFER_START + $28
DZFS_SBLOCK_TIMECREA_HH     .EQU    DZFS_SBLOCK_TIMECREA
DZFS_SBLOCK_TIMECREA_MM     .EQU    DZFS_SBLOCK_TIMECREA + 2
DZFS_SBLOCK_TIMECREA_SS     .EQU    DZFS_SBLOCK_TIMECREA + 4
DZFS_SBLOCK_BYTESSEC        .EQU    DISK_BUFFER_START + $2E
DZFS_SBLOCK_SECBLOCK        .EQU    DISK_BUFFER_START + $30
DZFS_SBLOCK_NOTUSED3        .EQU    DISK_BUFFER_START + $31
DZFS_SBLOCK_COPYRIGHT       .EQU    DISK_BUFFER_START + $32
DZFS_SBLOCK_FILLER          .EQU    DISK_BUFFER_START + $65

;==============================================================================
; Arduino Serial Multi-Device Controller (ASMDC)
;==============================================================================
ASMDC_ID                    .EQU    $A0

SD_CMD_GET_STATUS           .EQU    $B0
SD_CMD_GET_BUSY             .EQU    $B1
SD_CMD_READ_SECTOR          .EQU    $B2
SD_CMD_WRITE_SECTOR         .EQU    $B3
SD_CMD_PARK_DISKS           .EQU    $B4
SD_CMD_MOUNT_DISK           .EQU    $B5

RTC_CMD_GET_INFO            .EQU    $C0
RTC_CMD_GET_BATT            .EQU    $C1
RTC_CMD_GET_DATE            .EQU    $C2
RTC_CMD_GET_TIME            .EQU    $C3
RTC_CMD_SET_DATE            .EQU    $C4
RTC_CMD_SET_TIME            .EQU    $C5
RTC_CMD_GET_TEMP            .EQU    $C6

NVRAM_CMD_DETECT            .EQU    $D0