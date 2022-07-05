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
        ld      HL, msg_cli_version        ; CLI start up message
        call    F_KRN_SERIAL_WRSTR                ; Output message
        ; output 1 empty line
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

;TODO        ; Show Free available RAM
        ; ld      HL, FREERAM_TOTAL

cli_promptloop:
        call    F_CLI_CLRCLIBUFFS        ; Clear buffers
        ld        hl, msg_prompt          ; Prompt
        call    F_KRN_SERIAL_WRSTR        ; Output message
        ld        hl, CLI_buffer_cmd        ; address where commands are buffered

        ld        a, 0
        ld        (CLI_buffer_cmd), a
        call    F_CLI_READCMD
        call    F_CLI_PARSECMD
        jp      cli_promptloop
;------------------------------------------------------------------------------
F_CLI_READCMD:
; Read string containing a command and parameters
; Read characters from the Console into a memory buffer until RETURN is pressed.
; Parameters (identified by comma) are detected and stored in 'parameters buffer',
; meanwhile the command is stored in 'command buffer'.
        ld        IX, CLI_buffer_full_cmd
readcmd_loop:
        call    F_KRN_SERIAL_RDCHARECHO    ; read a character, with echo
        ld        (IX), A                    ; store full command
        inc        IX                        ;   in special buffer
        cp        ' '                        ; test for 1st parameter entered
        jp        z, was_param
        cp        ','                        ; test for 2nd parameter entered
        jp        z, was_param
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

        cp        CR                        ; ENTER?
        jp        z, end_get_cmd            ; yes, command was fully entered
        ld        (hl), a                    ; store character in buffer
        inc        hl                        ; buffer pointer + 1
no_buffer:
        jp        readcmd_loop            ; don't add last entered char to buffer
        ret
was_backspace:    
        dec        hl                        ; go back 1 unit on the buffer pointer
        jp        readcmd_loop            ; read another character
was_param:
        ld        a, (CLI_buffer_parm1_val)
        cp        00h                        ; is buffer area empty (=00h)?
        jp        z, add_value1            ; yes, add character to buffer area
        ld        a, (CLI_buffer_parm2_val)
        cp        00h                        ; is buffer area empty (=00h)?
        jp        z, add_value2            ; yes, add character to buffer area
        jp        readcmd_loop            ; read next character
add_value1:
        ld        hl, CLI_buffer_parm1_val
        jp        readcmd_loop
add_value2:
        ld        hl, CLI_buffer_parm2_val
        jp        readcmd_loop
end_get_cmd:
        ret
;------------------------------------------------------------------------------
F_CLI_PARSECMD:
; Parse command
; Parses entered command and calls related subroutine.
        ld        hl, CLI_buffer_cmd
        ld        a, (hl)
        cp        00h                        ; just an ENTER?
        jp        z, cli_promptloop        ; show prompt again
        ;search command "cat" (disk catalogue)
        ld        de, _CMD_CF_CAT
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_CF_CAT        ; yes, then execute the command
        ;search command "load" (load file)
        ld        DE,_CMD_CF_LOAD
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_CF_LOAD        ; yes, then execute the command
        ;search command "rename" (load file)
        ld      DE,_CMD_CF_RENAME
        call    search_cmd              ; was the command that we were searching?
        jp      z, CLI_CMD_CF_RENAME    ; yes, then execute the command
        ;search command "delete" (load file)
        ld      DE,_CMD_CF_DELETE
        call    search_cmd              ; was the command that we were searching?
        jp      z, CLI_CMD_CF_DELETE    ; yes, then execute the command
        ;search command "help"
        ld        de, _CMD_HELP
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_HELP            ; yes, then execute the command
        ;search command "run"
        ld        de, _CMD_RUN
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_RUN            ; yes, then execute the command
        ;search command "peek"
        ld        de, _CMD_PEEK
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_PEEK            ; yes, then execute the command
        ;search command "poke"
        ld        de, _CMD_POKE
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_POKE            ; yes, then execute the command
        ;search command "autopoke"
        ld        de, _CMD_AUTOPOKE
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_AUTOPOKE        ; yes, then execute the command
        ;search command "halt"
        ld        de, _CMD_HALT
        call    search_cmd                ; was the command that we were searching?
        jp        z, F_BIOS_SYSHALT        ; yes, then execute the command
        ;search command "reset"
        ld        de, _CMD_RESET
        call    search_cmd                ; was the command that we were searching?
        jp        z, F_BIOS_WBOOT            ; yes, then execute the command
        ;search command "formatdsk"
        ld        de, _CMD_CF_FORMATDSK
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_CF_FORMATDSK    ; yes, then execute the command
        ;search command "MEMDUMP" (load file)
        ld        de, _CMD_MEMDUMP
        call    search_cmd                ; was the command that we were searching?
        jp        z, CLI_CMD_MEMDUMP        ; yes, then execute the command
        ;search command "chgattr" (load file)
        ld      DE,_CMD_CF_CHGATTR
        call    search_cmd              ; was the command that we were searching?
        jp      z, CLI_CMD_CF_CHGATTR    ; yes, then execute the command
        ;search command "diskinfo" (load file)
        ld      DE,_CMD_CF_DISKINFO
        call    search_cmd              ; was the command that we were searching?
        jp      z, CLI_CMD_CF_DISKINFO  ; yes, then execute the command
