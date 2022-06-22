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
; 	-
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
; EQUates
;==============================================================================
LINESPERPAGE			.EQU	20		; 20 lines per page (for memdump)
;==============================================================================
; General Routines
;==============================================================================
		.ORG	CLI_START
cli_welcome:
		ld		hl, msg_cli_version		; CLI start up message
		call	F_KRN_SERIAL_WRSTR				; Output message
		; output 1 empty line
		ld		b, 1
		call 	F_KRN_SERIAL_EMPTYLINES

		; Show Free available RAM
;		ld		hl, FREERAM_END
;		ld		de, FREERAM_START
;		sbc		hl, de					; FREERAM_END - FREERAM_START
;;		inc		hl						; + 1 byte to account of byte 0
;		ld		(FREERAM_START), hl		; store it in RAM

; ToDo - Needs to be converted to decimal first!

cli_promptloop:
        call	F_CLI_CLRCLIBUFFS	    ; Clear buffers
		ld	    hl, msg_prompt          ; Prompt
		call	F_KRN_SERIAL_WRSTR             ; Output message
		ld	    hl, buffer_cmd          ; address where commands are buffered

		ld	    a, 0
		ld	    (buffer_cmd), a
		call	F_CLI_READCMD
		call	F_CLI_PARSECMD
        jp      cli_promptloop
;------------------------------------------------------------------------------
F_CLI_READCMD:
; Read string containing a command and parameters
; Read characters from the Console into a memory buffer until RETURN is pressed.
; Parameters (identified by colon) are detected and stored in *parameters buffer*,
; meanwhile the command is store in *command buffer*.
readcmd_loop:
		call	F_KRN_SERIAL_RDCHARECHO		; read a character, with echo
		cp		' '						; test for 1st parameter entered
		jp		z, was_param
		cp		','						; test for 2nd parameter entered
		jp		z, was_param
		; test for special keys
;		cp		key_backspace			; Backspace?
;		jp		z, was_backspace		; yes, don't add to buffer
;		cp		key_up					; up arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		key_down				; down arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		key_left				; left arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		key_right				; right arrow?
;		jp		z, no_buffer			; yes, don't add to buffer

		cp		CR						; ENTER?
		jp		z, end_get_cmd			; yes, command was fully entered
		ld		(hl), a					; store character in buffer
		inc		hl						; buffer pointer + 1
no_buffer:
		jp		readcmd_loop			; don't add last entered char to buffer
		ret
was_backspace:	
		dec		hl						; go back 1 unit on the buffer pointer
loop_get_cmd:	
		jp		readcmd_loop			; read another character
was_param:
		ld		a, (buffer_parm1_val)
		cp		00h						; is buffer area empty (=00h)?
		jp		z, add_value1			; yes, add character to buffer area
		ld		a, (buffer_parm2_val)
		cp		00h						; is buffer area empty (=00h)?
		jp		z, add_value2			; yes, add character to buffer area
		jp		readcmd_loop			; read next character
add_value1:
		ld		hl, buffer_parm1_val
		jp		readcmd_loop
add_value2:
		ld		hl, buffer_parm2_val
		jp		readcmd_loop
end_get_cmd:
		ret
;------------------------------------------------------------------------------
F_CLI_PARSECMD:
; Parse command
; Parses entered command and calls related subroutine.
		ld		hl, buffer_cmd
		ld		a, (hl)
		cp		00h						; just an ENTER?
		jp		z, cli_promptloop		; show prompt again
		;search command "cat" (disk catalogue)
		ld		de, _CMD_CF_CAT
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_CF_CAT		; yes, then execute the command
		;search command "load" (load file)
		ld		DE,_CMD_CF_LOAD
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_CF_LOAD		; yes, then execute the command
		;search command "load" (load file)
		ld		DE,_CMD_CF_DISKINFO
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_CF_DISKINFO	; yes, then execute the command
		;search command "help"
		ld		de, _CMD_HELP
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_HELP			; yes, then execute the command
		;search command "run"
		ld		de, _CMD_RUN
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_RUN			; yes, then execute the command
		;search command "peek"
		ld		de, _CMD_PEEK
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_PEEK			; yes, then execute the command
		;search command "poke"
		ld		de, _CMD_POKE
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_POKE			; yes, then execute the command
		;search command "autopoke"
		ld		de, _CMD_AUTOPOKE
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_AUTOPOKE		; yes, then execute the command
		;search command "memdump"
		ld		de, _CMD_MEMDUMP
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_MEMDUMP		; yes, then execute the command
		;search command "reset"
		ld		de, _CMD_RESET
		call	search_cmd				; was the command that we were searching?
		jp		z, F_BIOS_WBOOT			; yes, then execute the command
		;search command "halt"
		ld		de, _CMD_HALT
		call	search_cmd				; was the command that we were searching?
		jp		z, F_BIOS_SYSHALT		; yes, then execute the command
