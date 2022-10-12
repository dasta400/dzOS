;******************************************************************************
; CLI.cmds.asm
;
; Command-Line Interface - Available commands
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 06 Jul 2022
; Last Modification 06 Jul 2022
;******************************************************************************
; CHANGELOG
;   -
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
; LinEdit (Line Editor) entry point and main loop
;==============================================================================
LE_FILENAME             .EQU    $4420   ; filename that will be used to read/save
LE_TEXT_BUFFER          .EQU    $5000   ; start of the text buffer
LE_MAX_CHARS            .EQU    FREERAM_END - LE_TEXT_BUFFER
LE_CHAR_COUNTER         .EQU    tmp_addr3   ; counts the characters entered

le_msg_version:
        .BYTE   CR, LF
        .BYTE       "LinEdit v1.0 (c) David Asta 2022"
        .BYTE   CR, LF, 0
le_msg_prompt:
        .BYTE   CR, LF
        .BYTE   "* "
        .BYTE   0
le_msg_quit_confirm:
        .BYTE   CR, LF
        .BYTE   "Are you sure you want to quit? (y/n) ", 0
le_msg_bytes_free:
        .BYTE   " Bytes free", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
le_error_2001:
        .BYTE   "Command unknown", CR, LF, 0
le_error_2002:
        .BYTE   CR, LF
        .BYTE   "Filename was not provided", CR, LF, 0


;==============================================================================
; DELETE ME after tests
;==============================================================================
le_debug:
        .BYTE   "This is line one"
        .FILL   64, 0
        .BYTE   "This is another line"
        .FILL   76, 0
        .BYTE   $FF
        .BYTE   "This is line two, with a blank before it", 0, 0
        .FILL   32, 0

CLI_CMD_LINEDIT:
        ; Show linedit version
        ld      HL, le_msg_version
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ; Show free memory
        ld      HL, LE_MAX_CHARS
        call    F_KRN_BIN_TO_BCD6       ; CDE = 6-digit decimal number
        ex      DE, HL
        ld      DE, tmp_addr1
        call    F_KRN_BCD_TO_ASCII
        ld      IX, tmp_addr1
        call    F_KRN_SERIAL_WR6DIG_NOLZEROS
        ld      HL, le_msg_bytes_free
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR

        ; Check that the filename was provided as a parameter
        call    LE_CHK_PARAM            ; in case of error, will return to CLI

le_prompt_loop:
        ld      HL, le_msg_prompt          ; Prompt
        ld      A, ANSI_COLR_BLU
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, ANSI_COLR_WHT        ; Set text colour
        call    F_KRN_SERIAL_SETFGCOLR  ;   for user input
        call    LE_READ_CMD             ; Read command from user
        jp      le_prompt_loop
;------------------------------------------------------------------------------
LE_READ_CMD:
        ; Commands are one character. Some followed by a number
        call    F_BIOS_SERIAL_CONIN_A   ; Receive a character
        call    F_BIOS_SERIAL_CONOUT_A  ; and echo it
        ; Check character command
        cp      'p'                     ; position pointer to n line
        jp      z, LE_PTR_TO_LINE
        cp      'l'                     ; list all or n lines
        jp      z, LE_LIST_LINES
        cp      'i'                     ; insert line pointed at position
        jp      z, LE_INSERT_LINE
        cp      'r'                     ; replace line pointed at position
        jp      z, LE_REPLACE_LINE
        cp      'd'                     ; delete line pointed at position
        jp      z, LE_DELETE_LINE
        cp      's'                     ; save to file
        jp      z, LE_SAVE_TO_FILE
        cp      'q'                     ; quit linedit
        jp      z, LE_QUIT
        ; If none of the above, command is unknown
        ld      HL, le_error_2001
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        ret
;------------------------------------------------------------------------------
LE_PTR_TO_LINE:
        ; get another character(s) that will tell us the line number
        jp      le_prompt_loop
;------------------------------------------------------------------------------
LE_LIST_LINES:
        ; get another character(s) that will tell us the number of lines
        ; if empty, then display all lines from pointer
        jp      le_prompt_loop
;------------------------------------------------------------------------------
LE_INSERT_LINE:

; DEBUG START
        ; Write something to the text buffer
        ld      DE, LE_TEXT_BUFFER
        ld      HL, le_debug
        ld      BC, 241
        ld      (LE_CHAR_COUNTER), BC
        ldir
; DEBUG END
        jp      le_prompt_loop
;------------------------------------------------------------------------------
LE_REPLACE_LINE:
        jp      le_prompt_loop
;------------------------------------------------------------------------------
LE_DELETE_LINE:
        ; get another character(s) that will tell us the line number
        jp      le_prompt_loop
;------------------------------------------------------------------------------
LE_CHK_PARAM:
; Check that the filename was entered in CLI as a parameter to run command
; CLI command is stored in CLI_buffer_full_cmd (0x411F) as: run linedit filename
        ld      B, 0                    ; space character counter
        ld      HL, CLI_buffer_full_cmd - 1 ; CLI_buffer_full_cmd start byte - 1
_chkparam:
        inc     HL
        ld      A, (HL)                 ; get character
        cp      CR                      ; is it Carriage Return?
        jp      z, _endofcmd
        cp      SPACE                   ; is it a space character?
        jp      nz, _chkparam           ; no, check more characters
        inc     B                       ; yes, increment counter
        jr      _chkparam               ; check more characters
_endofcmd:
        ld      A, B                    ; did we count
        cp      1                       ;   two spaces?
; ToDo - Change 1 to 2 after tests
        ret     z                       ; yes, exit subroutine
        ; no, filename was not provided. Show error and return to CLI
         ld      HL, error_2002
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop

;------------------------------------------------------------------------------
LE_SAVE_TO_FILE:
        ; filename was provided in the CLI command that called linedit
        ; and it's stored in 
        ; run linedit filename

        ; Extract filename from CLI command buffer
        ;   Skip characters until second space character
        ld      B, 2                    ; space characters counter
        ld      HL, $411E               ; CLI_buffer_full_cmd start byte - 1
_getfname:
        inc     HL                      ; position pointer to character
        ld      A, (HL)                 ; get character
        cp      SPACE                   ; Is it a space character?
        jp      nz, _getfname           ; no, then read more characters
        djnz    _getfname               ; yes, decrement space counter and check more characters
        inc     HL                      ; skip last space character found

        ; copy filename from CLI_buffer_full_cmd to temporary variable LE_FILENAME
        ld      B, 51                   ; filename can be max. 52 characters
                                        ; beacuse run linedit SPACE occupies 12
                                        ; and the max. in CLI_buffer_full_cmd is 64
        ld      DE, LE_FILENAME