no_match:    ; unknown command entered
        ld        hl, error_1001
        call    F_KRN_SERIAL_WRSTR
        jp        cli_promptloop
;------------------------------------------------------------------------------
search_cmd:
; compare buffered command with a valid command syntax
;    IN <= DE = command to check against to
;    OUT => Z flag    1 if DE=HL, which means the command matches
;            0 if one letter isn't equal = command doesn't match
        ld        hl, CLI_buffer_cmd
        dec        de
loop_search_cmd:
        cp        ' '                        ; is it a space (start parameter)?
        ret        z                        ; yes, return
        inc        de                        ; no, continue checking
        ld        a, (de)
        cpi                                ; compare content of A with HL, and increment HL
        jp        z, test_end_hl            ; A = (HL)
        ret nz
test_end_hl:                            ; check if end (0) was reached on buffered command
        ld        a, (hl)
        cp        0
        jp        z, test_end_de
        jp        loop_search_cmd
test_end_de:                            ; check if end (0) was reached on command to check against to
        inc        de
        ld        a, (de)
        cp        0
        ret
;------------------------------------------------------------------------------
check_param1:
; Check if buffer parameters were specified
;    OUT => Z flag =    1 command doesn't exist
;                    0 command does exist
        ld        A, (CLI_buffer_parm1_val)    ; get what's in param1
        jp        check_param                    ; check it
check_param2:
        ld        A, (CLI_buffer_parm2_val)        ; get what's in param2
check_param:
        cp        0                            ; was a parameter specified?
        jp        z, bad_params                ; no, show error and exit subroutine
        ret
bad_params:
        ld        HL, error_1002                ; load bad parameters error text
        call    F_KRN_SERIAL_WRSTR            ; print it
        ret
;------------------------------------------------------------------------------
param1val_uppercase:
; converts CLI_buffer_parm1_val to uppercase
        ld        hl, CLI_buffer_parm1_val - 1
        jp        p1vup_loop
param2val_uppercase:
; converts CLI_buffer_parm2_val to uppercase
        ld        hl, CLI_buffer_parm2_val - 1
p1vup_loop:
        inc        hl
        ld        a, (hl)
        cp        0
        jp        z, plvup_end
        call    F_KRN_TOUPPER
        ld        (hl), a
        jp        p1vup_loop
plvup_end:
        ret
;==============================================================================
; Memory Routines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_CLRCLIBUFFS:
; Clear CLI buffers
; Clears the buffers used for F_CLI_READCMD, so they are ready for a new command
        ld        hl, CLI_buffer_cmd
        ld        BC, 15
        ld        a, 0
        call    F_KRN_SETMEMRNG

        ld        hl, CLI_buffer_parm1_val
        ld        BC, 15
        ld        a, 0
        call    F_KRN_SETMEMRNG

        ld        hl, CLI_buffer_parm2_val
        ld        BC, 15
        ld        a, 0
        call    F_KRN_SETMEMRNG
        ret
;==============================================================================
; CLI available Commands
;==============================================================================
;------------------------------------------------------------------------------
;    help - Show list of available commands
;------------------------------------------------------------------------------
CLI_CMD_HELP:
        ld        hl, msg_help
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
;    peek - Prints the value of a single memory address
;------------------------------------------------------------------------------
CLI_CMD_PEEK:
;    IN <=     CLI_buffer_parm1_val = address
;    OUT => default output (e.g. screen, I/O)
    ; Check if parameter 1 was specified
        call    check_param1
        jp        nz, peek                ; param1 specified? Yes, do the peek
        ret                                ; no, exit routine
peek:
        call    param1val_uppercase
;        ld        hl, empty_line            ; print an empty line
;        call    F_KRN_SERIAL_WRSTR
        ld        b, 1
        call     F_KRN_SERIAL_EMPTYLINES
    ; CLI_buffer_parm1_val has the value in hexadecimal
    ; we need to convert it to binary
        ld        a, (CLI_buffer_parm1_val)
        ld        h, a
        ld        a, (CLI_buffer_parm1_val + 1)
        ld        l, a
        call    F_KRN_ASCII_TO_HEX
        ld        d, a
        ld        a, (CLI_buffer_parm1_val + 2)
        ld        h, a
        ld        a, (CLI_buffer_parm1_val + 3)
        ld        l, a
        call    F_KRN_ASCII_TO_HEX
        ld        e, a
    ; DE contains the binary value for param1
        ex        de, hl                    ; move from DE to HL (param1)
        ld        a, (hl)                    ; load value at address of param1
        call    F_KRN_SERIAL_PRN_BYTE    ; Prints byte in hexadecimal notation
        ret
