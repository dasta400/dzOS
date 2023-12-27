;******************************************************************************
; Name:         kernel.asm
; Description:  Kernel
; Author:       David Asta
; License:      The MIT License
; Created:      03 Jan 2018
; Version:      1.4.0
; Last Modif.:  27 Dec 2023
;******************************************************************************
; CHANGELOG
;   - 17 Aug 2023 - To save bytes in the ROM, instead of loading a logo into
;                       the VDP screen, load a default font charset and display
;                       a text.
;   - 11 Nov 2023 - Removed NVRAM related code.
;   - 13 Dec 2023 - Check if FDD is connected
;   - 14 Dec 2023 - in KRN_DISK_CHANGE, return error if FDD is not connected
;   - 27 Dec 2023 - Removed KRN_DZOS_VERSION, KRN_INIT_RTC, KRN_INIT_VDP
;                 - Removed KRN_INIT_PSG, KRN_INIT_FDD, KRN_INIT_SD
;                 - Removed KRN_DISK_CHANGE, Kernel includes
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2018-2023 David Asta
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

#include "src/equates.inc"

        .ORG    KRN_START

        ; Set default message colours in SYSVARS
        ld      A, ANSI_COLR_CYA
        ld      (col_kernel_debug), A
        ld      A, ANSI_COLR_MGT
        ld      (col_kernel_disk), A
        ld      A, ANSI_COLR_RED
        ld      (col_kernel_error), A
        ld      A, ANSI_COLR_GRN
        ld      (col_kernel_info), A
        ld      A, ANSI_COLR_YLW
        ld      (col_kernel_notice), A
        ld      A, ANSI_COLR_MGT
        ld      (col_kernel_warning), A
        ld      A, ANSI_COLR_BLU
        ld      (col_kernel_welcome), A
        ld      A, ANSI_COLR_CYA
        ld      (col_CLI_debug), A
        ld      A, ANSI_COLR_MGT
        ld      (col_CLI_disk), A
        ld      A, ANSI_COLR_RED
        ld      (col_CLI_error), A
        ld      A, ANSI_COLR_GRN
        ld      (col_CLI_info), A
        ld      A, ANSI_COLR_WHT
        ld      (col_CLI_input), A
        ld      A, ANSI_COLR_YLW
        ld      (col_CLI_notice), A
        ld      A, ANSI_COLR_BLU
        ld      (col_CLI_prompt), A
        ld      A, ANSI_COLR_MGT
        ld      (col_CLI_warning), A
        ; Kernel start up messages
        ld      HL, msg_dzos            ; dzOS welcome message
        ld      A, (col_kernel_welcome)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, dzos_version        ; dzOS version
        ld      A, (col_kernel_welcome)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ld      HL, msg_bios_version    ; BIOS version
        ld      A, (col_kernel_debug)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_krn_version     ; Kernel version
        ld      A, (col_kernel_debug)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

        ; Devices initialisations
        call    KRN_INIT_RAM
        call    KRN_INIT_VDP
        call    KRN_INIT_PSG
        call    KRN_INIT_FDD
        call    KRN_INIT_SD
        call    KRN_INIT_RTC

        ; SYSVARS initialisation
        call    KRN_INIT_SYSVARS

        ; Set default DISK as 1 (1st image file disk on SD)
        ld      A, 1
        call    F_KRN_DISK_CHANGE

        ; Transfer control to CLI
        jp      CLI_START
;------------------------------------------------------------------------------
KRN_SYSHALT:
        call    F_BIOS_SD_PARK_DISKS    ; Tell ASMDC to close all Image files
        ld      HL, msg_halt
        ld      A, (col_kernel_warning)
        call    F_KRN_SERIAL_WRSTRCLR
        jp      F_BIOS_SYSHALT          ; Disable interrupts and halt
;------------------------------------------------------------------------------
KRN_INIT_SYSVARS:
        ; Set show deleted files with 'cat' as OFF
        xor     A
        ld      (DISK_show_deleted), A

        ; Reset VDP Cursor position
        ld      (VDP_cursor_x), A
        ld      (VDP_cursor_y), A

        ; Set default File Type as 0=USR (User defined)
        ; Set loadsave address to default ($0000)
        call    F_KRN_DZFS_SET_FILE_DEFAULTS

        ; Reset Jiffies counter
        ld      IX, VDP_jiffy_byte1
        ld      (IX + 0), 0             ; byte 1
        ld      (IX + 1), 0             ; byte 2
        ld      (IX + 2), 0             ; byte 3

        ret
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
msg_disk:
        .BYTE   "DISK", 0
msg_fdd_init:
        .BYTE    CR, LF
        .BYTE    "....Detecting FDD  ", 0
msg_sd_init:
        .BYTE    CR, LF
        .BYTE    "....Detecting SD   ", 0
msg_sd_found:
        .BYTE    "SD Card found", 0
msg_sd_imgs_found:
        .BYTE    "  Images found: ", 0
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
        .BYTE   CR, LF
        .BYTE   "Formatting", 0
msg_sd_disk_sep:
        .BYTE   "                      ", 0
msg_sd_MB:
        .BYTE   " MB", 0
msg_ram_detect:
        .BYTE   "....Detecting RAM  ", 0
msg_ram_trail:
        .BYTE   " Bytes free ]", 0
msg_rtc_detect:
        .BYTE   "....Detecting RTC  ", 0
msg_rtc_batok:
        .BYTE   "RTC Battery is healthy", 0
msg_nvram_bytes:
        .BYTE   " Bytes", 0
msg_vdp_detect:
        .BYTE    CR, LF
        .BYTE   "....Detecting VDP  ", 0
msg_psg_detect:
        .BYTE    CR, LF
        .BYTE   "....Detecting PSG  ", 0
msg_left_brkt:
        .BYTE   " [ ", 0
msg_right_brkt:
        .BYTE   " ] ", 0
msg_OK:
        .BYTE   "OK", 0
msg_halt:
        .BYTE    CR, LF
        .BYTE   "Computer was halted", CR, LF, 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
        .BYTE   "SD Card is Unformatted", CR, LF, 0
error_1002:
        .BYTE   "SD not found", 0
error_1003:
        .BYTE   "    Image not found", 0
error_2001:
        .BYTE   "RTC Battery needs replacement", 0
error_3001:
        .BYTE   "VDP not detected", 0
error_3002:
        .BYTE   "Unknown VDP mode", 0
error_4001:
        .BYTE   "Not connected", 0
;------------------------------------------------------------------------------
;             VDP Text
;------------------------------------------------------------------------------
vdp_line_1:
        .BYTE   "                dastaZ80", 0
vdp_line_3:
        .BYTE   "        A Z80 homebrew computer", 0
vdp_line_4:
        .BYTE   "           designed and built", 0
vdp_line_5:
        .BYTE   "              by David Asta", 0
vdp_line_7:
        .BYTE   "             (c) 2012-2023", 0
;==============================================================================
; END of CODE
;==============================================================================