_cpyfname:
        ld      A, (HL)                 ; We will copy
        cp      CR                      ;   characters from
        jp      z, fnamecopied          ;   CLI_buffer_full_cmd
        ld      (DE), A                 ;   to LE_FILENAME
        dec     B                       ;   until
        jp      z, fnamecopied          ;   we copied 52
        inc     HL                      ;   characters
        inc     DE                      ;   or found
        jp      _cpyfname               ;   a Carriage Return

fnamecopied:
        ld      A, 0                    ; Add a zero at the end to use it as
        ld      (DE), A                 ;   end of string indicator

        ; Save the contents of memory to disk
        ld      HL, LE_TEXT_BUFFER      ; address of first byte to be stored
        ld      BC, (LE_CHAR_COUNTER)   ; number of bytes to be stored
        ld      IX, LE_FILENAME         ; address where the filename is stored
        call    F_KRN_DZFS_CREATE_NEW_FILE

        jp      le_prompt_loop             ;go back to prompt
;------------------------------------------------------------------------------
LE_QUIT:
        ; ask for confirmation
        ld      HL, le_msg_quit_confirm
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, ANSI_COLR_WHT        ; Set text colour
        call    F_KRN_SERIAL_SETFGCOLR  ;   for user input
        call    F_BIOS_SERIAL_CONIN_A   ; Receive a character
        call    F_BIOS_SERIAL_CONOUT_A  ; and echo it
        cp      'y'
        jp      z, cli_promptloop       ; yes, then return to CLI
        jp      le_prompt_loop             ; no, then go back to prompt



;------------------------------------------------------------------------------
;   reset - Resets the computer, with a Warm Boot
;------------------------------------------------------------------------------
; CLI_CMD_RESET:
        ; jp      F_BIOS_WBOOT
;------------------------------------------------------------------------------
;   halt - Halts the computer
;------------------------------------------------------------------------------
CLI_CMD_HALT:
        jp      F_BIOS_SYSHALT
;------------------------------------------------------------------------------
;    help - Show list of available commands
;------------------------------------------------------------------------------
; CLI_CMD_HELP:
;         ld      HL, msg_help
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;    peek - Prints the value of a single memory address
;------------------------------------------------------------------------------
CLI_CMD_PEEK:
; IN <= CLI_buffer_parm1_val = address
; OUT => default output (e.g. screen, I/O)
        call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
        call    param1val_uppercase
;        ld        hl, empty_line            ; print an empty line
;        call    F_KRN_SERIAL_WRSTR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
    ; CLI_buffer_parm1_val has the value in hexadecimal
    ; we need to convert it to binary
        call    _CLI_HEX2BIN_PARAM1     ; DE contains the binary value for param1
        ex      DE, HL                  ; move from DE to HL (param1)
        ld      A, (HL)                 ; load value at address of param1
        call    F_KRN_SERIAL_PRN_BYTE   ; Prints byte in hexadecimal notation
        jp      cli_promptloop
;------------------------------------------------------------------------------
;    poke - calls poke subroutine that changes a single memory address 
;          to a specified value
;------------------------------------------------------------------------------
CLI_CMD_POKE:
; IN <= CLI_buffer_parm1_val = memory address
;       CLI_buffer_parm2_val = specified value
; OUT => print message 'OK' to default output (e.g. screen, I/O)
        call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
        call    param1val_uppercase
        call    param2val_uppercase
        call    F_KRN_ASCII_TO_HEX      ; Hex ASCII to Binary conversion
        ; CLI_buffer_parm1_val has the address in hexadecimal ASCII
        ; we need to convert its hexadecimal value (e.g. 33 => 03)
        ld      IX, CLI_buffer_parm1_val
        call    F_KRN_ASCIIADR_TO_HEX
        push    HL                      ; Backup HL
        ; CLI_buffer_parm2_val has the value in hexadecimal ASCII
        ; we need to convert its hexadecimal value (e.g. 33 => 03)
        ld      A, (CLI_buffer_parm2_val)
        ld      H, A
        ld      A, (CLI_buffer_parm2_val + 1)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX      ; A contains the binary value for param2
        pop     HL                      ; Restore HL
        ld      (HL), A                 ; Store value in address
        ; print OK, to let the user know that the command was successful
        ld      HL, msg_ok
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop
;------------------------------------------------------------------------------
;    autopoke - Allows to enter hexadecimal values that will be stored at the
;              address in parm1 and consecutive positions.
;              The address is incremented automatically after each hexadecimal 
;              value is entered. 
;              Entering no value (i.e. just press ENTER) will stop the process.
;------------------------------------------------------------------------------
CLI_CMD_AUTOPOKE:
; IN <=     CLI_buffer_parm1_val = Start address
        call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
        ; Convert address from ASCII to its hex value
        ld      IX, CLI_buffer_parm1_val
        call    F_KRN_ASCIIADR_TO_HEX
        ; Use IX as pointer to memory address where the values entered by
        ; the user will be stored. It's incremented after each value is entered
        ld      (tmp_addr1), HL
        ld      IX, (tmp_addr1)
autopoke_loop:
        ; show a dollar symbol to indicate the user that can enter an hexadecimal
        ld      HL, msg_prompt_hex      ; Prompt
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ; read 1st character
        call    F_KRN_SERIAL_RDCHARECHO ; read a character, with echo
        cp      CR                      ; test for 1st parameter entered
        jp      z, end_autopoke         ; if it's CR, exit subroutine
        call    F_KRN_TOUPPER
        ld      H, A                    ; H = value's 1st digit
        ; read 2nd character
        call    F_KRN_SERIAL_RDCHARECHO ; read a character, with echo
        cp      CR                      ; test for 1st parameter entered
        jp      z, end_autopoke         ; if it's CR, exit subroutine
        call    F_KRN_TOUPPER
        ld      L, A                    ; L = value's 2nd digit
        ; convert HL from ASCII to hex
        call    F_KRN_ASCII_TO_HEX      ; A = HL in hex
        ; Do the poke (i.e. store specified value at memory address)
        ld      (IX), A
        ; Increment memory address pointer and loop back to get next value
        inc     IX
        jp      autopoke_loop
end_autopoke:
        jp      cli_promptloop
;------------------------------------------------------------------------------
;    memdump - Shows memory contents of an specified section of memory
;------------------------------------------------------------------------------
CLI_CMD_MEMDUMP:
; IN <= CLI_buffer_parm1_val = Start address
;       CLI_buffer_parm2_val = End address
; OUT => default output (e.g. screen, I/O)
        call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
        ; print header
        ld      HL, msg_memdump_hdr
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ; CLI_buffer_parm2_val has the value in hexadecimal
        ; we need to convert it to binary
        call    _CLI_HEX2BIN_PARAM2     ; DE contains the binary value for param2
        push    DE                      ; store in the stack
        ; CLI_buffer_parm1_val has the value in hexadecimal
        ; we need to convert it to binary
        call    _CLI_HEX2BIN_PARAM1     ; DE contains the binary value for param1
        ex      DE, HL                  ; move from DE to HL (HL=param1)
        pop     DE                      ; restore from stack (DE=param2)