;------------------------------------------------------------------------------
;    poke - calls poke subroutine that changes a single memory address 
;          to a specified value
;------------------------------------------------------------------------------
CLI_CMD_POKE:
;    IN <=     CLI_buffer_parm1_val = memory address
;             CLI_buffer_parm2_val = specified value
;    OUT => print message 'OK' to default output (e.g. screen, I/O)
    ; Check if both parameters were specified
        call    check_param1
        ret        z                        ; param1 specified? No, exit routine
        call    check_param2            ; yes, check param2
        ; jp        nz, poke                ; param2 specified? Yes, do the poke
        ; ret                                ; no, exit routine
        ret        z                        ; param2 specified? No, exit routine
        ; yes, change the value
        call    param1val_uppercase
        call    param2val_uppercase
        call    F_KRN_ASCII_TO_HEX        ; Hex ASCII to Binary conversion
        ; CLI_buffer_parm1_val have the address in hexadecimal ASCII
        ; we need to convert its hexadecimal value (e.g. 33 => 03)
        ld        IX, CLI_buffer_parm1_val
        call    F_KRN_ASCIIADR_TO_HEX
        push    HL                        ; Backup HL
        ; CLI_buffer_parm2_val have the value in hexadecimal ASCII
        ; we need to convert its hexadecimal value (e.g. 33 => 03)
        ld        a, (CLI_buffer_parm2_val)
        ld        h, a
        ld        a, (CLI_buffer_parm2_val + 1)
        ld        l, a
        call    F_KRN_ASCII_TO_HEX        ; A contains the binary value for param2
        pop        HL                        ; Restore HL
        ld        (hl), a                    ; Store value in address
        ; print OK, to let the user know that the command was successful
        ld        hl, msg_ok
        call    F_KRN_SERIAL_WRSTR
        ret

;------------------------------------------------------------------------------
;    autopoke - Allows to enter hexadecimal values that will be stored at the
;              address in parm1 and consecutive positions.
;              The address is incremented automatically after each hexadecimal 
;              value is entered. 
;              Entering no value (i.e. just press ENTER) will stop the process.
;------------------------------------------------------------------------------
CLI_CMD_AUTOPOKE:
;    IN <=     CLI_buffer_parm1_val = Start address
        call    check_param1
        ret        z                        ; param1 specified? No, exit routine
        ; yes, convert address from ASCII to its hex value
        ld        IX, CLI_buffer_parm1_val
        call    F_KRN_ASCIIADR_TO_HEX
        ; Use IX as pointer to memory address where the values entered by
        ; the user will be stored. It's incremented after each value is entered
        ld        (tmp_addr1), HL
        ld        IX, (tmp_addr1)
autopoke_loop:
        ; show a dollar symbol to indicate the user that can enter an hexadecimal
        ld        hl, msg_prompt_hex      ; Prompt
        call    F_KRN_SERIAL_WRSTR      ; Output message
        ; read 1st character
        call    F_KRN_SERIAL_RDCHARECHO    ; read a character, with echo
        cp        CR                        ; test for 1st parameter entered
        jp        z, end_autopoke            ; if it's CR, exit subroutine
        call    F_KRN_TOUPPER
        ld        H, A                    ; H = value's 1st digit
        ; read 2nd character
        call    F_KRN_SERIAL_RDCHARECHO    ; read a character, with echo
        cp        CR                        ; test for 1st parameter entered
        jp        z, end_autopoke                ; if it's CR, exit subroutine
        call    F_KRN_TOUPPER
        ld        L, A                    ; L = value's 2nd digit
        ; convert HL from ASCII to hex
        call    F_KRN_ASCII_TO_HEX        ; A = HL in hex
        ; Do the poke (i.e. store specified value at memory address)
        ld        (IX), A
        ; Increment memory address pointer and loop back to get next value
        inc        IX
        jp        autopoke_loop
end_autopoke:
        ret
;------------------------------------------------------------------------------
;    memdump - Shows memory contents of an specified section of memory
;------------------------------------------------------------------------------
CLI_CMD_MEMDUMP:
;    IN <= CLI_buffer_parm1_val = Start address
;          CLI_buffer_parm2_val = End address
;    OUT => default output (e.g. screen, I/O)

        ; Check if both parameters were specified
        call    check_param1
        ret        z                        ; param1 specified? No, exit routine
        call    check_param2            ; yes, check param2
        ret        z                        ; no, exit routine
memdump:
        ; print header
        ld        hl, msg_memdump_hdr
        call    F_KRN_SERIAL_WRSTR
    ; CLI_buffer_parm2_val have the value in hexadecimal
    ; we need to convert it to binary
        ld        a, (CLI_buffer_parm2_val)
        ld        h, a
        ld        a, (CLI_buffer_parm2_val + 1)
        ld        l, a
        call    F_KRN_ASCII_TO_HEX
        ld        d, a
        ld        a, (CLI_buffer_parm2_val + 2)
        ld        h, a
        ld        a, (CLI_buffer_parm2_val + 3)
        ld        l, a
        call    F_KRN_ASCII_TO_HEX
        ld        e, a
    ; DE contains the binary value for param2
        push    de                        ; store in the stack
    ; CLI_buffer_parm1_val have the value in hexadecimal
    ; we need to convert it to binary
        ld        a, (CLI_buffer_parm1_val)
        ld        h, a
        ld        a, (CLI_buffer_parm1_val + 1)
        ld        l, a
        call    F_KRN_ASCII_TO_HEX
        ld        d, a
        ld        a, (CLI_buffer_parm1_val + 2)
        ld        h, a
        ld        a, (CLI_buffer_parm1_val + 3)
        ld        l, a
        call    F_KRN_ASCII_TO_HEX
        ld        e, a
    ; DE contains the binary value for param1
        ex        de, hl                    ; move from DE to HL (HL=param1)
        pop        de                        ; restore from stack (DE=param2)
