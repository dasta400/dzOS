;******************************************************************************
; kernel.video.asm
;
; Kernel's Serial routines
; for dastaZ80's dzOS
; by David Asta (Jun 2022)
;
; Version 1.0.0
; Created on 06 Jun 2022
; Last Modification 06 Jun 2022
;******************************************************************************
; CHANGELOG
; 	-
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

; Console = Serial (SIO/2) Channel A, connected to the Keyboard Controller (A3010KBD)
; Screen = Serial (SIO/2) Channel A, connected to the VGA Output (VGA32)

;------------------------------------------------------------------------------
KRN_SERIAL_SETFGCOLR:
; Set the colour that will be used for the foreground.
; The colour will remain until a new set is done.
; IN <= A = Colour number (as listed in equates.inc)
        ld      B, 5                    ; ANSI escape codes for colours are 5 bytes
        cp      ANSI_COLR_BLK
        jp      z, colour_is_black
        cp      ANSI_COLR_RED
        jp      z, colour_is_red
        cp      ANSI_COLR_GRN
        jp      z, colour_is_green
        cp      ANSI_COLR_YLW
        jp      z, colour_is_yellow
        cp      ANSI_COLR_BLU
        jp      z, colour_is_blue
        cp      ANSI_COLR_MGT
        jp      z, colour_is_magenta
        cp      ANSI_COLR_CYA
        jp      z, colour_is_cyan
        cp      ANSI_COLR_WHT
        jp      z, colour_is_white
        cp      ANSI_COLR_GRY
        jp      z, colour_is_grey
        jp      colour_is_other         ; White will be sent

colour_is_black:
        ld      DE, KRN_ANSI_COLR_BLK
        jp      KRN_SEND_ANSI_CODE
colour_is_red:
        ld      DE, KRN_ANSI_COLR_RED
        jp      KRN_SEND_ANSI_CODE
colour_is_green:
        ld      DE, KRN_ANSI_COLR_GRN
        jp      KRN_SEND_ANSI_CODE
colour_is_yellow:
        ld      DE, KRN_ANSI_COLR_YLW
        jp      KRN_SEND_ANSI_CODE
colour_is_blue:
        ld      DE, KRN_ANSI_COLR_BLU
        jp      KRN_SEND_ANSI_CODE
colour_is_magenta:
        ld      DE, KRN_ANSI_COLR_MGT
        jp      KRN_SEND_ANSI_CODE
colour_is_cyan:
        ld      DE, KRN_ANSI_COLR_CYA
        jp      KRN_SEND_ANSI_CODE
colour_is_white:
colour_is_other:
        ld      DE, KRN_ANSI_COLR_WHT
        jp      KRN_SEND_ANSI_CODE
colour_is_grey:
        ld      DE, KRN_ANSI_COLR_GRY
        jp      KRN_SEND_ANSI_CODE
;------------------------------------------------------------------------------
KRN_SERIAL_WRSTRCLR:
; Output a string to the Console, with a specific foreground colour
; IN <= A = Colour number (as listed in equates.inc)
;       HL = pointer to first character of the string
        call    F_KRN_SERIAL_SETFGCOLR  ; Set the foreground colour
        jp      F_KRN_SERIAL_WRSTR      ; Output the string
;------------------------------------------------------------------------------
KRN_SERIAL_WRSTR:
; Output to the Console a string of ASCII characters terminated with CR
; IN <= HL = pointer to first character of the string
        ld      A, (HL)                 ; Get character of the string
        or      A                       ; is it 00h? (i.e. end of string)
        ret     z                       ; if yes, then return
        rst     08h                     ; otherwise, print it
        inc     HL                      ; pointer to next character of the string
        jr      KRN_SERIAL_WRSTR        ; repeat (until character = 00h)
        ret
;------------------------------------------------------------------------------
KRN_SERIAL_WR6DIG_NOLZEROS:
; Output to the Console a string of ASCII characters representing number
;   without outputing leading zeros
; (.e.g. 30 30 31 32 30 34 is 001204, but the output is 1024)
; IN <= IX = address where the ASCII characters are stored
        or      A                       ; clear Carry Flag
        ld      DE, 0                   ; will use DE as a flag for leading zeros
        ld      B, 6                    ; 6 digits to print
