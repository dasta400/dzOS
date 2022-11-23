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
        ld      HL, msg_ram_detect
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_left_brkt
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
        ld      HL, msg_ram_trail
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR

        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

        ; Set show deleted files with 'cat' as OFF
        ld      A, 0
        ld      (DISK_show_deleted), A

        ; Detect SD Card
        ld      A, 0                    ; Start with
        ld      (DISK_is_formatted), A  ; disk is not formatted
        ld      HL, msg_sd_init
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_left_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_BIOS_SD_GET_STATUS
        ld      HL, SD_status
        bit     0, (HL)                 ; Check if SD card was found
        jp      nz, sd_notfound
        ld      HL, msg_sd_found
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        bit     1, (HL)                 ; Check if Image was found
        jp      nz, sd_image_notfound
        ld      HL, msg_sd_img_found
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR

        call    F_KRN_DZFS_READ_SUPERBLOCK  ; Will set SYSVARS.DISK_is_formatted
                                            ; to $FF with everything correct
        ld      A, (DISK_is_formatted)
        cp      $FF
        jp      nz, error_signature
        call    F_KRN_DZFS_SHOW_DISKINFO_SHORT

detect_RTC:
        ; Detect RTC
        ld      HL, msg_rtc_detect
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_left_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ; Show battery status
        call    F_BIOS_RTC_CHECK_BATTERY    ; A = 0x0A (Healthy) / 0x00 (Dead)
        cp      $00
        jp      z, battery_failed
battery_healthy:
        ld      HL, msg_rtc_batok
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
rtc_show_datetime:
        ; Show current Date
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_KRN_RTC_GET_DATE
        call    F_KRN_RTC_SHOW_DATE
        ; Separate Date and Time
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, '-'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ; Show current Time
        call    F_BIOS_RTC_GET_TIME
        call    F_KRN_RTC_SHOW_TIME
        ld      HL, msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR

        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

detect_NVRAM:
        ; Detect NVRAM
        ld      HL, msg_nvram_detect
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, ANSI_COLR_GRN
        ld      HL, msg_left_brkt
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_BIOS_NVRAM_DETECT
        cp      $FF
        jp      z, nonvram
        call    F_KRN_BIN_TO_BCD4       ; convert NVRAM length to decimal ASCII
        call    F_KRN_SERIAL_PRN_BYTE
        ld      HL, msg_nvram_bytes
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR

transfer_to_CLI:
; ********************************
        ; Transfer control to CLI
        jp      CLI_START
; ********************************

error_signature:
        ; Show a message telling that the disk is unformatted
        ld      HL, error_1001
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        jp      detect_RTC

battery_failed:
        ld      HL, error_2001
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        jp      detect_NVRAM

sd_notfound:
        ld      HL, error_1002
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        jp      detect_RTC

sd_image_notfound:
        ld      HL, error_1003
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        jp      detect_RTC

nonvram:
        ld      HL, error_2101
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        jp      transfer_to_CLI

;------------------------------------------------------------------------------
KRN_SYSHALT:
        call    F_BIOS_SD_PARK_DISKS    ; Tell ASMDC to close all Image files
        ld      HL, msg_halt
        ld      A, ANSI_COLR_MGT
        call    F_KRN_SERIAL_WRSTRCLR
        jp      F_BIOS_SYSHALT          ; Disable interrupts and halt

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
const_sd_fsid:
        .BYTE   "DZFSV1  "
const_sd_copyright:
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
msg_sd_init:
        .BYTE    "....Detecting SD Card ", 0
msg_sd_found:
        .BYTE    "SD Card found", 0
msg_sd_img_found:
        .BYTE    "  Image found", 0
msg_sd_volsn:
        .BYTE   " (S/N: ",0
msg_sd_vol_label:
        .BYTE    CR, LF
        .BYTE   "            Volume . . : ",0
msg_sd_vol_creation:
        .BYTE   "            Created on : ",0
msg_sd_filesys:
        .BYTE   "            File System: ", 0
msg_sd_bytes_sector:
        .BYTE   "       Bytes per Sector: ", 0
msg_sd_sectors_block:
        .BYTE   "      Sectors per Block: ", 0
msg_sd_data_saved:
        .BYTE    CR, LF
        .BYTE   "Data saved to disk", CR, LF, 0
msg_sd_bat_saved:
        .BYTE   "BAT Entry saved to disk", CR, LF, 0
msg_sd_format_start:
        .BYTE    CR, LF
        .BYTE    "Formatting", 0
msg_ram_detect:
        .BYTE   "....Detecting RAM ", 0
msg_ram_trail:
        .BYTE   " Bytes free ]", 0
msg_rtc_detect:
        .BYTE   "....Detecting RTC ", 0
msg_rtc_batok:
        .BYTE   "RTC Battery is healthy", 0
msg_nvram_detect:
        .BYTE   "....Detecting NVRAM ", 0
msg_nvram_bytes:
        .BYTE   " Bytes", 0
msg_left_brkt:
        .BYTE   " [ ", 0
msg_right_brkt:
        .BYTE   " ] ", 0
msg_OK:
        .BYTE   "OK", 0
msg_halt:
        .BYTE    CR, LF
        .BYTE   "Computer was halted", CR, LF, CR, LF
        .BYTE   "IMPORTANT: To use it again you MUST turn it off and on again.", CR, LF
        .BYTE   "           Do NOT just press the Reset button.", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
        .BYTE   "SD Card is Unformatted", CR, LF, 0
error_1002:
        .BYTE   "    SD not found", 0
error_1003:
        .BYTE   "    Image not found", 0
error_2001:
        .BYTE   "RTC Battery needs replacement", 0
error_2101:
        .BYTE   "NVRAM not responding", 0

;==============================================================================
; DZOS Version
;==============================================================================
        .ORG    KRN_DZOS_VERSION
dzos_version:            .EXPORT        dzos_version
        .BYTE    "YYYY.MM.DD.HH.MM", 0  ; This is overwritten by Makefile with
                                        ; compilation date and time
;==============================================================================
; END of CODE
;==============================================================================
        .ORG    KRN_END
        .BYTE    0
        .END