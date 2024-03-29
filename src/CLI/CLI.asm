;******************************************************************************
; CLI.asm
;
; Command-Line Interface
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.1.0
; Created on 03 Jan 2018
; Last Modification 08 Sep 2023
;******************************************************************************
; CHANGELOG
;   - 17 Aug 2023 - Check if command is a file in the current disk and in case
;                       it is, load and run it.
;   - 08 Sep 2023 - Added a push/pop to preserve the subrotuine counter in
;                       parse_get_command. This saves 354 clock cycles, because
;                       parse_get_command is not called twice when B=0 anymore.
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

        .ORG    CLI_START
cli_welcome:
        ld      HL, msg_cli_version     ; CLI start up message
        ld      A, (col_CLI_debug)
        call    F_KRN_SERIAL_WRSTRCLR

        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

        ld      HL, cli_promptloop
        ld      IX, CLI_prompt_addr
        ld      (IX + 0), L
        ld      (IX + 1), H

cli_promptloop:         .EXPORT     cli_promptloop
; Prompt is "DSK" + DISK_current + "> "
        call    F_CLI_CLRCLIBUFFS       ; Clear buffers
        ld      HL, msg_prompt          ; Prompt
        ld      A, (col_CLI_prompt)
        call    F_KRN_SERIAL_WRSTRCLR

        ; print disk number (DISK_current)
        ld      A, (col_CLI_debug)
        call    F_KRN_SERIAL_SETFGCOLR
        ld      A, (DISK_current)
        call    F_KRN_BIN_TO_BCD4       ; HL = disk number in decimal
        ld      DE, CLI_buffer
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII      ; DE = capacity in ASCII string
        ; skip leading zeros
        ld      A, (CLI_buffer + 4)
        cp      $30
        jp      z, prompt_skip_lead_zero
        call    F_BIOS_SERIAL_CONOUT_A  ; print first digit (if not a zero)
prompt_skip_lead_zero:
        ld      A, (CLI_buffer + 5)
        call    F_BIOS_SERIAL_CONOUT_A  ; print second digit
        ; print "> "
        ld      A, (col_CLI_prompt)
        call    F_KRN_SERIAL_SETFGCOLR
        ld      A, '>'
        call    F_BIOS_SERIAL_CONOUT_A  ; print prompt
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A  ; print separator

        ld      A, (col_CLI_input)      ; Set text colour
        call    F_KRN_SERIAL_SETFGCOLR  ;   for user input
        call    F_CLI_READCMD
        ; If no command was entered (just ENTER pressed), go to cli_promptloop
        ld      A, (CLI_buffer_cmd)
        cp      0
        jp      z, cli_promptloop
        ; Otherwise, parse it and call corresponding subroutine
        call    F_CLI_PARSECMD
        jr      c, cli_command_unknown
        jp      cli_promptloop
cli_command_unknown:
        ; Added 17 Aug 2023 - Check if command is a file in the current disk
        ;                       and in case it is, load and run it
        ; filename found, load and run it
        ld      A, $AB                  ; This is a flag to tell CLI_CMD_DISK_LOAD_DIRECT that the call
        ld      (tmp_byte2), A          ;   didn't come from the jumptable, so that it can return here
        ld      HL, CLI_buffer_cmd
        call    CLI_CMD_DISK_LOAD_DIRECT
        ld      A, (tmp_byte)           ; Was the file loaded correctly?
        cp      $EF                     ; EF means there was an error
        jp      z, cli_promptloop       ; exit subroutine if file didn't load
        ; file was loaded, run it
        ld      A, (col_CLI_input)      ; Set text colour
        call    F_KRN_SERIAL_SETFGCOLR  ;   for user input
        ld      HL, (DISK_cur_file_load_addr)
        jp      (HL)                    ; jump execution to address in HL
_cli_no_cmd_nor_file:
        ld      HL, error_9001
        ld      A, (col_CLI_error)
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop
;------------------------------------------------------------------------------
F_CLI_READCMD:
; Read string containing a command and parameters
; Read characters from the Console into a memory buffer until RETURN is pressed.
; Parameters (identified by comma) are detected and stored in 'parameters buffer',
; meanwhile the command is stored in 'command buffer'.
        ld      HL, CLI_buffer_cmd      ; address where command (no params) is stored
        ld      DE, CLI_buffer_full_cmd ; address where commands + params is stored