start_dump_line:
        ld      c, 20                    ; we will print 23 lines per page
dump_line:
        push    HL
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_KRN_SERIAL_PRN_WORD
        ld      A, ':'                  ; semicolon separates mem address from data
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ' '                  ; and an extra space to separate
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, $10                  ; we will output 16 bytes in each line
dump_loop:
        ld      A, (HL)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        inc     HL
        djnz    dump_loop
        ; dump ASCII characters
        pop     HL
        ld      B, $10                  ; we will output 16 bytes in each line
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_BIOS_SERIAL_CONOUT_A
ascii_loop:
        ld      A, (HL)
        call    F_KRN_IS_PRINTABLE      ; is it an ASCII printable character?
        jr      c, printable
        ld      A, '.'                  ; if is not, print a dot
printable:
        call    F_BIOS_SERIAL_CONOUT_A
        inc     HL
        djnz    ascii_loop

        push    HL                      ; backup HL before doing sbc instruction
        and     A                       ; clear carry flag
        sbc     HL, DE                  ; have we reached the end address?
        pop     HL                      ; restore HL
        jr      c, dump_next            ; end address not reached. Dump next line
        jp      cli_promptloop
dump_next:
        dec     c                       ; 1 line was printed
        jp      z, askmoreorquit        ; we have printed 23 lines. More?
        jp      dump_line               ; print another line
askmoreorquit:
        push    DE                      ; backup DE
        push    HL                      ; backup HL
        ld      HL, msg_moreorquit
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_BIOS_SERIAL_CONIN_A   ; read key
        cp      SPACE                   ; was the SPACE key?
        jp      z, wantsmore            ; user wants more
        pop     HL                      ; yes, user wants more. Restore HL
        pop     DE                      ; restore DE
        jp      cli_promptloop          ; no, user wants to quit
wantsmore:
        ; print header
        ld      HL, msg_memdump_hdr
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        pop     HL                      ; restore HL
        pop     DE                      ; restore DE
        jp      start_dump_line         ; return to start, so we print 23 more lines
;------------------------------------------------------------------------------
;    run - Starts running instructions from a specific memory address
;------------------------------------------------------------------------------
; CLI_CMD_RUN:
; ; IN <=     CLI_buffer_parm1_val = address or filename
;         call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
;         ; Check if param1 is an address (i.e. starts with a number) or a filename
;         ld      A, (CLI_buffer_parm1_val) ; check if the 1st character of param1
;         call    F_KRN_IS_NUMERIC        ;   is a number
;         jr      c, runner_addr          ; is number? Yes, run from memory address
; runner_filename:                        ; No, load and run file
;         ; filename is the first parameter, so can call load command directly
;         ld      A, $AB                  ; This is a flag to tell CLI_CMD_CF_LOAD that the call
;         ld      (tmp_byte), A           ;   didn't come from the jumptable, so that it can return here
;         call    CLI_CMD_CF_LOAD_NOCHECK
;         ld      A, (tmp_byte)           ; Was the file loaded correctly?
;         cp      $EF                     ; EF means there was an error
;         jp      z, cli_promptloop       ; exit subroutine if param1 was not specified
;         ; file was loaded, run it
;         ld      A, ANSI_COLR_WHT        ; Set text colour
;         call    F_KRN_SERIAL_SETFGCOLR  ;   for user input
;         ld      HL, (CF_cur_file_load_addr)
;         jp      (HL)                    ; jump execution to address in HL
; runner_addr:
;         call    param1val_uppercase
;         ; CLI_buffer_parm1_val has the value in hexadecimal
;         ; we need to convert it to binary
;         call    _CLI_HEX2BIN_PARAM1     ; DE contains the binary value for param1
;         ex      DE, HL                  ; move from DE to HL (param1)
;         jp      (HL)                    ; jump execution to address in HL
;         jp      cli_promptloop          ; exit subroutine if param1 was not specified
;------------------------------------------------------------------------------
;     cat - Shows disk catalogue
;------------------------------------------------------------------------------
; CLI_CMD_CF_CAT:
;         ; Only allow disk commands if the disk is formatted
;         ld      A, (CF_is_formatted)
;         cp      $FF
;         jp      nz, _error_diskunformatted
;         ; print header
;         ld      HL, msg_cf_cat_title
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         ld      HL, msg_cf_cat_sep
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         ld      HL, msg_cf_cat_detail
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         ld      HL, msg_cf_cat_sep
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         ; print catalogue
;         call    F_CLI_CF_PRINT_DISKCAT
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;     load - Load filename from disk to RAM
;------------------------------------------------------------------------------
<<<<<<< Updated upstream
CLI_CMD_CF_LOAD:
; IN <= CLI_buffer_parm1_val = Filename
; OUT => OK message on default output (e.g. screen, I/O) if file found
        ; Only allow disk commands if the disk is formatted
        ld      A, (CF_is_formatted)
        cp      $FF
        jp      nz, _error_diskunformatted
        call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
CLI_CMD_CF_LOAD_NOCHECK:                ; When called from CLI_CMD_RUN, the paramter was already checked
        ; Search filename in BAT
        ; Check that filename exists
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      z, filename_notfound    ; filename not found, error and exit
        ; yes, continue
        ld      DE, (CF_cur_file_1st_sector)
        ld      IX, (CF_cur_file_size_sectors)
        call    F_KRN_DZFS_LOAD_FILE_TO_RAM
        ; show success message
        ld      HL, msg_cf_file_loaded
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ; Show SYSVARS.CF_cur_file_load_addr
        ld      HL, (CF_cur_file_load_addr)
        call    F_KRN_SERIAL_PRN_WORD
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Did we get here via jumptable or call from CLI_CMD_RUN?
        ld      A, (tmp_byte)
        cp      $AB                     ; called from CLI_CMD_RUN?
        ret     z                       ; yes, then do a return
        jp      cli_promptloop          ; no, then transfer control back to CLI prompt
