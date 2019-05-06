;******************************************************************************
; CLI.asm
;
; Command-Line Interface
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 03 Jan 2018
;******************************************************************************
; CHANGELOG
; 	-
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; This file is part of dzOS
; Copyright (C) 2017-2018 David Asta

; dzOS is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; dzOS is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with dzOS.  If not, see <http://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------


;==============================================================================
; Includes
;==============================================================================
#include "src/equates.asm"
#include "exp/BIOS.exp"
#include "exp/kernel.exp"
#include "exp/sysvars.exp"
#include "exp/sysconsts.exp"

LINESPERPAGE			.EQU	17h		; 23 lines per page (for memdump)

;==============================================================================
; General Routines
;==============================================================================
		.ORG	CLI_START
cli_welcome:
		ld		hl, cli_msg_welcome		; CLI start up message
		call	F_KRN_WRSTR				; Output message
		ld		a, (CLI_BUILD)
		call	F_BIOS_CONOUT
		ld		a, (CLI_BUILD + 1)
		call	F_BIOS_CONOUT
		ld		a, (CLI_STATUS)
		call	F_BIOS_CONOUT
		ld		a, (CLI_STATUS + 1)
		call	F_BIOS_CONOUT
		ld		hl, empty_line
		call	F_KRN_WRSTR				; Output message
cli_promptloop:
        call	F_CLI_CLRCLIBUFFS	    ; Clear buffers
		ld	    hl, msg_prompt          ; Prompt
		call	F_KRN_WRSTR             ; Output message
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
		call	F_KRN_RDCHARECHO		; read a character, with echo
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

parse_cmd:
		ld		hl, buffer_cmd
		ld		a, (hl)
		cp		00h						; just an ENTER?
		jp		z, cli_promptloop		; show prompt again
		;search command "help"
		ld		de, _CMD_HELP
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_HELP			; yes, then execute the command
		;search command "loadihex"
		ld		de, _CMD_LOADIHEX
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_LOADIHEX		; yes, then execute the command
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
		;search command "memdump"
		ld		de, _CMD_MEMDUMP
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_MEMDUMP		; yes, then execute the command
		;search command "reset"
		ld		de, _CMD_RESET
		call	search_cmd				; was the command that we were searching?
		jp		z, F_BIOS_WBOOT			; yes, then execute the command
no_match:	; unknown command entered
		ld		hl, error_1001
		call	F_KRN_WRSTR
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
		jp		z, test_end_hl
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
		call	F_KRN_WRSTR				; print it
		ret
;------------------------------------------------------------------------------
param1val_uppercase:
; converts buffer_parm1_val to uppercase
		ld		hl, buffer_parm1_val - 1
		jp		p1vup_loop
param2val_uppercase:
; converts buffer_parm1_val to uppercase
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

		ld	    hl, buffer_parm1
		ld	    de, buffer_parm1 + 0fh	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm1_val
		ld	    de, buffer_parm1_val + 0fh   ; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm2
		ld	    de, buffer_parm2 + 0fh	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

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
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
;	peek - Prints the value of a single memory address
;------------------------------------------------------------------------------
CLI_CMD_PEEK:
;	IN <= 	buffer_parm1_val = address
;	OUT => default output (e.g. screen, I/O)
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, peek				; param1 specified yes, do the peek
		ret								; no, exit routine
peek:
		call	param1val_uppercase
		ld		hl, empty_line			; print an empty line
		call	F_KRN_WRSTR
	; buffer_parm1_val has the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (param1)
		ld		a, (hl)					; load value at address of param1
		call	F_KRN_PRN_BYTE			; Prints byte in hexadecimal notation
		ret
;------------------------------------------------------------------------------
;	poke - Changes a single memory address to a specified value
;------------------------------------------------------------------------------
CLI_CMD_POKE:
;	IN <= 	buffer_parm1_val = address
; 			buffer_parm2_val = value
;	OUT => print message 'OK' to default output (e.g. screen, I/O)
	; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified no, exit routine
		call	check_param2			; yes, check param2
		jp		nz, poke				; param2 specified yes, do the poke
		ret								; no, exit routine