readcmd_loop:
        call    F_KRN_SERIAL_RDCHARECHO ; A = character read from serial (keyboard)
        cp      0                       ; if no character (e.g. CLRSCR)
        jp      z, readcmd_loop         ;   read another
        ld      (DE), A                 ; store character
        inc     DE                      ;   in full command buffer

        ; Test for parameter entered (comma or space separated)
        cp      ' '
        jp      z, was_param
        cp      ','
        jp      z, was_param

        ; Test for special keys
        cp      BSPACE                  ; Backspace?
        jp      z, was_backspace        ; yes, don't add to buffer
        cp      CR                      ; ENTER?
        jp      z, end_get_cmd          ; yes, command was fully entered
        cp      $0C                     ; Break key pressed (CLear Screen)?
        jp      z, cli_promptloop

        ; Store character in buffer
        ld      (HL), A
        inc     HL
no_buffer:
        jp      readcmd_loop
        ret
was_backspace:
        dec     HL                      ; go back 1 unit on this buffer pointer
        ld      (HL), 0                 ; and clear whatever was there before
        dec     DE                      ; go back 2 units
        dec     DE                      ;    on full command buffer
        ; Delete character on screen
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A
        ; and go back 1 character on screen
        ld      B, 4
        push    DE
        ld      DE, ANSI_CURSOR_BACK
        call    F_KRN_SERIAL_SEND_ANSI_CODE
        pop     DE
        jp      readcmd_loop            ; read another character
was_param:
        ld      A, (CLI_buffer_parm1_val)
        cp      00h                     ; is buffer area empty (=00h)?
        jp      z, add_value1           ; yes, add character to buffer area
        ld      A, (CLI_buffer_parm2_val)
        cp      00h                     ; is buffer area empty (=00h)?
        jp      z, add_value2           ; yes, add character to buffer area
        jp      readcmd_loop            ; read next character
add_value1:
        ld      HL, CLI_buffer_parm1_val
        jp      readcmd_loop
add_value2:
        ld      HL, CLI_buffer_parm2_val
        jp      readcmd_loop
end_get_cmd:
        ret
;------------------------------------------------------------------------------
F_CLI_PARSECMD:
; Parse command
; Parses entered command and calls related subroutine.
; If command is not known by CLI, sets Carry flag and returns
        ld      B, 0                    ; subroutine counter
parse_loop:
        ld      HL, 0                   ; reset HL
        ld      A, B                    ; If checking the first command
        cp      0                       ;   (i.e. 0), don't need to calculate
        jp      z, parse_get_command    ;   the extra offset
        cp      JMPTABLE_LENGTH         ; If all commands in jump table
        ccf                             ;   were checked already
        ret     c                       ;   return with Carry Flag set
        ld      DE, 2                   ; If not 1st command, then needs
        push    BC                      ;   an offset of 2 bytes for each
        call    F_KRN_MULTIPLY816_SLOW  ;   value in the table
        pop     BC                      ; restore subroutine counter
parse_get_command:
        call    parse_get_from_jtable   ; get command address from jump table
        ld      HL, CLI_buffer_cmd      ; Compare command
        ld      A, (HL)                 ;    in jump table
        push    BC                      ; backup subrotuine counter
        call    search_cmd              ;    with command entered by user
        pop    BC                       ; restore subrotuine counter
        jp      z, parse_do_jmptable    ; is the same? Yes, jump to subroutine
        inc     B                       ; No, increment subroutine counter
        jp      parse_loop              ;     and check next command in jump table
parse_do_jmptable:
        ld      A, B                    ; If subroutine number
        cp      JMPTABLE_LENGTH         ;   is invalid
        ccf                             ;   then set Carry flag
        ret     c                       ;   and return

        add     A, A                    ; double index for word length entries
        ld      HL, cmd_jmptable        ; HL = pointer to jump table
        add     A, L                    ; A = points to subroutine in jump table
        ld      L, A                    ; Copy subroutine address
        xor     A                       ;   within jump table
        adc     A, H                    ;   to
        ld      H, A                    ;   HL

        ld      A, (HL)                 ; Copy address
        inc     HL                      ;   of subroutine
        ld      H, (HL)                 ;   from 
        ld      L, A                    ;   jump table
        ex      (SP), HL                ;   to Stack Pointer, so that when
        ret                             ;   doing ret it goes to the address
parse_get_from_jtable:
        ld      DE, cmd_list_table      ; DE = points to list of commands table
        add     HL, DE                  ; HL = points to subroutine number (with offset)
        ld      E, (HL)                 ; Copy address
        inc     HL                      ;   to
        ld      D, (HL)                 ;   HL
        ret
;------------------------------------------------------------------------------
F_CLI_CHECK_1_PARAM:
; Check if parameters 1 was specified
        call    check_param1
        jp      z, cli_promptloop       ; param1 specified? No, exit routine
        ret                             ; yesm go back to caller