=======
; CLI_CMD_CF_LOAD:
; ; IN <= CLI_buffer_parm1_val = Filename
; ; OUT => OK message on default output (e.g. screen, I/O) if file found
;         ; Only allow disk commands if the disk is formatted
;         ld      A, (CF_is_formatted)
;         cp      $FF
;         jp      nz, _error_diskunformatted
;         call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
; CLI_CMD_CF_LOAD_NOCHECK:                ; When called from CLI_CMD_RUN, the paramter was already checked
;         ; Search filename in BAT
;         ; Check that filename exists
;         ld      HL, CLI_buffer_parm1_val
;         call    F_KRN_DZFS_CHECK_FILE_EXISTS
;         jp      z, filename_notfound    ; filename not found, error and exit
;         ; yes, continue
;         ld      DE, (CF_cur_file_1st_sector)
;         ld      IX, (CF_cur_file_size_sectors)
;         call    F_KRN_DZFS_LOAD_FILE_TO_RAM
;         ; show success message
;         ld      HL, msg_cf_file_loaded
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         ; Show SYSVARS.CF_cur_file_load_addr
;         ld      HL, (CF_cur_file_load_addr)
;         call    F_KRN_SERIAL_PRN_WORD
;         ld      B, 1
;         call    F_KRN_SERIAL_EMPTYLINES
;         ; Did we get here via jumptable or call from CLI_CMD_RUN?
;         ld      A, (tmp_byte)
;         cp      $AB                     ; called from CLI_CMD_RUN?
;         ret     z                       ; yes, then do a return
;         jp      cli_promptloop          ; no, then transfer control back to CLI prompt
>>>>>>> Stashed changes
;------------------------------------------------------------------------------
;     formatdsk - Format CompactFlash disk
;------------------------------------------------------------------------------
; CLI_CMD_CF_FORMATDSK:
; ; IN <= CLI_buffer_parm1_val = disk label
; ;       CLI_buffer_parm2_val = number of partitions
; ;
;         call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
;         ; Check that param2 is not equal to 0
;         ld      A, (CLI_buffer_parm2_val)
;         cp      $30
;         jp      z, cli_promptloop
;         ; was not zero, continue
;         call    param2val_uppercase
;         ; Ask for confirmation before formatting
;         ; User MUST reply with the word 'yes' to proceed.
;         ; Any other word/character will cancel the formatting
;         ld      HL, msg_cf_format_confirm
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         ld      IX, CLI_buffer_pgm      ; answer will be stored in CLI_buffer_pgm
; format_answer_loop:
;         call    F_KRN_SERIAL_RDCHARECHO ; read a character, with echo
;         cp      CR                      ; ENTER?
;         jp      z, format_answer_end    ; yes, command was fully entered
;         ld      (IX), A                 ; store character
;         inc     IX                      ;   in buffer
;         jp      format_answer_loop      ; no, read more characters
; format_answer_end:
;         ; Check that the answer is yes
;         ld      IX, CLI_buffer_pgm
;         ld      A, (IX)
;         cp      'y'
;         jp      nz, cli_promptloop
;         ld      A, (IX + 1)
;         cp      'e'
;         jp      nz, cli_promptloop
;         ld      A, (IX + 2)
;         cp      's'
;         jp      nz, cli_promptloop
;         ; Answer was yes, then proceed to format the disk
;         ld      HL, CLI_buffer_parm1_val
;         ld      DE, CLI_buffer_parm2_val
;         call    F_KRN_DZFS_FORMAT_CF
;         ld      HL, msg_format_end
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;     diskinfo - Show CompactFlash information
;------------------------------------------------------------------------------
; CLI_CMD_CF_DISKINFO:
;         ; Only allow disk commands if the disk is formatted
;         ld      A, (CF_is_formatted)
;         cp      $FF
;         jp      nz, _error_diskunformatted
;         call    F_KRN_DZFS_READ_SUPERBLOCK  ; get CF information from the Superblock
;         ld      HL, msg_cf_diskinfo_hdr
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         call    F_KRN_DZFS_SHOW_DISKINFO
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;   rename - Renames a file with a specified filename to a new filename
;------------------------------------------------------------------------------
<<<<<<< Updated upstream
CLI_CMD_CF_RENAME:
; IN <= CLI_buffer_parm1_val = old filename
;       CLI_buffer_parm2_val = new filename
;
        ; Only allow disk commands if the disk is formatted
        ld      A, (CF_is_formatted)
        cp      $FF
        jp      nz, _error_diskunformatted
        call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
        ; Check that new filename doesn't already exists
        ld      HL, CLI_buffer_parm2_val
        call    F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      z, check_old_filename   ; File not found, check that old filename exists
        ; New filename already exists, show error an exit
        ld      HL, error_2004
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop
check_old_filename:
        ; Check that old filename exists
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      z, filename_notfound    ; Old filename not found, error and exit
        call    is_rosys                ; Old filename found, check that is not Read Only or System
        jp      nz, action_notallowed   ; Yes, error and exit
=======
; CLI_CMD_CF_RENAME:
; ; IN <= CLI_buffer_parm1_val = old filename
; ;       CLI_buffer_parm2_val = new filename
; ;
;         ; Only allow disk commands if the disk is formatted
;         ld      A, (CF_is_formatted)
;         cp      $FF
;         jp      nz, _error_diskunformatted
;         call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
;         ; Check that new filename doesn't already exists
;         ld      HL, CLI_buffer_parm2_val
;         call    F_KRN_DZFS_CHECK_FILE_EXISTS
;         jp      z, check_old_filename   ; File not found, check that old filename exists
;         ; New filename already exists, show error an exit
;         ld      HL, error_2004
;         ld      A, ANSI_COLR_RED
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
; check_old_filename:
;         ; Check that old filename exists
;         ld      HL, CLI_buffer_parm1_val
;         call    F_KRN_DZFS_CHECK_FILE_EXISTS
;         jp      z, filename_notfound    ; Old filename not found, error and exit
;         call    is_rosys                ; Old filename found, check that is not Read Only or System
;         jp      nz, action_notallowed   ; Yes, error and exit
>>>>>>> Stashed changes