_wr6dig_print:
        ld      A, (IX+0)               ; get digit
        cp      $30                     ; is it a zero? (in ASCII hex 0=$30)
        jp      nz, _wr6dig_print_digit ; no, then print digit
        bit     0, E                    ; if bit is set,
        jp      nz, _wr6dig_print_digit ;   it's not a leading zero, then print digit
        jp      _wr6dig_next_digit      ; otherwise, next digit
_wr6dig_print_digit:
        call    F_BIOS_SERIAL_CONOUT_A  ; print digit
        ld      E, 1                    ; set bit to indicate that a non zero was printed
                                        ;   and therefore there no more leading zeros
_wr6dig_next_digit:
        inc     IX                      ; point to next digit
        djnz    _wr6dig_print           ; and loop
        ret
;------------------------------------------------------------------------------
KRN_SERIAL_RDCHARECHO:
; Read a character, with echo
; Read a character from Console and outputs to the Screen
; Read character is stored in register A
        call    F_BIOS_SERIAL_CONIN_A
        call    F_BIOS_SERIAL_CONOUT_A
; ToDo - Check for special characters
; ToDo - Allow backspace
        ret
;------------------------------------------------------------------------------
KRN_SERIAL_EMPTYLINES:
; Output n empty lines
; IN <= B = number of empty lines to print out
; OUT => default output (e.g. screen, I/O)
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        djnz    KRN_SERIAL_EMPTYLINES
        ret
;------------------------------------------------------------------------------
KRN_SERIAL_PRN_BYTES:
; Prints bytes
; Print n number of bytes as ASCII characters
; IN <= B = number of bytes to print
;       HL = start memory address where the bytes are
; OUT => default output (e.g. screen, I/O)
        ld      A, (hl)                 ; get memory content pointed by HL into A
        cp      0                       ; is it null?
        jp      z, prnbytesend          ; yes, exit routine
        cp      LF                      ; new line?
        jp      nz, nonewline           ; no, contine normally
        ld      A, CR                   ; yes, print CR+LF
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
nonewline:
        call    F_BIOS_SERIAL_CONOUT_A  ; no, print character
        inc     HL                      ; pointer to next character
        djnz    KRN_SERIAL_PRN_BYTES    ; all bytes printed? No, continue printing
prnbytesend:
        ret                             ; yes, exit routine
;------------------------------------------------------------------------------
KRN_SERIAL_PRN_BYTE:
; Print Byte
; Prints a single byte in hexadecimal notation.
; IN <= A = the byte to be printed
; OUT => default output (e.g. screen, I/O)
        push    BC
        ; convert high nibble
        ld      B, A
        rrca                            ;move high nibble to low nibble
        rrca
        rrca
        rrca
        call    F_KRN_SERIAL_PRN_NIBBLE ; prints high nibble
        ;convert low nibble
        ld      A, B
        call    F_KRN_SERIAL_PRN_NIBBLE ; prints low nibble
        pop	BC
        ret
;------------------------------------------------------------------------------
KRN_SERIAL_PRN_NIBBLE:
; Print Nibble
; Prints a single hexadecimal nibble in hexadecimal notation.
; IN <= LSB of A
; OUT => default output (e.g. screen, I/O)
        and     $0f                     ; remove hight nibble
        cp      10                      ; is it a digit?
        jr      c, print_nibble         ; yes, print it
        add     A, 7                    ; no, add offset for letters
print_nibble:
        add     A, $30                  ; add offset for digits (30 to 39 in hex is 0 to 9 in dec)
        call    F_BIOS_SERIAL_CONOUT_A  ; print the nibble
        ret
;------------------------------------------------------------------------------
KRN_SERIAL_PRN_WORD:
; Print Word
; Prints the 4 hexadecimal digits of a word in hexadecimal notation.
; IN <= HL (the word to be printed)
; OUT => default output (e.g. screen, I/O)
        ld      A, H
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, L
        call    F_KRN_SERIAL_PRN_BYTE
        ret
;------------------------------------------------------------------------------
KRN_SERIAL_BACKSPACE:
; Routine for when user presses BACKSPACE key
        ld      DE, KRN_ANSI_BSPACE
        ld      B, 3
        ; jp      KRN_SEND_ANSI_CODE    ; Uncomment if other code is added after
                                        ; this subroutine, and before the next