no_match:	; unknown command entered
		ld		hl, error_1001
		call	F_KRN_SERIAL_WRSTR
		jp		cli_promptloop
;------------------------------------------------------------------------------
search_cmd:
; compare buffered command with a valid command syntax
;	IN <= DE = command to check against to
;	OUT => Z flag	1 if DE=HL, which means the command matches
;			0 if one letter isn't equal = command doesn't match
		ld		hl, buffer_cmd
		dec		de
loop_search_cmd:
		cp		' '						; is it a space (start parameter)?
		ret		z						; yes, return
		inc		de						; no, continue checking
		ld		a, (de)
		cpi								; compare content of A with HL, and increment HL
		jp		z, test_end_hl			; A = (HL)
		ret nz
test_end_hl:							; check if end (0) was reached on buffered command
		ld		a, (hl)
		cp		0
		jp		z, test_end_de
		jp		loop_search_cmd
test_end_de:							; check if end (0) was reached on command to check against to
		inc		de
		ld		a, (de)
		cp		0
		ret
;------------------------------------------------------------------------------
check_param1:
; Check if buffer parameters were specified
;	OUT => Z flag =	1 command doesn't exist
;					0 command does exist
		ld		a, (buffer_parm1_val)	; get what's in param1
		jp		check_param				; check it
check_param2:
		ld		a, (buffer_parm2_val)	; get what's in param2
check_param:
		cp		0						; was a parameter specified?
		jp		z, bad_params			; no, show error and exit subroutine
		ret
bad_params:
		ld		hl, error_1002			; load bad parameters error text
		call	F_KRN_SERIAL_WRSTR		; print it
		ret
;------------------------------------------------------------------------------
param1val_uppercase:
; converts buffer_parm1_val to uppercase
		ld		hl, buffer_parm1_val - 1
		jp		p1vup_loop
param2val_uppercase:
; converts buffer_parm2_val to uppercase
		ld		hl, buffer_parm2_val - 1
p1vup_loop:
		inc		hl
		ld		a, (hl)
		cp		0
		jp		z, plvup_end
		call	F_KRN_TOUPPER
		ld		(hl), a
		jp		p1vup_loop
plvup_end:
		ret
;==============================================================================
; Memory Routines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_CLRCLIBUFFS:
; Clear CLI buffers
; Clears the buffers used for F_CLI_READCMD, so they are ready for a new command
		ld	    a, 0
		ld	    hl, buffer_cmd
		ld	    de, buffer_cmd + 0fh    ; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		; ld	    hl, buffer_parm1
		; ld	    de, buffer_parm1 + 0fh	; buffers are 15 bytes long
		; call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm1_val
		ld	    de, buffer_parm1_val + 0fh   ; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		; ld	    hl, buffer_parm2
		; ld	    de, buffer_parm2 + 0fh	; buffers are 15 bytes long
		; call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm2_val
		ld	    de, buffer_parm2_val + 0fh	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG
		ret
;==============================================================================
; CLI available Commands
;==============================================================================
;------------------------------------------------------------------------------
;	help - Show list of available commands
;------------------------------------------------------------------------------
CLI_CMD_HELP:
		ld		hl, msg_help
		call	F_KRN_SERIAL_WRSTR
		ret
