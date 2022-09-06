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
;     -
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
#include "src/kernel/kernel.jblks.asm"

        .ORG    KRN_START

        ; Kernel start up messages
        ld      HL, msg_dzos            ; dzOS welcome message
        ld      A, ANSI_COLR_BLU
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, dzos_version        ; dzOS version
        ld      A, ANSI_COLR_BLU
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ld      HL, msg_bios_version    ; BIOS version
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_krn_version     ; Kernel version
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

        ; Detect RAM
        ld      HL, krn_msg_ram_detect
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, krn_msg_left_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ; Show Free available RAM
        ld      HL, FREERAM_TOTAL
        call    F_KRN_BIN_TO_BCD6       ; CDE = 6-digit decimal number
        ex      DE, HL
        ld      DE, tmp_addr1
        call    F_KRN_BCD_TO_ASCII
        ld      IX, tmp_addr1
        call    F_KRN_SERIAL_WR6DIG_NOLZEROS
        ld      HL, krn_msg_ram_trail
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR

        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

        ; Initialise CF card reader
        ld      hl, krn_msg_cf_init
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_BIOS_CF_INIT
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        call    F_KRN_DZFS_READ_SUPERBLOCK
        ld      A, (CF_SBLOCK_SIGNATURE)
        cp      $AB
        jp      nz, error_signature
        call    F_KRN_DZFS_SHOW_DISKINFO_SHORT

        ; Detect RTC
        ld      HL, krn_msg_rtc_detect
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, krn_msg_left_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ; Show battery status
        call    F_BIOS_RTC_CHECK_BATTERY
        cp      $00
        jp      z, battery_failed
battery_healthy:
        ld      HL, msg_rtc_batok
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
rtc_show_datetime:
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ; Show current Date
        call    F_BIOS_RTC_GET_DATE
        call    F_KRN_RTC_SHOW_DATE
        ; Separate Date and Time
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, '-'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ;Show current Time
        call    F_BIOS_RTC_GET_TIME
        call    F_KRN_RTC_SHOW_TIME
        ld      HL, krn_msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        jp      CLI_START               ; Transfer control to CLI

error_signature:
        ; Show a message telling that the disk is unformatted
        ld      HL, error_1001
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        jp      CLI_START               ; Transfer control to CLI

battery_failed:
        ld      HL, error_1002
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, krn_msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        jp      CLI_START               ; Transfer control to CLI

;==============================================================================
; Kernel Modules
;==============================================================================
#include "src/kernel/kernel.serial.asm"
#include "src/kernel/kernel.mem.asm"
#include "src/kernel/kernel.string.asm"
#include "src/kernel/kernel.conv.asm"
#include "src/kernel/kernel.math.asm"
#include "src/kernel/kernel.dzfs.asm"
#include "src/kernel/kernel.rtc.asm"

;==============================================================================
; Constants
;==============================================================================
const_fd_id:
        .BYTE   "DZFSV1  "
const_copyright:
        .BYTE   "Copyright 2022David Asta      The MIT License (MIT)"
;==============================================================================
; Messages
;==============================================================================
msg_dzos:
        .BYTE    CR, LF
        .BYTE    "#####   ######   ####    ####  ", CR, LF
        .BYTE    "##  ##     ##   ##  ##   ##    ", CR, LF
        .BYTE    "##  ##   ##     ##  ##     ##  ", CR, LF
        .BYTE    "#####   ######   ####    ####  ", 0
msg_krn_version:
        .BYTE    CR, LF
        .BYTE    "Kernel v0.1.0", 0
krn_msg_cf_init:
        .BYTE    "....Initialising CompactFlash reader ", 0
krn_msg_ram_detect:
        .BYTE   "....Detecting RAM ", 0
krn_msg_ram_trail:
        .BYTE   " Bytes free ]", 0
krn_msg_rtc_detect:
        .BYTE   "....Detecting RTC ", 0
krn_msg_left_brkt:
        .BYTE   " [ ", 0
krn_msg_right_brkt:
        .BYTE   " ] ", 0
msg_volsn:
        .BYTE   " (S/N: ",0
msg_vol_label:
        .BYTE   "            Volume . . : ",0
msg_vol_creation:
        .BYTE   "            Created on : ",0
msg_num_partitions:
        .BYTE   "            Partitions : ",0
msg_filesys:
        .BYTE   "            File System: ", 0
msg_bytes_sector:
        .BYTE   "       Bytes per Sector: ", 0
msg_sectors_block:
        .BYTE   "      Sectors per Block: ", 0
msg_format_start:
        .BYTE    CR, LF
        .BYTE    "Formatting", 0
msg_rtc_batok:
        .BYTE   "RTC Battery is healthy", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
        .BYTE   "    Disk appears to be unformatted", 0
error_1002:
        .BYTE   "RTC Battery needs replacement", 0

;==============================================================================
; DZOS Version
;==============================================================================
        .ORG    KRN_DZOS_VERSION
dzos_version:            .EXPORT        dzos_version
        .BYTE    "vYYYY.MM.DD.   ", 0    ; This is overwritten by Makefile with
                                        ; compilation date and compile number
;==============================================================================
; END of CODE
;==============================================================================
        .ORG    KRN_END
        .BYTE    0
        .END