;******************************************************************************
; CLI.jmptab.asm
;
; Command-Line Interface - Commands Jump Table
; for dastaZ80's dzOS
; by David Asta (Jul 2022)
;
; Version 1.1.0
; Created on 06 Jul 2022
; Last Modification 14 Dec 2023
;******************************************************************************
; CHANGELOG
;   - 20 Jul 2022 - Added 'save' command
;   - 11 Sep 2023 - Removed command 'reset'
;   - 14 Dec 2023 - Removed commands 'autopoke', 'crc16', 'clrram', 'vpoke'
;                   Removed commands 'screen', 'clsvdp'
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2022-2023 David Asta
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
; AVAILABLE CLI COMMANDS
;==============================================================================
_CMD_NOCMD              .BYTE   0
_CMD_PEEK               .BYTE   "peek", 0
_CMD_POKE               .BYTE   "poke", 0
_CMD_RUN                .BYTE   "run", 0
_CMD_HALT               .BYTE   "halt", 0

; Disk commands
_CMD_DISK_CAT           .BYTE   "cat", 0        ; show files catalogue
_CMD_DISK_LOAD          .BYTE   "load", 0       ; load filename from DISK to RAM
_CMD_DISK_FORMATDSK     .BYTE   "formatdsk", 0  ; format disk
_CMD_DISK_DISKINFO      .BYTE   "diskinfo", 0   ; show disk information
_CMD_DISK_RENAME        .BYTE   "rename", 0     ; renames a file
_CMD_DISK_DELETE        .BYTE   "delete", 0     ; deletes a file
_CMD_DISK_CHGATTR       .BYTE   "chgattr", 0    ; changes attributes of a file
_CMD_DISK_SAVE          .BYTE   "save", 0       ; save n bytes to a file
_CMD_DISK_CHANGE        .BYTE   "dsk", 0        ; changes current DISK
_CMD_DISK_LIST          .BYTE   "disklist", 0   ; show the list of available DISKs
_CMD_DISK_LOWLVLFORMAT  .BYTE   "erasedisk", 0  ; low-level format (only FDD)

; RTC commands
_CMD_RTC_DATE           .BYTE   "date", 0
_CMD_RTC_TIME           .BYTE   "time", 0
_CMD_RTC_SETDATE        .BYTE   "setdate", 0
_CMD_RTC_SETTIME        .BYTE   "settime", 0

;==============================================================================
; TABLES
;==============================================================================

; List of available CLI commands (add below too)
cmd_list_table:
        .WORD       _CMD_NOCMD
        .WORD       _CMD_PEEK
        .WORD       _CMD_POKE
        .WORD       _CMD_RUN
        .WORD       _CMD_HALT
        .WORD       _CMD_DISK_CAT
        .WORD       _CMD_DISK_LOAD
        .WORD       _CMD_DISK_FORMATDSK
        .WORD       _CMD_DISK_DISKINFO
        .WORD       _CMD_DISK_RENAME
        .WORD       _CMD_DISK_DELETE
        .WORD       _CMD_DISK_CHGATTR
        .WORD       _CMD_DISK_SAVE
        .WORD       _CMD_DISK_CHANGE
        .WORD       _CMD_DISK_LIST
        .WORD       _CMD_DISK_LOWLVLFORMAT
        .WORD       _CMD_RTC_DATE
        .WORD       _CMD_RTC_TIME
        .WORD       _CMD_RTC_SETDATE
        .WORD       _CMD_RTC_SETTIME

; Jump table for available CLI commands (add above too)
cmd_jmptable:
        .WORD       CLI_NOCMD
        .WORD       CLI_CMD_PEEK
        .WORD       CLI_CMD_POKE
        .WORD       CLI_CMD_RUN
        .WORD       CLI_CMD_HALT
        .WORD       CLI_CMD_DISK_CAT
        .WORD       CLI_CMD_DISK_LOAD
        .WORD       CLI_CMD_DISK_FORMATDSK
        .WORD       CLI_CMD_DISK_DISKINFO
        .WORD       CLI_CMD_DISK_RENAME
        .WORD       CLI_CMD_DISK_DELETE
        .WORD       CLI_CMD_DISK_CHGATTR
        .WORD       CLI_CMD_DISK_SAVE
        .WORD       CLI_CMD_DISK_CHANGE
        .WORD       CLI_CMD_DISK_LIST
        .WORD       CLI_CMD_DISK_LOWLVLFORMAT
        .WORD       CLI_CMD_RTC_DATE
        .WORD       CLI_CMD_RTC_TIME
        .WORD       CLI_CMD_RTC_SETDATE
        .WORD       CLI_CMD_RTC_SETTIME

;==============================================================================
; Local Equates
;==============================================================================
JMPTABLE_LENGTH     .EQU        20      ; total number of available commands
                                        ; in jump table above

CLI_NOCMD:
; For some reason I don't understand, a command in the first position of the
; jump table below, is never recognised. So as a workaround, I've added a
; non-existing command to the table
        ret