;------------------------------------------------------------------------------
;	peek - Prints the value of a single memory address
;------------------------------------------------------------------------------
CLI_CMD_PEEK:
;	IN <= 	buffer_parm1_val = address
;	OUT => default output (e.g. screen, I/O)
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, peek				; param1 specified? Yes, do the peek
		ret								; no, exit routine
peek:
		call	param1val_uppercase
;		ld		hl, empty_line			; print an empty line
;		call	F_KRN_SERIAL_WRSTR
		ld		b, 1
		call 	F_KRN_SERIAL_EMPTYLINES
	; buffer_parm1_val has the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (param1)
		ld		a, (hl)					; load value at address of param1
		call	F_KRN_SERIAL_PRN_BYTE	; Prints byte in hexadecimal notation
		ret
;------------------------------------------------------------------------------
;	poke - calls poke subroutine that changes a single memory address 
;          to a specified value
;------------------------------------------------------------------------------
CLI_CMD_POKE:
;	IN <= 	buffer_parm1_val = memory address
; 			buffer_parm2_val = specified value
;	OUT => print message 'OK' to default output (e.g. screen, I/O)
	; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		call	check_param2			; yes, check param2
		; jp		nz, poke				; param2 specified? Yes, do the poke
		; ret								; no, exit routine
		ret		z						; param2 specified? No, exit routine
		; yes, change the value
		call	param1val_uppercase
		call	param2val_uppercase
		call	F_KRN_ASCII_TO_HEX		; Hex ASCII to Binary conversion
		; buffer_parm1_val have the address in hexadecimal ASCII
		; we need to convert its hexadecimal value (e.g. 33 => 03)
		ld		IX, buffer_parm1_val
		call	F_KRN_ASCIIADR_TO_HEX
		push	HL						; Backup HL
		; buffer_parm2_val have the value in hexadecimal ASCII
		; we need to convert its hexadecimal value (e.g. 33 => 03)
		ld		a, (buffer_parm2_val)
		ld		h, a
		ld		a, (buffer_parm2_val + 1)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX		; A contains the binary value for param2
		pop		HL						; Restore HL
		ld		(hl), a					; Store value in address
		; print OK, to let the user know that the command was successful
		ld		hl, msg_ok
		call	F_KRN_SERIAL_WRSTR
		ret

;------------------------------------------------------------------------------
;	autopoke - Allows to enter hexadecimal values that will be stored at the
;              address in parm1 and consecutive positions.
;              The address is incremented automatically after each hexadecimal 
;              value is entered. 
;              Entering no value (i.e. just press ENTER) will stop the process.
;------------------------------------------------------------------------------
CLI_CMD_AUTOPOKE:
;	IN <= 	buffer_parm1_val = Start address
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		; yes, convert address from ASCII to its hex value
		ld		IX, buffer_parm1_val
		call	F_KRN_ASCIIADR_TO_HEX
		; Use IX as pointer to memory address where the values entered by
		; the user will be stored. It's incremented after each value is entered
		ld		(tmp_addr1), HL
		ld		IX, (tmp_addr1)
autopoke_loop:
		; show a dollar symbol to indicate the user that can enter an hexadecimal
		ld	    hl, msg_prompt_hex      ; Prompt
		call	F_KRN_SERIAL_WRSTR      ; Output message
		; read 1st character
		call	F_KRN_SERIAL_RDCHARECHO	; read a character, with echo
		cp		CR						; test for 1st parameter entered
		jp		z, end_autopoke			; if it's CR, exit subroutine
		call	F_KRN_TOUPPER
		ld		H, A					; H = value's 1st digit
		; read 2nd character
		call	F_KRN_SERIAL_RDCHARECHO	; read a character, with echo
		cp		CR						; test for 1st parameter entered
		jp		z, end_autopoke				; if it's CR, exit subroutine
		call	F_KRN_TOUPPER
		ld		L, A					; L = value's 2nd digit
		; convert HL from ASCII to hex
		call	F_KRN_ASCII_TO_HEX		; A = HL in hex
		; Do the poke (i.e. store specified value at memory address)
		ld		(IX), A
		; Increment memory address pointer and loop back to get next value
		inc		IX
		jp		autopoke_loop
end_autopoke:
		ret		