start_dump_line:
        ld        c, 20                    ; we will print 23 lines per page
dump_line:
        push    hl
        ld        a, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld        a, LF
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_KRN_SERIAL_PRN_WORD
        ld        a, ':'                    ; semicolon separates mem address from data
        call    F_BIOS_SERIAL_CONOUT_A
        ld        a, ' '                    ; and an extra space to separate
        call    F_BIOS_SERIAL_CONOUT_A
        ld        b, 10h                    ; we will output 16 bytes in each line
dump_loop:
        ld        a, (hl)
        call    F_KRN_SERIAL_PRN_BYTE
        ld        a, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        inc        hl
        djnz    dump_loop
        ; dump ASCII characters
        pop        hl
        ld        b, 10h                    ; we will output 16 bytes in each line
        ld        a, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_BIOS_SERIAL_CONOUT_A
ascii_loop:
        ld        a, (hl)
        call    F_KRN_IS_PRINTABLE        ; is it an ASCII printable character?
        jr        c, printable
        ld        a, '.'                    ; if is not, print a dot
printable:
        call    F_BIOS_SERIAL_CONOUT_A
        inc        hl
        djnz    ascii_loop

        push    hl                        ; backup HL before doing sbc instruction
        and        a                        ; clear carry flag
        sbc        hl, de                    ; have we reached the end address?
        pop        hl                        ; restore HL
        jr        c, dump_next            ; end address not reached. Dump next line
        ret
dump_next:
        dec        c                        ; 1 line was printed
        jp        z, askmoreorquit         ; we have printed 23 lines. More?
        jp         dump_line                ; print another line
askmoreorquit:
        push    hl                        ; backup HL
        ld        hl, msg_moreorquit
        call    F_KRN_SERIAL_WRSTR
        call    F_BIOS_SERIAL_CONIN_A    ; read key
        cp        SPACE                    ; was the SPACE key?
        jp        z, wantsmore            ; user wants more
        pop        hl                        ; yes, user wants more. Restore HL
        ret                                ; no, user wants to quit
wantsmore:
        ; print header
        ld        hl, msg_memdump_hdr
        call    F_KRN_SERIAL_WRSTR
        pop        hl                        ; restore HL
        jp        start_dump_line            ; return to start, so we print 23 more lines
;------------------------------------------------------------------------------
;    run - Starts running instructions from a specific memory address
;------------------------------------------------------------------------------
CLI_CMD_RUN:    ; TODO - It is running without full filename (e.g. disk runs diskinfo)
;    IN <=     CLI_buffer_parm1_val = address
    ; Check if parameter 1 was specified
        call    check_param1
        ret        z                        ; exit subroutine if param1 was not specified
check_addr_or_filename:
        ; Check if param1 is an address (i.e. starts with a number) or a filename
        ld        A, (CLI_buffer_parm1_val)    ; check if the 1st character of param1
        call    F_KRN_IS_NUMERIC        ;   is a number
        jr        c, runner_addr            ; is number? Yes, run from memory address
runner_filename:                        ; No, load and run file
        ; filename is the first parameter, so can call load command directly
        call    CLI_CMD_CF_LOAD
        ld        A, (tmp_byte)            ; Was the file loaded correctly?
        cp        $EF                        ; EF means there was an error
        ret        z                        ; no loaded, exit subroutine
        ; file was loaded, run it
        ld        HL, (CF_cur_file_load_addr)
        jp        (HL)                    ; jump execution to address in HL
runner_addr:
        call    param1val_uppercase
        ; CLI_buffer_parm1_val have the value in hexadecimal
        ; we need to convert it to binary
        ld        A, (CLI_buffer_parm1_val)
        ld        H, A
        ld        A, (CLI_buffer_parm1_val + 1)
        ld        L, A
        call    F_KRN_ASCII_TO_HEX
        ld        D, A
        ld        A, (CLI_buffer_parm1_val + 2)
        ld        H, A
        ld        A, (CLI_buffer_parm1_val + 3)
        ld        L, A
        call    F_KRN_ASCII_TO_HEX
        ld        E, A
        ; DE contains the binary value for param1
        ex        DE, HL                    ; move from DE to HL (param1)
        jp        (HL)                    ; jump execution to address in HL
        ret
;------------------------------------------------------------------------------
;     cat - Shows disk catalogue
;------------------------------------------------------------------------------
CLI_CMD_CF_CAT:
        ; print header
        ld        HL, msg_cf_cat_title
        call    F_KRN_SERIAL_WRSTR
        ld        HL, msg_cf_cat_sep
        call    F_KRN_SERIAL_WRSTR
        ld        HL, msg_cf_cat_detail
        call    F_KRN_SERIAL_WRSTR
        ld        HL, msg_cf_cat_sep
        call    F_KRN_SERIAL_WRSTR
        ; print catalogue
        call    F_CLI_CF_PRINT_DISKCAT
        ret
