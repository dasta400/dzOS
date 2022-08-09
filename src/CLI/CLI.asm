;******************************************************************************
; CLI.asm
;
; Command-Line Interface
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

; ToDo - Calls to functions should be to RAM jumpblock addresses

;==============================================================================
; Includes
;==============================================================================
#include "src/equates.inc"
#include "exp/BIOS.exp"
#include "exp/kernel.exp"
#include "exp/sysvars.exp"

;==============================================================================
; General Routines
;==============================================================================
        .ORG    CLI_START
cli_welcome:
        ld      HL, msg_cli_version     ; CLI start up message
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ; output 1 empty line
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

;TODO        ; Show Free available RAM
        ; ld      HL, FREERAM_TOTAL
        ; ld      HL, msg_bytesfree
        ; call    F_KRN_SERIAL_WRSTRCLR

cli_promptloop:         .EXPORT     cli_promptloop
        call    F_CLI_CLRCLIBUFFS       ; Clear buffers
        ld      HL, msg_prompt          ; Prompt
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, ANSI_COLR_WHT        ; Set text colour
        call    F_KRN_SERIAL_SETFGCOLR  ;   for user input
        ld      HL, CLI_buffer_cmd      ; address where commands are buffered

        ld      A, 0
        ld      (CLI_buffer_cmd), A
        call    F_CLI_READCMD
        call    F_CLI_PARSECMD
        jp      c, cli_command_unknown
        jp      cli_promptloop
cli_command_unknown:
        ld      HL, error_1001
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop
;------------------------------------------------------------------------------
F_CLI_READCMD:
; Read string containing a command and parameters
; Read characters from the Console into a memory buffer until RETURN is pressed.
; Parameters (identified by comma) are detected and stored in 'parameters buffer',
; meanwhile the command is stored in 'command buffer'.
        ld      IX, CLI_buffer_full_cmd
readcmd_loop:
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (IX), A                 ; store full command
        inc     IX                      ;   in special buffer
        cp      ' '                     ; test for 1st parameter entered
        jp      z, was_param
        cp      ','                     ; test for 2nd parameter entered
        jp      z, was_param
        ; test for special keys
;        cp        key_backspace            ; Backspace?
;        jp        z, was_backspace        ; yes, don't add to buffer
;        cp        key_up                    ; up arrow?
;        jp        z, no_buffer            ; yes, don't add to buffer
;        cp        key_down                ; down arrow?
;        jp        z, no_buffer            ; yes, don't add to buffer
;        cp        key_left                ; left arrow?
;        jp        z, no_buffer            ; yes, don't add to buffer
;        cp        key_right                ; right arrow?
;        jp        z, no_buffer            ; yes, don't add to buffer

        cp      CR                      ; ENTER?
        jp      z, end_get_cmd          ; yes, command was fully entered
        ld      (HL), A                 ; store character in buffer
        inc     HL                      ; buffer pointer + 1
no_buffer:
        jp      readcmd_loop            ; don't add last entered char to buffer
        ret
was_backspace:    
        dec     HL                      ; go back 1 unit on the buffer pointer
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
        call    search_cmd              ;    with command entered by user
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
        ld      A, 0                    ;   within jump table
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
        jp      z, bad_params               ; no, show error and exit subroutine
        ret
bad_params:
        ld      HL, error_1002
        ld      A, ANSI_COLR_RED
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
        ld      A, 0
        call    F_KRN_SETMEMRNG

        ld      HL, CLI_buffer_parm1_val
        ld      BC, 15
        ld      A, 0
        call    F_KRN_SETMEMRNG

        ld      HL, CLI_buffer_parm2_val
        ld      BC, 15
        ld      A, 0
        call    F_KRN_SETMEMRNG
        ret
;==============================================================================
; Messages
;==============================================================================
msg_cli_version:
        .BYTE   "CLI    v1.0.0", 0
; msg_bytesfree:
;         .BYTE   " Bytes free", 0
msg_prompt:
        .BYTE   CR, LF
        .BYTE   "> "
        .BYTE   0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
        .BYTE   CR, LF
        .BYTE   "Command unknown (type help for list of available commands)", CR, LF, 0
error_1002:
        .BYTE   CR, LF
        .BYTE   "Bad parameter(s)", CR, LF, 0
;==============================================================================
; CLI Modules
;==============================================================================
#include "src/CLI/CLI.jmptab.asm"
#include "src/CLI/CLI.cmds.asm"

;==============================================================================
; END of CODE
;==============================================================================
        .ORG    CLI_END
        .BYTE   0
        .END