;         ; Old filename exists, new filename doesn't. All good to do the renaming
;         ld      DE, (CF_cur_file_entry_number)
;         ld      IY, CLI_buffer_parm2_val
;         call    F_KRN_DZFS_RENAME_FILE
;         ; Show success message
;         ld      HL, msg_cf_file_renamed
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
; filename_notfound:
;         ; File not found, show error an exit
;         ld      HL, error_2003
;         ld      A, ANSI_COLR_RED
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
; action_notallowed:
;         ; File is Read Only and/or System, show error and exit
;         ld      HL, error_2007
;         ld      A, ANSI_COLR_RED
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;   delete - Deletes a file with a specified filename
;            The Kernel doesn't delete the file data. It just changes the
;               first character of the filename to ~
;------------------------------------------------------------------------------
<<<<<<< Updated upstream
CLI_CMD_CF_DELETE:
; IN <= CLI_buffer_parm1_val = filename
;
        ; Only allow disk commands if the disk is formatted
        ld      A, (CF_is_formatted)
        cp      $FF
        jp      nz, _error_diskunformatted
        call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
        ; Check that filename exists
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      z, filename_notfound    ; filename not found, error and exit
        call    is_rosys
        jp      nz, action_notallowed   ; Yes, error and exit
                                        ; No, continue
        ld      DE, (CF_cur_file_entry_number)
        call    F_KRN_DZFS_DELETE_FILE
        ; show success message
        ld      HL, msg_cf_file_deleted
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop
=======
; CLI_CMD_CF_DELETE:
; ; IN <= CLI_buffer_parm1_val = filename
; ;
;         ; Only allow disk commands if the disk is formatted
;         ld      A, (CF_is_formatted)
;         cp      $FF
;         jp      nz, _error_diskunformatted
;         call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
;         ; Check that filename exists
;         ld      HL, CLI_buffer_parm1_val
;         call    F_KRN_DZFS_CHECK_FILE_EXISTS
;         jp      z, filename_notfound    ; filename not found, error and exit
;         call    is_rosys
;         jp      nz, action_notallowed   ; Yes, error and exit
;                                         ; No, continue
;         ld      DE, (CF_cur_file_entry_number)
;         call    F_KRN_DZFS_DELETE_FILE
;         ; show success message
;         ld      HL, msg_cf_file_deleted
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
>>>>>>> Stashed changes
;------------------------------------------------------------------------------
;   chgattr - Changes the attributes (RSHE) of a specified filename
;             The attributes entered by the user will become the new attributes
;               of the file. There is no option to remove a single attribute.
;------------------------------------------------------------------------------
<<<<<<< Updated upstream
CLI_CMD_CF_CHGATTR:
; IN <= CLI_buffer_parm1_val = filename
;       CLI_buffer_parm2_val = new attributes
;
        ; Only allow disk commands if the disk is formatted
        ld      A, (CF_is_formatted)
        cp      $FF
        jp      nz, _error_diskunformatted
        call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
        ; Check that filename exists
        ld      HL, CLI_buffer_parm1_val
        call    F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      z, filename_notfound    ; filename not found, error and exit
chgattr:
        ; Do not allow change attributes on System files
        ld      A, (CF_cur_file_attribs)
        bit     2, A                    ; is it System?
        jp      nz, action_notallowed   ; Yes, error and exit
                                        ; No, continue        
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
        ld      HL, error_2005
        ld      A, ANSI_COLR_RED
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop
mask_done:
        ld      DE, (CF_cur_file_entry_number)
        ld      A, (tmp_byte)
        call    F_KRN_DZFS_CHGATTR_FILE
        ; show success message
        ld      HL, msg_cf_file_attr_chged
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        jp      cli_promptloop
=======
; CLI_CMD_CF_CHGATTR:
; ; IN <= CLI_buffer_parm1_val = filename
; ;       CLI_buffer_parm2_val = new attributes
; ;
;         ; Only allow disk commands if the disk is formatted
;         ld      A, (CF_is_formatted)
;         cp      $FF
;         jp      nz, _error_diskunformatted
;         call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
;         ; Check that filename exists
;         ld      HL, CLI_buffer_parm1_val
;         call    F_KRN_DZFS_CHECK_FILE_EXISTS
;         jp      z, filename_notfound    ; filename not found, error and exit
; chgattr:
;         ; Do not allow change attributes on System files
;         ld      A, (CF_cur_file_attribs)
;         bit     2, A                    ; is it System?
;         jp      nz, action_notallowed   ; Yes, error and exit
;                                         ; No, continue        
;         ; Read each character of param2 and make up the mask byte as per
;         ;   (0=Inactive / 1=Active)
;         ;       Bit 0 = Read Only
;         ;       Bit 1 = Hidden
;         ;       Bit 2 = System
;         ;       Bit 3 = Executable
;         ;       Bit 4-7 = Not used
;         ld      B, 1                    ; character counter
;         ld      IX, CLI_buffer_parm2_val; pointer to characters in param2
;         ld      HL, tmp_byte            ; pointer to final attribute mask byte
;         ld      A, 0                    ; clear the
;         ld      (tmp_byte), A           ;    mask byte
; read_attr:
;         ld      A, (IX)                 ; load attribute
;         cp      'R'                     ; is it Read Only?
;         jp      z, make_readonly        ; yes, make mask byte
;         cp      'H'                     ; is it Hidden?
;         jp      z, make_hidden          ; yes, make mask byte
;         cp      'S'                     ; is it System?
;         jp      z, make_system          ; yes, make mask byte
;         cp      'E'                     ; is it Executable?
;         jp      z, make_exec            ; yes, make mask byte
;         cp      $00                     ; is it end of param2?
;         jp      z, mask_done            ; yes, call Kernel routine
;         jp      wrong_attr              ;  Error. It wasn't R, H, S or E.
; next_attr:
;         inc     IX                      ; next character in param2
;         inc     B                       ; increment character counter
;         ld      A, B                    ; did we process
;         cp      5                       ;    5 characters already?
;         jp      z, mask_done            ; yes, then we're finished
;         jp      read_attr               ; no, process more characters
; make_readonly:
;         ld      A, (HL)
;         or      1
;         jp      make_done
; make_hidden:
;         ld      A, (HL)
;         or      2
;         jp      make_done
; make_system:
;         ld      A, (HL)
;         or      4
;         jp      make_done
; make_exec
;         ld      A, (HL)
;         or      8
;         jp      make_done
; make_done:
;         ld      (HL), A                 ; change mask byte
;         jp      next_attr
; wrong_attr:
;         ld      HL, error_2005
;         ld      A, ANSI_COLR_RED
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
; mask_done:
;         ld      DE, (CF_cur_file_entry_number)
;         ld      A, (tmp_byte)
;         call    F_KRN_DZFS_CHGATTR_FILE
;         ; show success message
;         ld      HL, msg_cf_file_attr_chged
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
>>>>>>> Stashed changes
; ;------------------------------------------------------------------------------
; is_filename_found:
; ; IN <= tmp_addr3 filled by F_KRN_DZFS_GET_FILE_BATENTRY
; ; OUT => z is set if file not found
; ;
;         ; When getting a BAT entry, the Kernel stores two bytes ($ABBA)
;         ;   as default value in SYSVARS.tmp_addr3.
;         ; These two bytes get replaced ($0000) if a file is found.
;         ; Therefore, we can use it to detect if a file was found or not.
;         ; Was the filename found?
;         ld      A, (tmp_addr3)
;         cp      $AB
;         ret     z
;         ld      A, (tmp_addr3 + 1)
;         cp      $BA
;         ret
;------------------------------------------------------------------------------
; is_rosys:
; ; return error if file is Read Only and/or System
; ; IN <= reads from SYSVARS.CF_cur_file_attribs
; ; OUT => Zero Flag cleared if Read Only or System
;         ld      A, (CF_cur_file_attribs)
;         bit     0, A                    ; is it Read Only?
;         ret     nz                       ; exit
;         bit     2, A                    ; no, is it System?
;         ret