poke:
		call	param1val_uppercase
		call	param2val_uppercase
		; convert param2 to uppercase and store in HL
		ld		hl, (buffer_parm2_val)
		ld		a, h
		call	F_KRN_TOUPPER
		ld		b, a
		ld		a, l
		call	F_KRN_TOUPPER
		ld		l, b
		ld		h, a
		call	F_KRN_HEX2BN			; Hex ASCII to Binary conversion
	; buffer_parm1_val have the address in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		e, a					; DE contains the binary value for param1
	; buffer_parm2_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm2_val)
		ld		h, a
		ld		a, (buffer_parm2_val + 1)
		ld		l, a
		call	F_KRN_HEX2BN			; A contains the binary value for param2
		ex		de, hl					; move from DE to HL
		ld		(hl), a					; store value in address
	; print OK, to let the user know that the command was successful
		ld		hl, msg_ok
		call	F_KRN_WRSTR
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
		ret		z						; param1 specified no, exit routine
		call	check_param2			; yes, check param2
		jp		nz, memdump				; param2 specified yes, do the memdump
		ret								; no, exit routine
memdump:
	; buffer_parm2_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm2_val)
		ld		h, a
		ld		a, (buffer_parm2_val + 1)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		d, a
		ld		a, (buffer_parm2_val + 2)
		ld		h, a
		ld		a, (buffer_parm2_val + 3)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		e, a
	; DE contains the binary value for param2
		push	de						; store in the stack
	; buffer_parm1_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (HL=param1)
		pop		de						; restore from stack (DE=param2)
start_dump_line:
		ld		c, LINESPERPAGE			; we will print 23 lines per page
dump_line:
		push	hl
		ld		a, CR
		call	F_BIOS_CONOUT
		ld		a, LF
		call	F_BIOS_CONOUT
		call	F_KRN_PRN_WORD
		ld		a, ':'					; semicolon separates mem address from data
		call	F_BIOS_CONOUT
		ld		a, ' '					; and an extra space to separate
		call	F_BIOS_CONOUT
		ld		b, 10h					; we will output 16 bytes in each line
dump_loop:
		ld		a, (hl)
		call	F_KRN_PRN_BYTE
		ld		a, ' '
		call	F_BIOS_CONOUT
		inc		hl
		djnz	dump_loop
		; dump ASCII characters
		pop		hl
		ld		b, 10h					; we will output 16 bytes in each line
		ld		a, ' '
		call	F_BIOS_CONOUT
		call	F_BIOS_CONOUT
ascii_loop:
		ld		a, (hl)
		call	F_KRN_PRINTABLE			; is it an ASCII printable character?
		jr		c, printable
		ld		a, '.'					; if is not, print a dot
printable:
		call	F_BIOS_CONOUT
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
		call	F_KRN_WRSTR
		call	F_BIOS_CONIN			; read key
		cp		SPACE					; was the SPACE key?
		jp		z, wantsmore			; user wants more
		pop		hl						; yes, user wants more. Restore HL
		ret								; no, user wants to quit
wantsmore:
		pop		hl						; restore HL
		jp		start_dump_line			; return to start, so we print 23 more lines
;------------------------------------------------------------------------------
;	loadihex - Load Intel HEX file into memory
;------------------------------------------------------------------------------
CLI_CMD_LOADIHEX:
; IMPORTANT NOTE: Checksum is not implemented
;
; Intel HEX record structure
;	A record (line of text) consists of six fields that appear in order
;	from left to right
;		START CODE; one character, an ASCII colon.
;		BYTE COUNT; 2 hex digits, indicating number of bytes in data field.
;		ADDRESS; 4 hex digits, representing the 16-bit beginning memory
;		  address offset of the data
;		RECORD TYPE; 2 hex digits, defining the meaning of the data field.
;			00 = data
;			01 = end of file
;			02 = Extended Segment Address
;			03 = Start Segment Address
;			04 = Extended Linear Address
;			05 = Start Linear Address
;		DATA; a sequence of n bytes of data, represented by 2n hex digits.
;		CHECKSUM; 2 hex digits, a computed value that can be used to verify
;		  the record has no errors. It is computed by summing the decoded
;		  byte values and extracting the LSB of the sum and then calculating
;		  the two's complement of the LSB.
;
; Used registers
; 	A = Received iHEX bytes
; 	D = byte count from iHEX
; 	HL = pointer to memory address

		ld		hl, msg_rcvhex
		call	F_KRN_WRSTR
		ld		c, 0					; initilise C, to store checksum
start_ihexload:
		; Start code (1 byte)
		call	F_KRN_RDCHARECHO		; get START CODE (1 char)
		cp		':'						; is it colon?
		jp		nz, ihexload_error		; no, show error and return
		; Byte count (1 byte)
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		d, a					; store it in D
		; Address (2 bytes)
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		h, a
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		l, a
	; HL contains now the address from iHex file
		; Record type (1 byte)
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		cp		01h						; is it End Of File?
		jp		z, ihexload_end 		; yes, show finished message and end
		cp		00h						; no, is it Data?
		jp		nz, ihexload_error		; no, show error and return
		; Data (n bytes, where n is equal to BYTE COUNT)