;------------------------------------------------------------------------------
KRN_SEND_ANSI_CODE:
; Writes an ANSI code to the serial channel
; IN <= DE = first byte of ANSI escape code
;       B = number of bytes in the ANSI escape code
        ld      A, (DE)
        rst     08h
        inc     DE
        djnz    KRN_SEND_ANSI_CODE
        ret
;==============================================================================
; ANSI escape codes for Serial (https://en.wikipedia.org/wiki/ANSI_escape_code)
;==============================================================================
KRN_ANSI_BSPACE                 .BYTE   $1B, "\b"      ; Move cursor left 1 column

KRN_ANSI_COLR_BLK               .BYTE   $1B, "[30m"     ; Colour 0
KRN_ANSI_COLR_RED               .BYTE   $1B, "[31m"     ; Colour 1
KRN_ANSI_COLR_GRN               .BYTE   $1B, "[32m"     ; Colour 2
KRN_ANSI_COLR_YLW               .BYTE   $1B, "[33m"     ; Colour 3
KRN_ANSI_COLR_BLU               .BYTE   $1B, "[34m"     ; Colour 4
KRN_ANSI_COLR_MGT               .BYTE   $1B, "[35m"     ; Colour 5
KRN_ANSI_COLR_CYA               .BYTE   $1B, "[36m"     ; Colour 6
KRN_ANSI_COLR_WHT               .BYTE   $1B, "[37m"     ; Colour 7
KRN_ANSI_COLR_GRY               .BYTE   $1B, "[90m"     ; Colour 8
;KRN_ANSI_COLR_RED_BR            .BYTE   $1B, "[91m"
;KRN_ANSI_COLR_GRN_BR            .BYTE   $1B, "[92m"
;KRN_ANSI_COLR_YLW_BR            .BYTE   $1B, "[93m"
;KRN_ANSI_COLR_BLU_BR            .BYTE   $1B, "[94m"
;KRN_ANSI_COLR_MGT_BR            .BYTE   $1B, "[95m"
;KRN_ANSI_COLR_CYA_BR            .BYTE   $1B, "[96m"
;KRN_ANSI_COLR_WHT_BR            .BYTE   $1B, "[97m"

; Background colours
; KRN_ANSI_COLR_BG_BLK            .BYTE   $1B, "40m"
; KRN_ANSI_COLR_BG_RED            .BYTE   $1B, "41m"
; KRN_ANSI_COLR_BG_GRN            .BYTE   $1B, "42m"
; KRN_ANSI_COLR_BG_YLW            .BYTE   $1B, "43m"
; KRN_ANSI_COLR_BG_BLU            .BYTE   $1B, "44m"
; KRN_ANSI_COLR_BG_MGT            .BYTE   $1B, "45m"
; KRN_ANSI_COLR_BG_CYA            .BYTE   $1B, "46m"
; KRN_ANSI_COLR_BG_WHT            .BYTE   $1B, "47m"
; KRN_ANSI_COLR_BG_GRY            .BYTE   $1B, "100m"
; KRN_ANSI_COLR_BG_RED_BR         .BYTE   $1B, "101m"
; KRN_ANSI_COLR_BG_GRN_BR         .BYTE   $1B, "102m"
; KRN_ANSI_COLR_BG_YLW_BR         .BYTE   $1B, "103m"
; KRN_ANSI_COLR_BG_BLU_BR         .BYTE   $1B, "104m"
; KRN_ANSI_COLR_BG_MGT_BR         .BYTE   $1B, "105m"
; KRN_ANSI_COLR_BG_CYA_BR         .BYTE   $1B, "106m"
; KRN_ANSI_COLR_BG_WHT_BR         .BYTE   $1B, "107m"

; KRN_ANSI_COLR_DFT               .BYTE   $1B, "[39;49m"

; KRN_ANSI_FNT_NORMAL             .BYTE   $1B, "[0m"
; KRN_ANSI_FNT_BOLD               .BYTE   $1B, "[1m"
; KRN_ANSI_FNT_DIM                .BYTE   $1B, "[2m"
; KRN_ANSI_FNT_ITALIC             .BYTE   $1B, "[3m"
; KRN_ANSI_FNT_UNDERLINE          .BYTE   $1B, "[4m"
; KRN_ANSI_FNT_REVERSE_ON         .BYTE   $1B, "[7m"
; KRN_ANSI_FNT_REVERSE_OFF        .BYTE   $1B, "[27m"