;------------------------------------------------------------------------------
;     load - Load filename from disk to RAM
;------------------------------------------------------------------------------
CLI_CMD_CF_LOAD:    ; TODO - It is loading without full filename (e.g. disk loads diskinfo)
; IN <= CLI_buffer_parm1_val = Filename
; OUT => OK message on default output (e.g. screen, I/O) if file found
        ; Check parameter was specified
        call    check_param1
        ret     z                                ; param1 specified? No, exit routine
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_GET_FILE_BATENTRY    ; Yes, search filename in BAT
        ; Was the filename found?
        call    is_filename_found
        ; ld      A, (tmp_addr3)
        ; cp      $AB
        ; jp      z, load_filename_not_found        ; No, show error message
        ; ld      A, (tmp_addr3 + 1)
        ; cp      $BA
        jp      z, load_filename_not_found        ; No, show error message
        ; yes, continue
        ld        HL, (CF_cur_file_load_addr)        ; Load file into SYSVARS.CF_cur_file_load_addr
        ld        DE, (CF_cur_file_1st_sector)
        ld        IX, (CF_cur_file_size_sectors)
        call    F_KRN_DZFS_LOAD_FILE_TO_RAM
        ; show success message
        ld        HL, msg_cf_file_loaded
        call    F_KRN_SERIAL_WRSTR
        ; Show SYSVARS.CF_cur_file_load_addr
        ld        HL, (CF_cur_file_load_addr)
        call    F_KRN_SERIAL_PRN_WORD
        ld        B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ret
load_filename_not_found:
        ld        A, $EF                            ; Flag for 'run' command
        ld        (tmp_byte), A                    ; to indicate that the file was not run
        ld        HL, error_1003
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
;     formatdsk - Format CompactFlash disk
;------------------------------------------------------------------------------
CLI_CMD_CF_FORMATDSK:
;    IN <=     CLI_buffer_parm1_val = disk label
;             CLI_buffer_parm2_val = number of partitions
        ; Check if both parameters were specified
        call    check_param1
        ret        z                        ; param1 specified? No, exit routine
        call    check_param2            ; yes, check param2
        ret        z                        ; param2 specified? No, exit routine
        ; yes, check that param2 is not equal to 0
        ld        A, (CLI_buffer_parm2_val)
        cp        $30
        ret     z
        ; was not zero, continue
        call    param2val_uppercase
        ; Ask for confirmation before formatting
        ; User MUST reply with the word 'yes' to proceed.
        ; Any other word/character will cancel the formatting
        ld        HL, msg_cf_format_confirm
        call    F_KRN_SERIAL_WRSTR
        ld        IX, CLI_buffer_pgm            ; answer will be stored in CLI_buffer_pgm
format_answer_loop:
        call    F_KRN_SERIAL_RDCHARECHO        ; read a character, with echo
        cp        CR                            ; ENTER?
        jp        z, format_answer_end        ; yes, command was fully entered
        ld        (IX), A                        ; store character
        inc        IX                            ;   in buffer
        jp        format_answer_loop            ; no, read more characters
format_answer_end:
        ; Check that the answer is yes
        ld        IX, CLI_buffer_pgm
        ld        A, (IX)
        cp        'y'
        ret        nz
        ld        A, (IX + 1)
        cp        'e'
        ret        nz
        ld        A, (IX + 2)
        cp        's'
        ret        nz
        ; Answer was yes, then proceed to format the disk
        ld        HL, CLI_buffer_parm1_val
        ld        DE, CLI_buffer_parm2_val
        call    F_KRN_DZFS_FORMAT_CF
        ld      HL, msg_format_end
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
;     diskinfo - Show CompactFlash information
;------------------------------------------------------------------------------
CLI_CMD_CF_DISKINFO:
        call    F_KRN_DZFS_READ_SUPERBLOCK  ; get CF information from the Superblock
        ld      HL, msg_cf_diskinfo_hdr
        call    F_KRN_SERIAL_WRSTR
        call    F_KRN_DZFS_SHOW_DISKINFO
        ; File System id
        ; Volume Label
        ; Volume Date creation
        ; Volume Time creation
        ; Bytes per Sector
        ; Sectors per Block
        ; Number of Partitions
        ; Copyright
        ret
;------------------------------------------------------------------------------
;   rename - Renames a file with a specified filename to a new filename
;------------------------------------------------------------------------------
CLI_CMD_CF_RENAME:  ; TODO - Do not allow renaming System or Read Only files
                    ; TODO - It is renaming without full filename (e.g. disk renames diskinfo)
; IN <= CLI_buffer_parm1_val = old filename
;       CLI_buffer_parm2_val = new filename

        ; Check if both parameters were specified
        call    check_param1
        ret     z                       ; param1 specified? No, exit routine
        call    check_param2            ; yes, check param2
        ret     z                             ; no, exit routine
        ; Check that new filename doesn't already exists
        ld      HL, CLI_buffer_parm2_val
        call    F_KRN_DZFS_GET_FILE_BATENTRY
        ; Was the filename found?
        call    is_filename_found
        ; ld      A, (tmp_addr3)
        ; cp      $AB
        ; jp      z, check_old_filename   ; No, continue
        ; ld      A, (tmp_addr3 + 1)
        ; cp      $BA
        jp      z, check_old_filename   ; No, continue
        ; Old filename already exists, show error an exit
        ld      HL, error_1004
        call    F_KRN_SERIAL_WRSTR
        ret
