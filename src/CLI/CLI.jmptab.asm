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

;==============================================================================
; Messages
;==============================================================================
msg_help:
        .BYTE   CR, LF
        .BYTE   ANSI_COLR_YLW
        .BYTE   " dzOS Help", CR, LF
        .BYTE   "|-------------|-----------------------------------|--------------------|", CR, LF
        .BYTE   "| Command     | Description                       | Usage              |", CR, LF
        .BYTE   "|-------------|-----------------------------------|--------------------|", CR, LF
        .BYTE   "| help        | Shows this help                   | help               |", CR, LF
        .BYTE   "| memdump     | Shows contents of memory          | memdump 2200,2300  |", CR, LF
        .BYTE   "| peek        | Show a Memory Address value       | peek 20cf          |", CR, LF
        .BYTE   "| poke        | Change a Memory Address value     | poke 20cf,ff       |", CR, LF
        .BYTE   "| autopoke    | Like poke, but autoincrement addr.| autopoke 2570      |", CR, LF
        .BYTE   "| run         | Run from Memory Address           | run 2570           |", CR, LF
        .BYTE   "| reset       | Clears RAM and resets the system  | reset              |", CR, LF
        .BYTE   "| halt        | Halt the system                   | halt               |", CR, LF
        .BYTE   "|             |                                   |                    |", CR, LF
        .BYTE   "| cat         | Show Disk Catalogue               | cat                |", CR, LF
        .BYTE   "| run         | Run a file on disk                | run diskinfo       |", CR, LF
        .BYTE   "| load        | Load filename from disk to RAM    | load file1         |", CR, LF
        .BYTE   "| formatdsk   | Format CompactFlash disk          | formatdsk mydisk,3 |", CR, LF
        .BYTE   "| rename      | Rename a file                     | rename old,new     |", CR, LF
        .BYTE   "| delete      | Deletes a file                    | delete myfile      |", CR, LF
        .BYTE   "| chgattr     | Assigns new Attributes to a file  | chgattr myfile,RSE |", CR, LF
        ; .BYTE   "| save        | Save from addr. n bytes to a file | save 4570,64       |", CR, LF
        .BYTE   "|             |                                   |                    |", CR, LF
        .BYTE   "| date        | Show current date                 | date               |", CR, LF
        .BYTE   "| time        | Show current time                 | time               |", CR, LF
        .BYTE   "| setdate     | Change current date (ddmmyyyy)    | setdate 30072022   |", CR, LF
        .BYTE   "| settime     | Change current time (hhmmss)      | settime 193900     |", CR, LF
        .BYTE   "|-------------|-----------------------------------|--------------------|", 0

;==============================================================================
; AVAILABLE CLI COMMANDS
;==============================================================================
_CMD_NOCMD          .BYTE   0
_CMD_HELP           .BYTE   "help", 0
_CMD_PEEK           .BYTE   "peek", 0
_CMD_POKE           .BYTE   "poke", 0
_CMD_AUTOPOKE       .BYTE   "autopoke", 0
_CMD_RESET          .BYTE   "reset", 0
_CMD_RUN            .BYTE   "run", 0
_CMD_HALT           .BYTE   "halt", 0
_CMD_MEMDUMP        .BYTE   "memdump", 0

; CompactFlash commands
_CMD_CF_CAT         .BYTE   "cat", 0        ; show files catalogue
_CMD_CF_LOAD        .BYTE   "load", 0       ; load filename from CF to RAM
_CMD_CF_FORMATDSK   .BYTE   "formatdsk", 0  ; format CompactFlash
_CMD_CF_DISKINFO    .BYTE   "diskinfo", 0   ; show CompactFlash information
_CMD_CF_RENAME      .BYTE   "rename", 0     ; renames a file
_CMD_CF_DELETE      .BYTE   "delete", 0     ; deletes a file
_CMD_CF_CHGATTR     .BYTE   "chgattr", 0    ; changes attributes of a file
_CMD_CF_SAVE        .BYTE   "save", 0       ; save n bytes to a file

; RTC commands
_CMD_RTC_DATE       .BYTE   "date", 0
_CMD_RTC_TIME       .BYTE   "time", 0
_CMD_RTC_SETDATE    .BYTE   "setdate", 0
_CMD_RTC_SETTIME    .BYTE   "settime", 0

;==============================================================================
; TABLES
;==============================================================================

; List of available CLI commands
cmd_list_table:
        .WORD       _CMD_NOCMD
        .WORD       _CMD_HELP
        .WORD       _CMD_PEEK
        .WORD       _CMD_POKE
        .WORD       _CMD_AUTOPOKE
        .WORD       _CMD_RESET
        .WORD       _CMD_RUN
        .WORD       _CMD_HALT
        .WORD       _CMD_MEMDUMP
        .WORD       _CMD_CF_CAT
        .WORD       _CMD_CF_LOAD
        .WORD       _CMD_CF_FORMATDSK
        .WORD       _CMD_CF_DISKINFO
        .WORD       _CMD_CF_RENAME
        .WORD       _CMD_CF_DELETE
        .WORD       _CMD_CF_CHGATTR
        ; .WORD       _CMD_CF_SAVE
        .WORD       _CMD_RTC_DATE
        .WORD       _CMD_RTC_TIME
        .WORD       _CMD_RTC_SETDATE
        .WORD       _CMD_RTC_SETTIME

; Jump table for available CLI commands
cmd_jmptable:
        .WORD       CLI_NOCMD
        .WORD       CLI_CMD_HELP
        .WORD       CLI_CMD_PEEK
        .WORD       CLI_CMD_POKE
        .WORD       CLI_CMD_AUTOPOKE
        .WORD       CLI_CMD_RESET
        .WORD       CLI_CMD_RUN
        .WORD       CLI_CMD_HALT
        .WORD       CLI_CMD_MEMDUMP
        .WORD       CLI_CMD_CF_CAT
        .WORD       CLI_CMD_CF_LOAD
        .WORD       CLI_CMD_CF_FORMATDSK
        .WORD       CLI_CMD_CF_DISKINFO
        .WORD       CLI_CMD_CF_RENAME
        .WORD       CLI_CMD_CF_DELETE
        .WORD       CLI_CMD_CF_CHGATTR
        ; .WORD       CLI_CMD_CF_SAVE
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