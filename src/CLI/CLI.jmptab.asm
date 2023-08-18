;******************************************************************************
; CLI.jmptab.asm
;
; Command-Line Interface - Commands Jump Table
; for dastaZ80's dzOS
; by David Asta (Jul 2022)
;
; Version 1.0.0
; Created on 06 Jul 2022
; Last Modification 20 Jul 2022
;******************************************************************************
; CHANGELOG
;   - 20 Jul 2022 - Added 'save' command
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2022 David Asta
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

; ;==============================================================================
; ; Messages
; ;==============================================================================
; msg_help:
;         .BYTE   CR, LF
;         .BYTE   " This are just some dzOS commands", CR, LF
;         .BYTE   "|-------------|-----------------------------------|--------------------|", CR, LF
;         .BYTE   "| Command     | Description                       | Usage              |", CR, LF
;         .BYTE   "|-------------|-----------------------------------|--------------------|", CR, LF
;         .BYTE   "| peek        | Show a Memory Address value       | peek 20cf          |", CR, LF
;         .BYTE   "| poke        | Change a Memory Address value     | poke 20cf,ff       |", CR, LF
;         .BYTE   "| autopoke    | Like poke, but autoincrement addr.| autopoke 2570      |", CR, LF
;         .BYTE   "| halt        | Halt the system                   | halt               |", CR, LF
;         .BYTE   "|             |                                   |                    |", CR, LF
;         .BYTE   "| dsk         | Change current DSK                | dsk 1              |", CR, LF
;         .BYTE   "| cat         | Show Disk Catalogue               | cat                |", CR, LF
;         .BYTE   "| run         | Run a file on disk                | run diskinfo       |", CR, LF
;         .BYTE   "| load        | Load filename from disk to RAM    | load file1         |", CR, LF
;         .BYTE   "| rename      | Rename a file                     | rename old,new     |", CR, LF
;         .BYTE   "| delete      | Deletes a file                    | delete myfile      |", CR, LF
;         .BYTE   "| save        | Save from addr. n bytes to a file | save 4570,64       |", CR, LF
;         .BYTE   "|             |                                   |                    |", CR, LF
;         .BYTE   "| date        | Show current date                 | date               |", CR, LF
;         .BYTE   "| time        | Show current time                 | time               |", CR, LF
;         .BYTE   "|-------------|-----------------------------------|--------------------|", 0

;==============================================================================
; AVAILABLE CLI COMMANDS
;==============================================================================
_CMD_NOCMD              .BYTE   0
; _CMD_HELP               .BYTE   "help", 0
_CMD_PEEK               .BYTE   "peek", 0
_CMD_POKE               .BYTE   "poke", 0
_CMD_AUTOPOKE           .BYTE   "autopoke", 0
_CMD_RESET              .BYTE   "reset", 0
_CMD_RUN                .BYTE   "run", 0
_CMD_HALT               .BYTE   "halt", 0
_CMD_CRC16BSC           .BYTE   "crc16", 0
_CMD_CLRRAM             .BYTE   "clrram", 0

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

; VDP commands
_CMD_VDP_VPOKE          .BYTE   "vpoke", 0
_CMD_VDP_SCREEN         .BYTE   "screen", 0
_CMD_VDP_CLS            .BYTE   "clsvdp", 0

;==============================================================================
; TABLES
;==============================================================================

; List of available CLI commands (add below too)
cmd_list_table:
        .WORD       _CMD_NOCMD
        ; .WORD       _CMD_HELP
        .WORD       _CMD_PEEK
        .WORD       _CMD_POKE
        .WORD       _CMD_AUTOPOKE
        .WORD       _CMD_RESET
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
        .WORD       _CMD_CRC16BSC
        .WORD       _CMD_CLRRAM
        .WORD       _CMD_VDP_VPOKE
        .WORD       _CMD_VDP_SCREEN
        .WORD       _CMD_VDP_CLS

; Jump table for available CLI commands (add above too)
cmd_jmptable:
        .WORD       CLI_NOCMD
        ; .WORD       CLI_CMD_HELP
        .WORD       CLI_CMD_PEEK
        .WORD       CLI_CMD_POKE
        .WORD       CLI_CMD_AUTOPOKE
        .WORD       CLI_CMD_RESET
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
        .WORD       CLI_CMD_CRC16BSC
        .WORD       CLI_CMD_CLRRAM
        .WORD       CLI_CMD_VDP_VPOKE
        .WORD       CLI_CMD_VDP_SCREEN
        .WORD       CLI_CMD_VDP_CLS

;==============================================================================
; Local Equates
;==============================================================================
JMPTABLE_LENGTH     .EQU        27      ; total number of available commands
                                        ; in jump table above

CLI_NOCMD:
; For some reason I don't understand, a command in the first position of the
; jump table below, is never recognised. So as a workaround, I've added a
; non-existing command to the table
        ret