get_data:
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		(hl), a					; store byte in memory
		inc		hl						; increment memory address pointer
		dec		d						; decrement byte count counter
		ld		a, d					; copy D to A to make compare
		cp		0						; did we loaded all bytes?
		jp		nz, get_data			; no, get more data
		; Checksum (1 byte)
	; Checksum is not implemented, we just read the byte and discard it
		call	F_KRN_RDCHARECHO		; get START CODE (1 char)
		call	F_KRN_RDCHARECHO		; get START CODE (1 char)
		; CRLF (1 byte)
		call	F_BIOS_CONIN 			; get CR
		ld		hl, msg_crc_ok
		call	F_KRN_WRSTR
		jp		start_ihexload			; and get next line
ihexload_error:							; invalid Intel HEX file
		ld		hl, error_1003
		call	F_KRN_WRSTR
		ret
ihexload_end: 							; RECORD TYPE = End Of File (01), then last byte must be FF
	; Checksum is not implemented, we just read the byte and discard it
		call	F_KRN_GET_BYTE_BIN_ECHO	; get 1 byte from input and put it in binary in A
		ld		hl, msg_crc_ok
		call	F_KRN_WRSTR
		ld		hl, msg_endhex			; yes, show success message
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
;	run - Starts running instructions from a specific memory address
;------------------------------------------------------------------------------
CLI_CMD_RUN:
;	IN <= 	buffer_parm1_val = address
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, runner				; param1 specified yes, do the run
		ret								; no, exit routine
runner:
		call	param1val_uppercase
	; buffer_parm1_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_HEX2BN
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (param1)
		jp		(hl)					; jump execution to address in HL
		ret
;==============================================================================
; Messages
;==============================================================================
empty_line:
		.BYTE	CR, LF, 0
cli_msg_welcome:
		.BYTE	"CLI    v1.0.0.", 0
msg_prompt:
		.BYTE	CR, LF
		.BYTE	"> ", 0
msg_ok:
		.BYTE	CR, LF
		.BYTE	"OK", 0
msg_moreorquit:
		.BYTE	CR, LF
		.BYTE	"[SPACE] for more or another key for stop", 0
msg_help:
		.BYTE	CR, LF
		.BYTE	" dzOS Help", CR, LF
		.BYTE	"|-------------|----------------------------------|--------------------|", CR, LF
		.BYTE	"| Command     | Description                      | Usage              |", CR, LF
		.BYTE	"|-------------|----------------------------------|--------------------|", CR, LF
		.BYTE	"| help        | Shows this help                  | help               |", CR, LF
		.BYTE	"| loadihex    | Load Intel HEX file              | loadihex 2600      |", CR, LF
		.BYTE	"| memdump     | Memory Dump                      | memdump 0000,0100  |", CR, LF
		.BYTE	"| peek        | Show a Memory Address value      | peek 20cf          |", CR, LF
		.BYTE	"| poke        | Change a Memory Address value    | poke 20cf,ff       |", CR, LF
		.BYTE	"| reset       | Clears RAM and resets the system | reset              |", CR, LF
		.BYTE	"| run         | Run from Memory Address          | run 2600           |", CR, LF
		.BYTE	"|-------------|----------------------------------|--------------------|", 0
msg_rcvhex:
		.BYTE	CR, LF
		.BYTE	"PASTE THE .HEX FILE INTO THE TERMINAL WINDOW", CR, LF, 0
msg_endhex:
		.BYTE	CR, LF
		.BYTE	"Intel HEX file received successfully", CR, LF, 0
msg_cf_test_start:
		.BYTE	CR, LF
		.BYTE	"CF Card Test", CR, LF, 0
msg_cf_test_end:
		.BYTE	"Sector 0 was loaded into RAM", CR, LF, 0
msg_crc_ok:
		.BYTE	" ...[CRC OK]", CR, LF, 0
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
		.BYTE	"Invalid Intel HEX format", CR, LF, 0
error_1004:	
		.BYTE	CR, LF
		.BYTE	"Checksum error", CR, LF, 0
;==============================================================================
; AVAILABLE CLI COMMANDS
;==============================================================================
_CMD_HELP		.BYTE	"help", 0
_CMD_LOADIHEX	.BYTE	"loadihex", 0
_CMD_MEMDUMP	.BYTE	"memdump", 0
_CMD_PEEK		.BYTE	"peek", 0
_CMD_POKE		.BYTE	"poke", 0
_CMD_RESET		.BYTE	"reset", 0
_CMD_RUN		.BYTE	"run", 0
;==============================================================================
; END of CODE
;==============================================================================
        .ORG	CLI_END
		.BYTE	0
		.END