;------------------------------------------------------------------------------
;	memdump - Shows memory contents of an specified section of memory
;------------------------------------------------------------------------------
CLI_CMD_MEMDUMP:
;	IN <= 	buffer_parm1_val = Start address
; 			buffer_parm2_val = End address
;	OUT => default output (e.g. screen, I/O)

	; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		call	check_param2			; yes, check param2
		jp		nz, memdump				; param2 specified? Yes, do the memdump
		ret								; no, exit routine
memdump:
		; print header
		ld		hl, msg_memdump_hdr
		call	F_KRN_SERIAL_WRSTR
	; buffer_parm2_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm2_val)
		ld		h, a
		ld		a, (buffer_parm2_val + 1)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		d, a
		ld		a, (buffer_parm2_val + 2)
		ld		h, a
		ld		a, (buffer_parm2_val + 3)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		e, a
	; DE contains the binary value for param2
		push	de						; store in the stack
	; buffer_parm1_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (HL=param1)
		pop		de						; restore from stack (DE=param2)
start_dump_line:
		ld		c, LINESPERPAGE			; we will print 23 lines per page
dump_line:
		push	hl
		ld		a, CR
		call	F_BIOS_SERIAL_CONOUT_A
		ld		a, LF
		call	F_BIOS_SERIAL_CONOUT_A
		call	F_KRN_SERIAL_PRN_WORD
		ld		a, ':'					; semicolon separates mem address from data
		call	F_BIOS_SERIAL_CONOUT_A
		ld		a, ' '					; and an extra space to separate
		call	F_BIOS_SERIAL_CONOUT_A
		ld		b, 10h					; we will output 16 bytes in each line
dump_loop:
		ld		a, (hl)
		call	F_KRN_SERIAL_PRN_BYTE
		ld		a, ' '
		call	F_BIOS_SERIAL_CONOUT_A
		inc		hl
		djnz	dump_loop
		; dump ASCII characters
		pop		hl
		ld		b, 10h					; we will output 16 bytes in each line
		ld		a, ' '
		call	F_BIOS_SERIAL_CONOUT_A
		call	F_BIOS_SERIAL_CONOUT_A
ascii_loop:
		ld		a, (hl)
		call	F_KRN_PRINTABLE			; is it an ASCII printable character?
		jr		c, printable
		ld		a, '.'					; if is not, print a dot
printable:
		call	F_BIOS_SERIAL_CONOUT_A
		inc		hl
		djnz	ascii_loop

		push	hl						; backup HL before doing sbc instruction
		and		a						; clear carry flag
		sbc		hl, de					; have we reached the end address?
		pop		hl						; restore HL
		jr		c, dump_next			; end address not reached. Dump next line
		ret
dump_next:
		dec		c						; 1 line was printed
		jp		z, askmoreorquit	 	; we have printed 23 lines. More?
		jp 		dump_line				; print another line
askmoreorquit:
		push	hl						; backup HL
		ld		hl, msg_moreorquit
		call	F_KRN_SERIAL_WRSTR
		call	F_BIOS_SERIAL_CONIN_A	; read key
		cp		SPACE					; was the SPACE key?
		jp		z, wantsmore			; user wants more
		pop		hl						; yes, user wants more. Restore HL
		ret								; no, user wants to quit
wantsmore:
		; print header
		ld		hl, msg_memdump_hdr
		call	F_KRN_SERIAL_WRSTR
		pop		hl						; restore HL
		jp		start_dump_line			; return to start, so we print 23 more lines

;------------------------------------------------------------------------------
;	run - Starts running instructions from a specific memory address
;------------------------------------------------------------------------------
CLI_CMD_RUN:
;	IN <= 	buffer_parm1_val = address
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, runner				; param1 specified? Yes, do the run
		ret								; no, exit routine
runner:
		call	param1val_uppercase
	; buffer_parm1_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_ASCII_TO_HEX
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (param1)
		jp		(hl)					; jump execution to address in HL
		ret