;------------------------------------------------------------------------------
F_CLI_CHECK_2_PARAMS:
; Check if both parameters were specified
        call    check_param1
        jp      z, cli_promptloop       ; param1 specified? No, go back to CLI prompt
        call    check_param2            ; yes, check param2
        jp      z, cli_promptloop       ; no, go back to CLI prompt
        ret                             ; yesm go back to caller
;------------------------------------------------------------------------------
check_param1:
; Check if buffer parameters were specified
; OUT => Z flag = 1 command doesn't exist
;                 0 command does exist
        ld      A, (CLI_buffer_parm1_val)   ; get what's in param1
        jp      check_param
check_param2:
        ld      A, (CLI_buffer_parm2_val)   ; get what's in param2
check_param:
        cp      0                           ; was a parameter specified?
                                            ; ToDo - this will fail if parameter was a zero
        jp      z, bad_params               ; no, show error and exit subroutine
        ret
bad_params:
        ld      HL, error_9002
        ld      A, (col_CLI_error)
        call    F_KRN_SERIAL_WRSTRCLR
        ret
;------------------------------------------------------------------------------
param1val_uppercase:
; converts CLI_buffer_parm1_val to uppercase
        ld      HL, CLI_buffer_parm1_val - 1
        jp      p1vup_loop
param2val_uppercase:
; converts CLI_buffer_parm2_val to uppercase
        ld      HL, CLI_buffer_parm2_val - 1
p1vup_loop:
        inc     HL
        ld      A, (HL)
        cp      0
        jp      z, plvup_end
        call    F_KRN_TOUPPER
        ld      (HL), A
        jp      p1vup_loop
plvup_end:
        ret
;------------------------------------------------------------------------------
search_cmd:
; Compare buffered command with a valid command syntax
; IN <= DE = command to check against to
; OUT => Z flag = 1 if DE=HL, which means the command matches
;                 0 if one letter isn't equal = command doesn't match
        ld      HL, CLI_buffer_cmd
        dec     DE
loop_search_cmd:
        cp      ' '                     ; is it a space (start parameter)?
        ret     z                       ; yes, return
        inc     DE                      ; no, continue checking
        ld      A, (DE)
        cpi                             ; compare content of A with HL, and increment HL
        jp      z, test_end_hl          ; A = (HL)
        ret     nz
test_end_hl:                            ; check if end (0) was reached on buffered command
        ld      A, (HL)
        cp      0
        jp      z, test_end_de
        jp      loop_search_cmd
test_end_de:                            ; check if end (0) was reached on command to check against to
        inc     DE
        ld      A, (DE)
        cp      0
        ret
;==============================================================================
; Memory Routines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_CLRCLIBUFFS:
; Clear CLI buffers
; Clears the buffers used for F_CLI_READCMD, so they are ready for a new command
        ld      HL, CLI_buffer_cmd
        ld      BC, 15
        xor     A
        call    F_KRN_SETMEMRNG

        ld      HL, CLI_buffer_parm1_val
        ld      BC, 15
        xor     A
        call    F_KRN_SETMEMRNG

        ld      HL, CLI_buffer_parm2_val
        ld      BC, 15
        xor     A
        call    F_KRN_SETMEMRNG

        ld      HL, CLI_buffer_pgm
        ld      BC, 31
        xor     A
        call    F_KRN_SETMEMRNG

        ld      HL, CLI_buffer_full_cmd
        ld      BC, 63
        xor     A
        call    F_KRN_SETMEMRNG

        ret
;==============================================================================
; Messages
;==============================================================================
ANSI_CURSOR_BACK:
        .BYTE   $1B, "[1D"       ; Move cursor left 1 column

msg_cli_version:
        .BYTE   CR, LF
        .BYTE   "CLI v0.1.0", 0
msg_prompt:
        .BYTE   CR, LF
        .BYTE   "DSK", 0
msg_prompt_hex:
        .BYTE   CR, LF
        .BYTE   "$ ", 0
msg_ok:
        .BYTE   CR, LF
        .BYTE   "OK", 0
msg_dirlabel:
        .BYTE   "<DIR>", 0
msg_crc_ok:
        .BYTE   " ...[CRC OK]", CR, LF, 0
msg_exeloaded:
        .BYTE   CR, LF
        .BYTE   "Executable loaded at: 0x", 0
msg_disk_cat_title:
        .BYTE   CR, LF
        .BYTE   CR, LF
        .BYTE   "Disk Catalogue", CR, LF, 0
msg_disk_cat_sep:
        .BYTE   "--------------------------------------------------------------------------------", CR, LF, 0
msg_disk_cat_detail:
        .BYTE   "File            Type   Last Modified          Load Address   Attributes   Size", CR, LF, 0