;------------------------------------------------------------------------------
;   save - Save n bytes from an specified address in memory to a file
;          User will be prompted for a filename
;------------------------------------------------------------------------------
; CLI_CMD_CF_SAVE:
; ; IN <= CLI_buffer_parm1_val = start address in memory
; ;       CLI_buffer_parm2_val = number of bytes to save
; ;
;         ; Only allow disk commands if the disk is formatted
;         ld      A, (CF_is_formatted)
;         cp      $FF
;         jp      nz, _error_diskunformatted
;         call    F_CLI_CHECK_2_PARAMS    ; Check if both parameters were specified
;         ; Ask for filename
;         ld      HL, msg_prompt_fname
;         ld      A, ANSI_COLR_BLU
;         call    F_KRN_SERIAL_WRSTRCLR
;         ld      IX, CLI_buffer_cmd      ; store filename entered by the user in SYSVARS
; get_filename:
;         call    F_KRN_SERIAL_RDCHARECHO
;         cp      CR                      ; ENTER?
;         jp      z, end_get_fname        ; yes, filename was fully entered
;         ld      (IX), A                 ; no, store filename in SYSVARS
;         inc     IX
;         jp      get_filename            ; and continue reading characters
; end_get_fname:
;         ; Check filename exists
;         ld      HL, CLI_buffer_cmd
;         call    F_KRN_DZFS_GET_FILE_BATENTRY
;         ; Was the filename found?
;         ; call    is_filename_found
;         jp      z, save_filename        ; doesn't exist, do the saving
;         ; exists, error and exit
;         ld      HL, error_2004
;         ld      A, ANSI_COLR_RED
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
; save_filename:
;         ; Convert param1 to binary
;         call    _CLI_HEX2BIN_PARAM1     ; DE contains the binary value for param1
;         push    DE                      ;backup param1 in binary
;         ; Convert param2 to binary
;         ;   Get the length of param2 and store it in B
;         ld      HL, CLI_buffer_parm2_val
;         ld      A, $00                      ; param2 is terminated with $00
;         call    F_KRN_STRLEN
;         ;   Shift bytes by one to the right
;         ;      and put the length in first byte
;         dec     HL                          ; pointer to last byte to shift
;         call    F_KRN_SHIFT_BYTES_BY1
;         ;   Convert it to binary
;         ld      HL, CLI_buffer_parm2_val
;         call    F_KRN_DEC_TO_BIN
;         ld      B, H                        ; store byte counter
;         ld      C, L                        ;   in BC

;         pop     HL                          ; restore param1 in binary
;         ld      IX, CLI_buffer_cmd      ; IX points to where the filename is stored

;         call    F_KRN_DZFS_CREATE_NEW_FILE

;         ; print OK message, to let the user know that the command was successful
;         ld      HL, msg_cf_file_saved
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;   date - Show current date
;------------------------------------------------------------------------------
; CLI_CMD_RTC_DATE:
;         ld      HL, msg_todayis
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         call    F_KRN_RTC_SHOW_DATE
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;   time - Show current time
;------------------------------------------------------------------------------
; CLI_CMD_RTC_TIME:
;         ld      HL, msg_nowis
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         call    F_KRN_RTC_SHOW_TIME
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;   setdate - Change current date (ddmmyyyy)
;------------------------------------------------------------------------------
; CLI_CMD_RTC_SETDATE:
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;   settime - Change current time (hhmmss)
;------------------------------------------------------------------------------
; CLI_CMD_RTC_SETTIME:
;         jp      cli_promptloop
;------------------------------------------------------------------------------
;   crc - Calculates the CRC-16 BSC for a number of bytes
;------------------------------------------------------------------------------
; CLI_CMD_CRC16BSC:
; ; IN <= CLI_buffer_parm1_val = start address or filename
; ;       CLI_buffer_parm2_val = end address or blank
; ;
;         call    F_CLI_CHECK_1_PARAM     ; Check if parameter 1 was specified
;         ; Check if param1 is an address (i.e. starts with a number) or a filename
;         ld      A, (CLI_buffer_parm1_val) ; check if the 1st character of param1
;         call    F_KRN_IS_NUMERIC        ;   is a number
;         jr      c, crc16_addr           ; is number? Yes, run from memory address
; crc16_filename:
; ; ToDo - CLI_CMD_CRC16BSC for files
;         jp      cli_promptloop
; crc16_addr:
;         ; If it an address, parameter 2 MUST be provided too
;         call    check_param2            ; Check if parameter 2 was specified
;         jp      z, cli_promptloop       ; no, go back to CLI prompt
;         call    param1val_uppercase
;         call    param2val_uppercase
;         ; CLI_buffer_parm1_val and CLI_buffer_parm2_val has the value in 
;         ;   hexadecimal we need to convert it to binary
;         call    _CLI_HEX2BIN_PARAM1         ; DE contains the binary value for param1
;         ld      (CLI_buffer_parm1_val), DE  ; Store it in SYSVARS
;         call    _CLI_HEX2BIN_PARAM2         ; DE contains the binary value for param1
;         ld      (CLI_buffer_parm2_val), DE  ; Store it in SYSVARS

;         ; How many bytes?
;         ld      HL, (CLI_buffer_parm2_val)  ; end address
;         ld      DE, (CLI_buffer_parm1_val)  ; start address
;         xor     A                           ; clear Carry Flag
;         sbc     HL, DE                      ; HL = end address - start address
;         ld      B, H
;         ld      C, L
;         inc     BC                          ; BC = number of bytes to CRC
;         push    BC                          ; backup byte counter

;         ; Calculate the CRC
;         call    F_KRN_CRC16_INI             ; Initialise the CRC polynomial and clear the CRC
;         ld      IX, (CLI_buffer_parm1_val)  ; IX = pointer to byte to CRC
;         pop     BC                          ; restore byte counter
; crc16_gen_loop:
;         push    BC                          ; backup byte counter
;         ld      A, (IX)                     ; get byte to CRC
;         call    F_KRN_CRC16_GEN             ; generate CRC
;         inc     IX
;         pop     BC                          ; restore byte counter
;         dec     BC                          ; decrement counter
;         ld      A, B                        ; If didn't CRCed
;         or      C                           ;   all bytes
;         jp      nz, crc16_gen_loop          ;   do more CRCs

;         ; Show calculated CRC on screen
;         ld      HL, msg_crcis
;         ld      A, ANSI_COLR_YLW
;         call    F_KRN_SERIAL_WRSTRCLR
;         ld      HL, (MATH_CRC)
;         call    F_KRN_SERIAL_PRN_WORD

;         jp      cli_promptloop
;------------------------------------------------------------------------------
; clrram - fill the entire free ram with zeros
;------------------------------------------------------------------------------
CLI_CMD_CLRRAM:
        ld      HL, FREERAM_START
        ld      BC, FREERAM_END - FREERAM_START
        ld      A, 0
        call    F_KRN_SETMEMRNG
        jp      cli_promptloop