;------------------------------------------------------------------------------
; 	cat - Shows disk catalogue
;------------------------------------------------------------------------------
CLI_CMD_CF_CAT:
		; print header
		ld		HL, msg_cf_cat_title
		call	F_KRN_SERIAL_WRSTR
		ld		HL, msg_cf_cat_sep
		call	F_KRN_SERIAL_WRSTR
		ld		HL, msg_cf_cat_detail
		call	F_KRN_SERIAL_WRSTR
		ld		HL, msg_cf_cat_sep
		call	F_KRN_SERIAL_WRSTR
		; print catalogue
		call	F_CLI_CF_PRINT_DISKCAT
		ret
;------------------------------------------------------------------------------
; 	load - Load filename from disk to RAM
;------------------------------------------------------------------------------
CLI_CMD_CF_LOAD:
; IN <= buffer_parm1_val = Filename
; OUT => OK message on default output (e.g. screen, I/O)
		; Check parameter was specified
		call	check_param1
		ret		z								; param1 specified? No, exit routine
		ld		HL, buffer_parm1_val
		call	F_KRN_DZFS_GET_FILE_BATENTRY	; Yes, search filename in BAT
		; Was the filename found?
		ld		A, (tmp_addr3)
		cp		$AB
		jp		z, load_filename_not_found		; No, show error message
		ld		A, (tmp_addr3 + 1)
		cp		$BA
		jp		z, load_filename_not_found		; No, show error message
		; yes, continue
		ld		HL, (cur_file_load_addr)		; Load file into SYSVARS.cur_file_load_addr
		ld		DE, (cur_file_1st_sector)
		ld		IX, (cur_file_size_sectors)
		call	F_KRN_DZFS_LOAD_FILE_TO_RAM
		; show success message
		ld		HL, msg_cf_file_loaded
		call	F_KRN_SERIAL_WRSTR
		; Show SYSVARS.cur_file_load_addr
		ld		HL, (cur_file_load_addr)
		call	F_KRN_SERIAL_PRN_WORD
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
		ret
load_filename_not_found:
		ld		HL, error_1003
		call	F_KRN_SERIAL_WRSTR
		ret
;------------------------------------------------------------------------------
; 	diskinfo - Show CF information
;------------------------------------------------------------------------------
CLI_CMD_CF_DISKINFO:
; Info is stored in Words (2 bytes) and Double Words (4 bytes)
; Words are little-endian. For Double Words, 1st Word is the MSW in little endian
		call 	F_BIOS_CF_DISKINFO
		ld		HL, msg_cf_info
		call	F_KRN_SERIAL_WRSTR
		; Word 1: Number of cylinders
		ld		HL, msg_cf_info_numcyls
		call	F_KRN_SERIAL_WRSTR
		ld		HL, (CF_BUFFER_START + 2)	; offset for word 1
		call	F_KRN_BIN_TO_BCD6				; DE = HL in decimal
		ex		DE, HL
		call	F_KRN_SERIAL_PRN_WORD
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
		; Word 3: Number of heads
		ld		HL, msg_cf_info_numheads
		call	F_KRN_SERIAL_WRSTR
		ld		HL, (CF_BUFFER_START + 6)	; offset for word 3
		call	F_KRN_BIN_TO_BCD6				; DE = HL in decimal
		ex		DE, HL
		call	F_KRN_SERIAL_PRN_WORD
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
		; Word 6: Number of sectors per track
		ld		HL, msg_cf_info_secpertrk
		call	F_KRN_SERIAL_WRSTR
		ld		HL, (CF_BUFFER_START + 12)	; offset for word 3
		call	F_KRN_BIN_TO_BCD6				; DE = HL in decimal
		ex		DE, HL
		call	F_KRN_SERIAL_PRN_WORD
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
		; Words 10-19: Serial number (20 ASCII)
		ld		HL, msg_cf_info_sernum
		call	F_KRN_SERIAL_WRSTR
		ld		B, 20
		ld		HL, CF_BUFFER_START + 20
		call	F_KRN_SERIAL_PRN_BYTES
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
		; Words 23-26: Firmware revision (8 ASCII)
		ld		HL, msg_cf_info_firmw_rev
		call	F_KRN_SERIAL_WRSTR
		ld		B, 8
		ld		HL, CF_BUFFER_START + 46
		call	F_KRN_SERIAL_PRN_BYTES
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
		; Words 27-46: Model number (40 ASCII)
		ld		HL, msg_cf_info_model
		call	F_KRN_SERIAL_WRSTR
		ld		B, 40
		ld		HL, CF_BUFFER_START + 54
		call	F_KRN_SERIAL_PRN_BYTES
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
		; Words 23-26: Firmware revision (8 ASCII)
		; Words 27-46: Model number (40 ASCII)
		; Words 49: Capabilities (bit 9 = LBA Supported)
		; Words 51: PIO data transfer cycle timing mode
		; Words 54: Number of current cylinders
		; Words 55: Number of current heads
		; Words 56: Number of current sectors per track
		; Words 57-58: Current capacity in sectors
		; Words 60-61: Total number of user addressable sectors (LBA mode only)
		ret