msg_disk_file_loaded:
        .BYTE   CR, LF
        .BYTE   "File loaded successfully at address: $", 0
msg_disk_file_renamed:
        .BYTE   CR, LF
        .BYTE   "File renamed", 0
msg_disk_file_deleted:
        .BYTE   CR, LF
        .BYTE   "File deleted", 0
msg_disk_file_attr_chged:
        .BYTE   CR, LF
        .BYTE   "File Attributes changed", 0
msg_disk_file_saved:
        .BYTE   CR, LF
        .BYTE   "File saved", 0
msg_sd_erase_start:
        .BYTE   CR, LF
        .BYTE   "Erasing disk", 0
msg_disk_format_confirm:
        .BYTE   CR, LF
        .BYTE   "All data in the disk will be destroyed!", CR, LF
        .BYTE   "Do you want to continue? (yes/no) ", 0
msg_disk_diskinfo_hdr:
        .BYTE   CR, LF
        .BYTE   "Disk Information", 0
msg_format_end:
        .BYTE   CR, LF
        .BYTE   "Disk was successfully formatted", CR, LF, 0
msg_lowlvlformat_end:
        .BYTE   CR, LF
        .BYTE   "Disk was successfully low-level formatted", CR, LF
        .BYTE   "But still needs formatdsk to be used", CR, LF, 0
msg_prompt_fname:
        .BYTE   CR, LF
        .BYTE   "filename? ", 0
msg_todayis:
        .BYTE   CR, LF
        .BYTE   "Today: ", 0
msg_nowis:
        .BYTE   CR, LF
        .BYTE   "Now: ", 0
msg_crcis:
        .BYTE   CR, LF
        .BYTE   "CRC16: 0x", 0
msg_disk0:
        .BYTE   "                      DISK0 ", 0
msg_fdd:
        .BYTE   "FDD", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_9001:
        .BYTE   CR, LF
        .BYTE   "Command unknown", CR, LF, 0
error_9002:
        .BYTE   CR, LF
        .BYTE   "Bad parameter(s)", CR, LF, 0
error_9003:
        .BYTE   CR, LF
        .BYTE   "File not found", CR, LF, 0
error_9004:
        .BYTE   CR, LF
        .BYTE   "New filename already exists", CR, LF, 0
error_9005:
        .BYTE   CR, LF
        .BYTE   "Unknown attribute letter was specified", CR, LF, 0
error_9006:
        .BYTE   CR, LF
        .BYTE   "Disk appears to be unformatted", CR, LF, 0
error_9007:
        .BYTE   CR, LF
        .BYTE   "File is protected", CR, LF, 0
error_9008:
        .BYTE   CR, LF
        .BYTE   "No disk in FDD drive", CR, LF, 0
error_9009:
        .BYTE   CR, LF
        .BYTE   "Disk is write protected", CR, LF, 0
error_9010:
        .BYTE   CR, LF
        .BYTE   "Command is only allowed for Floppy Disks", CR, LF, 0
error_9011:
        .BYTE   CR, LF
        .BYTE   "Error", CR, LF, 0
error_9012:
        .BYTE   CR, LF
        .BYTE   "Mode number incorrect. Valid modes 0 to 4.", CR, LF, 0
;==============================================================================
; Tables
;==============================================================================
; File Types
tab_file_types:
        .BYTE   "USR"                   ; $0 = User defined
        .BYTE   "EXE"                   ; $1 = Executable binary
        .BYTE   "BIN"                   ; $2 = Binary (non-executable) data
        .BYTE   "BAS"                   ; $3 = BASIC code
        .BYTE   "TXT"                   ; $4 = Plain ASCII text file
        .BYTE   "SC1"                   ; $5 = Screen 1 (Graphics I Mode) Picture
        .BYTE   "FN6"                   ; $6 = Font (6×8) for Text Mode
        .BYTE   "SC2"                   ; $7 = Screen 2 (Graphics II Mode) Picture
        .BYTE   "FN8"                   ; $8 = Font (8×8) for Graphics Modes
        .BYTE   "SC3"                   ; $9 = Screen 3 (Multicolour Mode) Picture
        .BYTE   "---"                   ; $A = Unused
        .BYTE   "---"                   ; $B = Unused
        .BYTE   "---"                   ; $C = Unused
        .BYTE   "---"                   ; $D = Unused
        .BYTE   "---"                   ; $E = Unused
        .BYTE   "---"                   ; $F = Unused

;==============================================================================
; CLI Modules
;==============================================================================
#include "src/CLI/CLI.jmptab.asm"
#include "src/CLI/CLI.cmds.asm"