check_old_filename:
        ; Check that old filename exists
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_GET_FILE_BATENTRY
        ; Was the filename found?
        call    is_filename_found
        ; ld      A, (tmp_addr3)
        ; cp      $AB
        ; jp      z, filename_notfound    ; No, error and exit
        ; ld      A, (tmp_addr3 + 1)
        ; cp      $BA
        jp      z, filename_notfound    ; No, error and exit
        ; Yes, do the renaming
        ld      DE, (CF_cur_file_entry_number)
        ld      IY, CLI_buffer_parm2_val
        call    F_KRN_DZFS_RENAME_FILE
        ; show success message
        ld      HL, msg_cf_file_renamed
        call    F_KRN_SERIAL_WRSTR
        ret
filename_notfound:
        ; Old filename already exists, show error an exit
        ld      HL, error_1003
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
;   delete - Deletes a file with a specified filename
;            The Kernel doesn't delete the file data. It just changes the
;               first character of the filename to ~
;------------------------------------------------------------------------------
CLI_CMD_CF_DELETE:      ; TODO - Do not allow delete System or Read Only files
                        ; TODO - It is deleting without full filename (e.g. disk deletes diskinfo)
; IN <= CLI_buffer_parm1_val = filename
        call    check_param1
        ret     z                               ; param1 specified? No, exit routine
        ; Search filename in BAT
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_GET_FILE_BATENTRY
        ; Was the filename found?
        call    is_filename_found
        ; ld      A, (tmp_addr3)
        ; cp      $AB
        ; jp      z, filename_notfound  ; No, show error message
        ; ld      A, (tmp_addr3 + 1)
        ; cp      $BA
        jp      z, filename_notfound  ; No, show error message
        ; yes, continue
        ld      DE, (CF_cur_file_entry_number)
        call    F_KRN_DZFS_DELETE_FILE
        ; show success message
        ld      HL, msg_cf_file_deleted
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
;   chgattr - Changes the attributes (RSHE) of a specified filename
;             The attributes entered by the user will become the new attributes
;               of the file. There is no option to remove a single attribute.
;------------------------------------------------------------------------------
CLI_CMD_CF_CHGATTR:     ; TODO - It is changing attribs without full filename (e.g. disk changes diskinfo)
; IN <= CLI_buffer_parm1_val = filename
;       CLI_buffer_parm2_val = new attributes

        ; Check if both parameters were specified
        call    check_param1
        ret     z                       ; param1 specified? No, exit routine
        call    check_param2            ; yes, check param2
        ret     z                             ; no, exit routine
        ; Check filename exists
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_GET_FILE_BATENTRY
        ; Was the filename found?
        call    is_filename_found
        jp      nz, chgattr             ; exists, change attributes
        ; doesn't exists, error and exit
        ld      HL, error_1003
        call    F_KRN_SERIAL_WRSTR
        ret
chgattr:
        ; Read each character of param2 and make up the mask byte as per
        ;   (0=Inactive / 1=Active)
        ;       Bit 0 = Read Only
        ;       Bit 1 = Hidden
        ;       Bit 2 = System
        ;       Bit 3 = Executable
        ;       Bit 4-7 = Not used
        ld      B, 1                    ; character counter
        ld      IX, CLI_buffer_parm2_val; pointer to characters in param2
        ld      HL, tmp_byte            ; pointer to final attribute mask byte
        ld      A, 0                    ; clear the
        ld      (tmp_byte), A           ;    mask byte
read_attr:
        ld      A, (IX)                 ; load attribute
        cp      'R'                     ; is it Read Only?
        jp      z, make_readonly        ; yes, make mask byte
        cp      'H'                     ; is it Hidden?
        jp      z, make_hidden          ; yes, make mask byte
        cp      'S'                     ; is it System?
        jp      z, make_system          ; yes, make mask byte
        cp      'E'                     ; is it Executable?
        jp      z, make_exec            ; yes, make mask byte
        cp      $00                     ; is it end of param2?
        jp      z, mask_done            ; yes, call Kernel routine
        jp      wrong_attr              ;  Error. It wasn't R, H, S or E.
next_attr:
        inc     IX                      ; next character in param2
        inc     B                       ; increment character counter
        ld      A, B                    ; did we process
        cp      5                       ;    5 characters already?
        jp      z, mask_done            ; yes, then we're finished
        jp      read_attr               ; no, process more characters
make_readonly:
        ld      A, (HL)
        or      1
        jp      make_done
make_hidden:
        ld      A, (HL)
        or      2
        jp      make_done
make_system:
        ld      A, (HL)
        or      4
        jp      make_done
make_exec
        ld      A, (HL)
        or      8
        jp      make_done
make_done:
        ld      (HL), A                 ; change mask byte
        jp      next_attr
wrong_attr:
        ld      HL, error_1005
        call    F_KRN_SERIAL_WRSTR
        ret
mask_done:
        ld      DE, (CF_cur_file_entry_number)
        ld      A, (tmp_byte)
        call    F_KRN_DZFS_CHGATTR_FILE
        ; show success message
        ld      HL, msg_cf_file_attr_chged
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
is_filename_found:
; IN <= tmp_addr3 filled by F_KRN_DZFS_GET_FILE_BATENTRY
; OUT => z is set if file not found
;
        ; When getting a BAT entry, the Kernel stores two bytes ($ABBA)
        ;   as default value in SYSVARS.tmp_addr3.
        ; These two bytes get replaced ($0000) if a file is found.
        ; Therefore, we can use it to detect if a file was found or not.
        ; Was the filename found?
        ld      A, (tmp_addr3)
        cp      $AB
        ret     z
        ld      A, (tmp_addr3 + 1)
        cp      $BA
        ret