;==============================================================================
; Subroutines
;==============================================================================
;------------------------------------------------------------------------------
_CLI_HEX2BIN_PARAM1:
; Converts CLI_buffer_parm1_val from ASCII hex to binary values
; (e.g. 0x33 and 0x45 are converted into 3E)
; OUT => DE = the binary value for CLI_buffer_parm1_val
        ld      A, (CLI_buffer_parm1_val)
        ld      H, A
        ld      A, (CLI_buffer_parm1_val + 1)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      D, A
        ld      A, (CLI_buffer_parm1_val + 2)
        ld      H, A
        ld      A, (CLI_buffer_parm1_val + 3)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      E, A
        ret
;------------------------------------------------------------------------------
_CLI_HEX2BIN_PARAM2:
; Converts CLI_buffer_parm2_val from ASCII hex to binary values
; (e.g. 0x33 and 0x45 are converted into 3E)
; OUT => DE = the binary value for CLI_buffer_parm1_val
        ld      A, (CLI_buffer_parm2_val)
        ld      H, A
        ld      A, (CLI_buffer_parm2_val + 1)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      D, A
        ld      A, (CLI_buffer_parm2_val + 2)
        ld      H, A
        ld      A, (CLI_buffer_parm2_val + 3)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      E, A
        ret
;==============================================================================
; Disk subroutines
;==============================================================================
;------------------------------------------------------------------------------
<<<<<<< Updated upstream
F_CLI_CF_PRINT_DISKCAT:
; Prints the contents (catalogue) of the CompactFlash Disk
; All entries in the BAT are consecutive. When a new file is stored, it will be 
; stored in the next available (first character = $00=available, or $FF=deleted).
; Hence, once we can read the BAT, and once we find the first entry with $00, we
; know there are no more entries. The maximum number of entries is 1744
        ld      A, 1                    ; BAT starts at sector 1
        ld      (CF_cur_sector), A
        ld      A, 0
        ld      (CF_cur_sector + 1), A
diskcat_nextsector:
        call    F_KRN_DZFS_READ_BAT_SECTOR
        ; As we read in groups of 512 bytes (Sector), 
        ; each read will put 16 entries in the buffer.
        ; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
        ; therefore 64 sectors.
        ld      A, 0                    ; entry counter
diskcat_print:
        push    AF
        call    F_KRN_DZFS_BATENTRY_TO_BUFFER
=======
; F_CLI_CF_PRINT_DISKCAT:
; ; Prints the contents (catalogue) of the CompactFlash Disk
; ; All entries in the BAT are consecutive. When a new file is stored, it will be 
; ; stored in the next available (first character = $00=available, or $FF=deleted).
; ; Hence, once we can read the BAT, and once we find the first entry with $00, we
; ; know there are no more entries. The maximum number of entries is 1744
;         ld      A, 1                    ; BAT starts at sector 1
;         ld      (CF_cur_sector), A
;         ld      A, 0
;         ld      (CF_cur_sector + 1), A
; diskcat_nextsector:
;         call    F_KRN_DZFS_READ_BAT_SECTOR
;         ; As we read in groups of 512 bytes (Sector), 
;         ; each read will put 16 entries in the buffer.
;         ; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
;         ; therefore 64 sectors.
;         ld      A, 0                    ; entry counter
; diskcat_print:
;         push    AF
;         call    F_KRN_DZFS_BATENTRY_TO_BUFFER
>>>>>>> Stashed changes

;         ; Check if the file should be displayed
;         ; i.e. first character is not 7E (deleted)
;         ;      and attribute bit 1 (hidden) is not 1
;         ; If first character is 00, then there aren't more entries.
;         ld      A, (CF_cur_file_name)
;         cp      $7E                     ; File is deleted?
;         jp      z, diskcat_nextentry    ; Yes, skip it
;         cp      $00                     ; Available entry? (i.e. no file)
;         jp      z, diskcat_end          ; Yes, no more entries then
;         ld      A, (CF_cur_file_attribs)
;         and     2                       ; File is hidden?
;         jp      nz, diskcat_nextentry   ; Yes, skip it

;         ; Print entry data
;         ;   Filename
;         ld      B, 14
;         ld      HL, CF_cur_file_name
;         call    F_KRN_SERIAL_PRN_BYTES
;         call    print_a_space
;         call    print_a_space
;         ;   Date created
;         ld      HL, (CF_cur_file_date_created)
;         call    F_KRN_PKEDDATE_TO_DMY   ; A = day, B = month, C = year
;         call    _print_DDMMYYYY
;         call    print_a_space
;         call    print_a_space
;         ;   Time created
;         ld      HL, (CF_cur_file_time_created)
;         call    F_KRN_PKEDTIME_TO_HMS   ; A = hour, B = minutes, C = seconds
;         call    _print_HMS
;         call    print_a_space
;         call    print_a_space
;         ;   Date last modif.
;         ld      HL, (CF_cur_file_date_modified)
;         call    F_KRN_PKEDDATE_TO_DMY   ; A = day, B = month, C = year
;         call    _print_DDMMYYYY
;         call    print_a_space
;         call    print_a_space
;         ;   Time last modif.
;         ld      HL, (CF_cur_file_time_modified)
;         call    F_KRN_PKEDTIME_TO_HMS   ; A = hour, B = minutes, C = seconds
;         call    _print_HMS
;         call    print_a_space
;         call    print_a_space
;         ;   Size
;         ld      IY, CF_cur_file_size_bytes
;         ld      E, (IY)                 ; E = MSB
;         ld      D, (IY + 1)             ; D = LSB
;         ex      DE, HL                  ; H = 1st byte (LSB), L = 2nd byte (LSB)
;         call    F_KRN_BIN_TO_BCD6
;         ex      DE, HL                  ; HL = converted 6-digit BCD
;         ld      DE, CLI_buffer_pgm      ; where the numbers in ASCII will be stored
;         call    F_KRN_BCD_TO_ASCII
;         ;   Print each of the 6 digits (without leading zeros)
;         ld      IX, CLI_buffer_pgm
;         call    F_KRN_SERIAL_WR6DIG_NOLZEROS
;         ld      B, 3                    ; print 3 spaces
;         call    print_n_spaces
;         ;   Attributes (RHSE, R=Read Only, H=Hidden, S=System, E=Executable)
; ; ToDo - make it print always in the same column
;         call    F_CLI_CF_PRINT_ATTRBS
;         ld      B, 8                    ; print 8 spaces
;         call    print_n_spaces
;         ; Load Address
; ; ToDo - make it print always in the same column
;         ld      HL, (CF_cur_file_load_addr)
;         call    F_KRN_SERIAL_PRN_WORD
        