;==============================================================================
; Disk Routines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_CF_PRINT_DISKCAT:
; Prints the contents (catalogue) of the CompactFlash Disk
; All entries in the BAT are consecutive. When a new file is stored, it will be 
; stored in the next available (first character = $00=available, or $FF=deleted).
; Hence, once we can read the BAT, and once we find the first entry with $00, we
; know there are no more entries. The maximum number of entries is 1744
		ld      A, 1						; BAT starts at sector 1
        ld      (cur_sector), A
        ld      A, 0
        ld      (cur_sector + 1), A
diskcat_nextsector:
		call	F_KRN_DZFS_READ_BAT_SECTOR
		; As we read in groups of 512 bytes (Sector), 
		; each read will put 16 entries in the buffer.
		; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
		; therefore 64 sectors.
		ld		A, 0						; entry counter
diskcat_print:
		push 	AF
		call	F_KRN_DZFS_BATENTRY2BUFFER

		; Check if the file should be displayed
		; i.e. first character is not 7E (deleted)
		;      and attribute bit 1 (hidden) is not 1
		; If first character is 00, then there aren't more entries.
		ld		A, (cur_file_name)
		cp		$7E							; File is deleted?
		jp		z, diskcat_nextentry		; Yes, skip it
		cp		$00							; Available entry? (i.e. no file)
		jp		z, diskcat_end				; Yes, no more entries then
		ld		A, (cur_file_attribs)
		and		2							; File is hidden?
		jp		nz,	diskcat_nextentry		; Yes, skip it

		; Print entry data
		; Filename
		ld		B, 14
		ld		HL, cur_file_name
		call	F_KRN_SERIAL_PRN_BYTES
		call	print_a_space
		call	print_a_space

		; Date created
; TODO - Need to convert into DD-MM-YYYY
		ld		A, 'D'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'D'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, '-'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, '-'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		call	print_a_space
		call	print_a_space
		; Time created
; TODO - Need to convert into hh:mm:ss		
		; call	F_KRN_TRANSLT_TIME
		ld		A, 'H'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'H'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, ':'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, ':'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'S'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'S'
		call	F_BIOS_SERIAL_CONOUT_A
		call	print_a_space
		call	print_a_space
		; Date last modif.
; TODO - Need to convert into DD-MM-YYYY
		ld		A, 'D'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'D'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, '-'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, '-'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'Y'
		call	F_BIOS_SERIAL_CONOUT_A
		call	print_a_space
		call	print_a_space
		; Time last modif.