;==============================================================================
; Disk subroutines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_CF_PRINT_DISKCAT:
; Prints the contents (catalogue) of the CompactFlash Disk
; All entries in the BAT are consecutive. When a new file is stored, it will be 
; stored in the next available (first character = $00=available, or $FF=deleted).
; Hence, once we can read the BAT, and once we find the first entry with $00, we
; know there are no more entries. The maximum number of entries is 1744
        ld      A, 1                        ; BAT starts at sector 1
        ld      (CF_cur_sector), A
        ld      A, 0
        ld      (CF_cur_sector + 1), A
diskcat_nextsector:
        call    F_KRN_DZFS_READ_BAT_SECTOR
        ; As we read in groups of 512 bytes (Sector), 
        ; each read will put 16 entries in the buffer.
        ; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
        ; therefore 64 sectors.
        ld        A, 0                        ; entry counter
diskcat_print:
        push     AF
        call    F_KRN_DZFS_BATENTRY2BUFFER

        ; Check if the file should be displayed
        ; i.e. first character is not 7E (deleted)
        ;      and attribute bit 1 (hidden) is not 1
        ; If first character is 00, then there aren't more entries.
        ld        A, (CF_cur_file_name)
;TODO - uncomment after tests        cp        $7E                            ; File is deleted?
;TODO - uncomment after tests        jp        z, diskcat_nextentry        ; Yes, skip it
        cp        $00                            ; Available entry? (i.e. no file)
        jp        z, diskcat_end                ; Yes, no more entries then
        ld        A, (CF_cur_file_attribs)
        and        2                            ; File is hidden?
        jp        nz,    diskcat_nextentry        ; Yes, skip it

        ; Print entry data
        ; Filename
        ld        B, 14
        ld        HL, CF_cur_file_name
        call    F_KRN_SERIAL_PRN_BYTES
        call    print_a_space
        call    print_a_space

        ; Date created
; TODO - Need to convert into DD-MM-YYYY
        ld        A, 'D'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'D'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, '-'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, '-'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        call    print_a_space
        call    print_a_space
        ; Time created
; TODO - Need to convert into hh:mm:ss        
        ; call    F_KRN_TRANSLT_TIME
        ld        A, 'H'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'H'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'S'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'S'
        call    F_BIOS_SERIAL_CONOUT_A
        call    print_a_space
        call    print_a_space
        ; Date last modif.
; TODO - Need to convert into DD-MM-YYYY
        ld        A, 'D'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'D'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, '-'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, '-'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'Y'
        call    F_BIOS_SERIAL_CONOUT_A
        call    print_a_space
        call    print_a_space
        ; Time last modif.
; TODO - Need to convert into hh:mm:ss
        ld        A, 'H'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'H'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'M'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'S'
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, 'S'
        call    F_BIOS_SERIAL_CONOUT_A
        call    print_a_space
        call    print_a_space
        ; Size
        ld        IY, CF_cur_file_size_bytes
        ld        E, (IY)                        ; E = MSB
        ld        D, (IY + 1)                    ; D = LSB
        ex        DE, HL                        ; H = 1st byte (LSB), L = 2nd byte (LSB)
        call    F_KRN_BIN_TO_BCD6
        ex        DE, HL                        ; HL = converted 6-digit BCD
        ld        DE, CLI_buffer_pgm                ; where the numbers in ASCII will be stored
        call    F_KRN_BCD_TO_ASCII
        ; Print each of the 6 digits
        ld        IY, CLI_buffer_pgm
        ld        A, (IY + 0)
        call    diskcat_space_when_zero
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, (IY + 1)
        call    diskcat_space_when_zero
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, (IY + 2)
        call    diskcat_space_when_zero
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, (IY + 3)
        call    diskcat_space_when_zero
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, (IY + 4)
        call    diskcat_space_when_zero
        call    F_BIOS_SERIAL_CONOUT_A
        ld        A, (IY + 5)
        call    diskcat_space_when_zero
        call    F_BIOS_SERIAL_CONOUT_A
        call    print_a_space
        call    print_a_space
        call    print_a_space
        ; Attributes (RHSE, R=Read Only, H=Hidden, S=System, E=Executable)
        call    F_CLI_CF_PRINT_ATTRBS
        
        ; Add CR + LF
        ld        B, 1
        call    F_KRN_SERIAL_EMPTYLINES
diskcat_nextentry:
        pop        AF
        inc        A                            ; next entry
        cp        16                            ; did we process the 16 entries?
        jp        nz, diskcat_print            ; No, process next entry
        ; More entries in other sectors?
        ld        A, (CF_cur_sector)
        inc        A                            ; increment sector counter
        ld        (CF_cur_sector), A                ; Did we process
        cp        64                            ;    64 sectors already?
; TODO - Change this 64, to be read from Superblock's Sectors per Block
        jp        nz, diskcat_nextsector        ; No, then process next sector
        jp        diskcat_end_nopop
diskcat_end:
        pop     AF                            ; needed because previous push AF    