;         ; Add CR + LF
;         ld      B, 1
;         call    F_KRN_SERIAL_EMPTYLINES
; diskcat_nextentry:
;         pop     AF
;         inc     A                       ; next entry
;         cp      16                      ; did we process the 16 entries?
;         jp      nz, diskcat_print       ; No, process next entry
;         ; More entries in other sectors?
;         ld      A, (CF_cur_sector)
;         inc     A                       ; increment sector counter
;         ld      (CF_cur_sector), A      ; Did we process
;         cp      64                      ;    64 sectors already?
; ; TODO - Change this 64, to be read from Superblock's Sectors per Block?
; ;        Then needs to be stored in SYSVARS
;         jp      nz, diskcat_nextsector  ; No, then process next sector
;         jp      diskcat_end_nopop
; diskcat_end:
;         pop     AF                      ; needed because previous push AF    
; diskcat_end_nopop:
;         jp      cli_promptloop          ; Yes, then nothing else to do
;------------------------------------------------------------------------------
; F_CLI_CF_PRINT_ATTRBS:
; ; Prints a string with letters (R=Read Only, H=Hidden, S=System, E=Executable)
; ; if file attribute is ON, or space if it's OFF
;         ld      A, (CF_cur_file_attribs)
;         push    AF
;         and     1                       ; Read Only?
;         jp      nz, cf_attrb_is_ro      ; No, print a space
;         call    print_a_space
;         jp      cf_attrib_hidden
; cf_attrb_is_ro:                         ; Yes, print a dot
;         ld      A, 'R'
;         call    F_BIOS_SERIAL_CONOUT_A
; cf_attrib_hidden:
;         pop     AF
;         push    AF
;         and     2                       ; Hidden?
;         jp      nz, cf_attrb_is_hidden  ; No, print a space
;         call    print_a_space
;         jp      cf_attrib_system
; cf_attrb_is_hidden:                     ; Yes, print a dot
;         ld      A, 'H'
;         call    F_BIOS_SERIAL_CONOUT_A
; cf_attrib_system:
;         pop     AF
;         push    AF
;         and     4                       ; System?
;         jp      nz, cf_attrb_is_system  ; No, print a space
;         call    print_a_space
;         jp      cf_attrib_executable
; cf_attrb_is_system:                     ; Yes, print a dot
;         ld      A, 'S'
;         call    F_BIOS_SERIAL_CONOUT_A
; cf_attrib_executable:
;         pop     AF
;         and     8                       ; Executable?
;         jp      nz, cf_attrb_is_exec    ; No, print a space
;         call    print_a_space
;         ret
; cf_attrb_is_exec:                       ; Yes, print a dot
;         ld      A, 'E'
;         call    F_BIOS_SERIAL_CONOUT_A

; print_a_space:
;         ld      A, ' '
;         call    F_BIOS_SERIAL_CONOUT_A
;         ret
; print_n_spaces:
;         ld      A, ' '
;         call    F_BIOS_SERIAL_CONOUT_A
;         djnz    print_n_spaces
;         ret
;------------------------------------------------------------------------------
; _print_DDMMYYYY:
;         ; Print day and separator
;         push    BC                      ; backup month and year
;         call    F_KRN_BIN_TO_BCD4       ; Convert day to decimal
;         ld      C, 0
;         ld      DE, tmp_addr1
;         call    F_KRN_BCD_TO_ASCII      ; tmp_addr3 = ASCII values for day
;         ld      A, (tmp_addr3)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print first character of day
;         ld      A, (tmp_addr3 + 1)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print second character of day
;         ld      A, '-'
;         call    F_BIOS_SERIAL_CONOUT_A  ; print date separator
;         ; Print month and separator
;         pop     BC                      ; restore month
;         push    BC                      ; backup year
;         ld      A, B
;         call    F_KRN_BIN_TO_BCD4       ; Convert month to decimal
;         ld      C, 0
;         ld      DE, tmp_addr1
;         call    F_KRN_BCD_TO_ASCII      ; tmp_addr3 = ASCII values for month
;         ld      A, (tmp_addr3)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print first character of month
;         ld      A, (tmp_addr3 + 1)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print second character of month
;         ld      A, '-'
;         call    F_BIOS_SERIAL_CONOUT_A  ; print date separator
;         ; Print year (need to add 20 for 20xx)
;         pop     BC                      ; restore year
;         ld      A, '2'
;         call    F_BIOS_SERIAL_CONOUT_A  ; print first digit of century
;         ld      A, '0'
;         call    F_BIOS_SERIAL_CONOUT_A  ; print second digit of century
;         ld      A, C
;         call    F_KRN_BIN_TO_BCD4       ; Convert year to decimal
;         ld      C, 0
;         ld      DE, tmp_addr1
;         call    F_KRN_BCD_TO_ASCII      ; tmp_addr3 = ASCII values for year
;         ld      A, (tmp_addr3)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print first character of year
;         ld      A, (tmp_addr3 + 1)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print second character of year
;         ret
;------------------------------------------------------------------------------
; _print_HMS:
;         ; Print hour and separator
;         push    BC                      ; backup minutes and seconds
;         call    F_KRN_BIN_TO_BCD4       ; Convert hour to decimal
;         ld      C, 0
;         ld      DE, tmp_addr1
;         call    F_KRN_BCD_TO_ASCII      ; tmp_addr3 = ASCII values for hour
;         ld      A, (tmp_addr3)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print first character of hour
;         ld      A, (tmp_addr3 + 1)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print second character of hour
;         ld      A, ':'
;         call    F_BIOS_SERIAL_CONOUT_A  ; print time separator
;         ; Print minutes and separator
;         pop     BC                      ; restore minutes
;         push    BC                      ; backup seconds
;         ld      A, B
;         call    F_KRN_BIN_TO_BCD4       ; Convert minutes to decimal
;         ld      C, 0
;         ld      DE, tmp_addr1
;         call    F_KRN_BCD_TO_ASCII      ; tmp_addr3 = ASCII values for minutes
;         ld      A, (tmp_addr3)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print first character of minutes
;         ld      A, (tmp_addr3 + 1)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print second character of minutes
;         ld      A, ':'
;         call    F_BIOS_SERIAL_CONOUT_A  ; print time separator
;         ; Print seconds
;         pop     BC                      ; restore seconds
;         ld      A, C
;         call    F_KRN_BIN_TO_BCD4       ; Convert seconds to decimal
;         ld      C, 0
;         ld      DE, tmp_addr1
;         call    F_KRN_BCD_TO_ASCII      ; tmp_addr3 = ASCII values for seconds
;         ld      A, (tmp_addr3)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print first character of seconds
;         ld      A, (tmp_addr3 + 1)
;         call    F_BIOS_SERIAL_CONOUT_A  ; print second character of seconds
;         ret
;------------------------------------------------------------------------------
; _error_diskunformatted:
;         ld      HL, error_2006
;         ld      A, ANSI_COLR_RED
;         call    F_KRN_SERIAL_WRSTRCLR
;         jp      cli_promptloop