; TODO - Need to convert into hh:mm:ss
		ld		A, 'H'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'H'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, ':'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'M'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, ':'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'S'
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, 'S'
		call	F_BIOS_SERIAL_CONOUT_A
		call	print_a_space
		call	print_a_space
		; Size
		ld		IY, cur_file_size_bytes
		ld		E, (IY)						; E = MSB
		ld		D, (IY + 1)					; D = LSB
		ex		DE, HL						; H = 1st byte (LSB), L = 2nd byte (LSB)
		call	F_KRN_BIN_TO_BCD6
		ex		DE, HL						; HL = converted 6-digit BCD
		ld		DE, buffer_pgm				; where the numbers in ASCII will be stored
		call	F_KRN_BCD_TO_ASCII
		; Print each of the 6 digits
		ld		IY, buffer_pgm
		ld		A, (IY + 0)
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, (IY + 1)
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, (IY + 2)
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, (IY + 3)
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, (IY + 4)
		call	F_BIOS_SERIAL_CONOUT_A
		ld		A, (IY + 5)
		call	F_BIOS_SERIAL_CONOUT_A
		call	print_a_space
		call	print_a_space
		call	print_a_space
		; Attributes (RHSE, R=Read Only, H=Hidden, S=System, E=Executable)
		call	F_CLI_CF_PRINT_ATTRBS
		
		; Add CR + LF
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES
diskcat_nextentry:
		pop		AF
		inc		A							; next entry
		cp		16							; did we process the 16 entries?
		jp		nz, diskcat_print			; No, process next entry
		; More entries in other sectors?
		ld		A, (cur_sector)
		inc		A							; increment sector counter
		ld		(cur_sector), A				; Did we process
		cp		64							;    64 sectors already?
; TODO - Change this 64, to be read from Superblock's Sectors per Block
		jp		nz, diskcat_nextsector		; No, then process next sector
		jp		diskcat_end_nopop
diskcat_end:
		pop     AF							; needed because previous push AF	
diskcat_end_nopop:
		ret									; Yes, then nothing else to do
;------------------------------------------------------------------------------
F_CLI_CF_PRINT_ATTRBS:
; Prints a string with letters (R=Read Only, H=Hidden, S=System, E=Executable)
; if file attribute is ON, or space if it's OFF
		ld		A, (cur_file_attribs)
		push	AF
		and		1							; Read Only?
		jp		nz, cf_attrb_is_ro			; No, print a space
		call	print_a_space
		jp		cf_attrib_hidden
cf_attrb_is_ro:								; Yes, print a dot
		ld		A, 'R'
		call	F_BIOS_SERIAL_CONOUT_A
cf_attrib_hidden:
		pop		AF
		push	AF
		and		2							; Hidden?
		jp		nz, cf_attrb_is_hidden		; No, print a space
		call	print_a_space
		jp		cf_attrib_system
cf_attrb_is_hidden:							; Yes, print a dot
		ld		A, 'H'
		call	F_BIOS_SERIAL_CONOUT_A
cf_attrib_system:
		pop		AF
		push	AF
		and		4							; System?
		jp		nz, cf_attrb_is_system		; No, print a space
		call	print_a_space
		jp		cf_attrib_executable
cf_attrb_is_system:							; Yes, print a dot
		ld		A, 'S'
		call	F_BIOS_SERIAL_CONOUT_A
cf_attrib_executable:
		pop		AF
		and		8							; Executable?
		jp		nz, cf_attrb_is_exec		; No, print a space
		call	print_a_space
		jp		print_attribs_end
cf_attrb_is_exec:							; Yes, print a dot
		ld		A, 'E'
		call	F_BIOS_SERIAL_CONOUT_A
print_attribs_end:
		ret

print_a_space:
		ld		A, ' '
		call	F_BIOS_SERIAL_CONOUT_A
		ret
;==============================================================================
; Messages
;==============================================================================
msg_cli_version:
		.BYTE	CR, LF
		.BYTE	"CLI    v1.0.0", 0
msg_bytesfree:
		.BYTE	" Bytes free", 0
msg_prompt:
		.BYTE	CR, LF
		.BYTE	"> ", 0
msg_prompt_hex:
		.BYTE	CR, LF
		.BYTE	"$ ", 0
msg_ok:
		.BYTE	CR, LF
		.BYTE	"OK", 0
msg_moreorquit:
		.BYTE	CR, LF
		.BYTE	"[SPACE] for more or another key for stop", 0