diskcat_end_nopop:
        ret                                    ; Yes, then nothing else to do
diskcat_space_when_zero:
        cp        $30                        ; is it a 0?
        ret        nz                      ; no, then return
        ld        A, SPACE                ; yes, then change it for a space
        ret
;------------------------------------------------------------------------------
F_CLI_CF_PRINT_ATTRBS:
; Prints a string with letters (R=Read Only, H=Hidden, S=System, E=Executable)
; if file attribute is ON, or space if it's OFF
        ld        A, (CF_cur_file_attribs)
        push    AF
        and        1                            ; Read Only?
        jp        nz, cf_attrb_is_ro            ; No, print a space
        call    print_a_space
        jp        cf_attrib_hidden
cf_attrb_is_ro:                                ; Yes, print a dot
        ld        A, 'R'
        call    F_BIOS_SERIAL_CONOUT_A
cf_attrib_hidden:
        pop        AF
        push    AF
        and        2                            ; Hidden?
        jp        nz, cf_attrb_is_hidden        ; No, print a space
        call    print_a_space
        jp        cf_attrib_system
cf_attrb_is_hidden:                            ; Yes, print a dot
        ld        A, 'H'
        call    F_BIOS_SERIAL_CONOUT_A
cf_attrib_system:
        pop        AF
        push    AF
        and        4                            ; System?
        jp        nz, cf_attrb_is_system        ; No, print a space
        call    print_a_space
        jp        cf_attrib_executable
cf_attrb_is_system:                            ; Yes, print a dot
        ld        A, 'S'
        call    F_BIOS_SERIAL_CONOUT_A
cf_attrib_executable:
        pop        AF
        and        8                            ; Executable?
        jp        nz, cf_attrb_is_exec        ; No, print a space
        call    print_a_space
        jp        print_attribs_end
cf_attrb_is_exec:                            ; Yes, print a dot
        ld        A, 'E'
        call    F_BIOS_SERIAL_CONOUT_A
print_attribs_end:
        ret

print_a_space:
        ld        A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ret
;==============================================================================
; Messages
;==============================================================================
msg_cli_version:
        .BYTE   CR, LF
        .BYTE   "CLI    v1.0.0", 0
msg_bytesfree:
        .BYTE   " Bytes free", 0
msg_prompt:
        .BYTE   CR, LF
        .BYTE   "> ", 0
msg_prompt_hex:
        .BYTE   CR, LF
        .BYTE   "$ ", 0
msg_ok:
        .BYTE   CR, LF
        .BYTE   "OK", 0
msg_help:
        .BYTE   CR, LF
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
        .BYTE   "|-------------|-----------------------------------|--------------------|", 0
msg_dirlabel:
        .BYTE   "<DIR>", 0
msg_crc_ok:
        .BYTE   " ...[CRC OK]", CR, LF, 0
msg_exeloaded:
        .BYTE   CR, LF
        .BYTE   "Executable loaded at: 0x", 0
msg_cf_cat_title:
        .BYTE   CR, LF
        .BYTE   CR, LF
        .BYTE   "Disk Catalogue", CR, LF, 0
msg_cf_cat_sep:
        .BYTE   "-------------------------------------------------------------------------------", CR, LF, 0
msg_cf_cat_detail:
        .BYTE   "File              Created               Modified              Size   Attributes", CR, LF, 0
msg_cf_file_loaded:
        .BYTE   CR, LF
        .BYTE   "File loaded successfully at address: $", 0
msg_cf_file_renamed:
        .BYTE   CR, LF
        .BYTE   "File renamed", 0
msg_cf_file_deleted:
        .BYTE   CR, LF
        .BYTE   "File deleted", 0
msg_cf_file_attr_chged:
        .BYTE   CR, LF
        .BYTE   "File Attributes changed", 0
msg_cf_format_confirm:
        .BYTE   CR, LF
        .BYTE   "All data in the disk will be destroyed!", CR, LF
        .BYTE   "Do you want to continue? (yes/no) ", 0
msg_cf_diskinfo_hdr:
        .BYTE   CR, LF
        .BYTE   "CompactFlash Information", CR, LF, 0
msg_memdump_hdr:
        .BYTE   CR, LF
        .BYTE   "      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", CR, LF
        .BYTE   "      .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..", 0
msg_moreorquit:
        .BYTE   CR, LF
        .BYTE   "[SPACE] for more or another key for stop", 0
msg_format_end:
        .BYTE   CR, LF
        .BYTE   "Disk was successfully formatted", CR, LF, 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
        .BYTE   CR, LF
        .BYTE   "Command unknown (type help for list of available commands)", CR, LF, 0
error_1002:
        .BYTE   CR, LF
        .BYTE   "Bad parameter(s)", CR, LF, 0
error_1003:
        .BYTE   CR, LF
        .BYTE   "File not found", CR, LF, 0
error_1004:
        .BYTE   CR, LF
        .BYTE   "New filename already exists", CR, LF, 0
error_1005:
        .BYTE   CR, LF
        .BYTE   "Unknown attribute letter was specified", CR, LF, 0
;==============================================================================
; AVAILABLE CLI COMMANDS
;==============================================================================
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

;==============================================================================
; END of CODE
;==============================================================================
        .ORG    CLI_END
        .BYTE   0
        .END