msg_help:
		.BYTE	CR, LF
		.BYTE	" dzOS Help", CR, LF
		.BYTE	"|-------------|-----------------------------------|--------------------|", CR, LF
		.BYTE	"| Command     | Description                       | Usage              |", CR, LF
		.BYTE	"|-------------|-----------------------------------|--------------------|", CR, LF
		.BYTE	"| help        | Shows this help                   | help               |", CR, LF
		.BYTE	"| memdump     | Memory Dump                       | memdump 0000,0100  |", CR, LF
		.BYTE	"| peek        | Show a Memory Address value       | peek 20cf          |", CR, LF
		.BYTE	"| poke        | Change a Memory Address value     | poke 20cf,ff       |", CR, LF
		.BYTE	"| autopoke    | Like poke, but autoincrement addr.| autopoke 2570      |", CR, LF
		.BYTE	"| reset       | Clears RAM and resets the system  | reset              |", CR, LF
		.BYTE	"| run         | Run from Memory Address           | run 2570           |", CR, LF
		.BYTE	"| halt        | Halt the system                   | halt               |", CR, LF
		.BYTE	"|             |                                   |                    |", CR, LF
		.BYTE	"| cat         | Show Disk Catalogue               | cat                |", CR, LF
		.BYTE   "| load        | Load filename from disk to RAM    | load file1         |", CR, LF
		.BYTE	"|-------------|-----------------------------------|--------------------|", 0
msg_dirlabel:
		.BYTE	"<DIR>", 0
msg_crc_ok:
		.BYTE	" ...[CRC OK]", CR, LF, 0
msg_memdump_hdr:
		.BYTE	CR, LF
		.BYTE	"      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", CR, LF
		.BYTE	"      .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..", 0
msg_exeloaded:
		.BYTE	CR, LF
		.BYTE	"Executable loaded at: 0x", 0
msg_cf_cat_title:
		.BYTE	CR, LF
		.BYTE	CR, LF
		.BYTE	"Disk Catalogue", CR, LF, 0
msg_cf_cat_sep:
		.BYTE	"-------------------------------------------------------------------------------", CR, LF, 0
msg_cf_cat_detail:
		.BYTE	"File              Created               Modified              Size   Attributes" , CR, LF, 0
msg_cf_file_loaded:
		.BYTE	CR, LF
		.BYTE	"File loaded successfully at address: $", 0
msg_cf_info:
		.BYTE	CR, LF
		.BYTE	CR, LF
		.BYTE	"CompactFlash diskinfo", CR, LF
		.BYTE	"----------------------------------------", CR, LF, 0
msg_cf_info_numcyls:
		.BYTE	"Cylinders . . . . : ", 0
msg_cf_info_numheads:
		.BYTE	"Heads . . . . . . : ", 0
msg_cf_info_secpertrk:
		.BYTE	"Sectors per Track : ", 0
msg_cf_info_sernum:
		.BYTE	"Serial Number . . : ", 0
msg_cf_info_firmw_rev:
		.BYTE	"Firmware revision : ", 0
msg_cf_info_model:
		.BYTE	"Model . . . . . . : ", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
		.BYTE	CR, LF
		.BYTE	"Command unknown (type help for list of available commands)", CR, LF, 0
error_1002:
		.BYTE	CR, LF
		.BYTE	"Bad parameter(s)", CR, LF, 0
error_1003:
		.BYTE	CR, LF
		.BYTE	"File not found", CR, LF, 0
;==============================================================================
; AVAILABLE CLI COMMANDS
;==============================================================================
_CMD_HELP			.BYTE	"help", 0
_CMD_MEMDUMP		.BYTE	"memdump", 0
; TODO - Convert memdump into a stand-alone executable program
_CMD_PEEK			.BYTE	"peek", 0
_CMD_POKE			.BYTE	"poke", 0
_CMD_AUTOPOKE		.BYTE	"autopoke", 0
_CMD_RESET			.BYTE	"reset", 0
_CMD_RUN			.BYTE	"run", 0
_CMD_HALT			.BYTE	"halt", 0

; CompactFlash commands
_CMD_CF_CAT			.BYTE	"cat", 0		; show files catalogue
_CMD_CF_LOAD		.BYTE	"load", 0		; load filename from disk to RAM
_CMD_CF_DISKINFO	.BYTE	"diskinfo", 0	; show CF information
; TODO - Convert diskinfo into a stand-alone executable program

;==============================================================================
; END of CODE
;==============================================================================
        .ORG	CLI_END
		.BYTE 	0
		.END