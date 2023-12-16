;******************************************************************************
; kernel.vdp.asm
;
; Kernel's VDP routines
; for dastaZ80's dzOS
; by David Asta (Aug 2023)
;
; Version 1.1.0
; Created on 17 Aug 2023
; Last Modification 16 Dec 2023
;******************************************************************************
; CHANGELOG
;     - 16 Dec 2023 - Added KRN_VDP_SET_MODE
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2023 David Asta
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

;-----------------------------------------------------------------------------
KRN_VDP_WRSTR:
; Displays a text in the VDP screen, starting at a specified XY position
; The text MUST be a zero terminated string
; IN <= B = Cursor X start position
;       C = Cursor Y start position
;       HL = Address of a zero terminated string

        ; Set cursor to starting position
        ld      A, B                    ; Set
        ld      (VDP_cursor_x), A       ;   initial values
        ld      A, C                    ;   for
        ld      (VDP_cursor_y), A       ;   XY cursor position
        ; Output character by character, until $00 is found,
        ;   meanwhile incrementing XY
_vdp_wrstr_loop:
        ld      A, (HL)                 ; get a character
        cp      0                       ; if terminator character found
        jr      z, _vdp_wrstr_end       ;   do not print anymore and exit
        push    HL
        call    F_BIOS_VDP_CHAROUT_ATXY ; output character at XY position
        pop     HL
        inc     HL                      ; next character in the string
        jr      _vdp_wrstr_loop
_vdp_wrstr_end:
        ret
;-----------------------------------------------------------------------------
KRN_VDP_GET_CURSOR_ADDR:
; Returns the VRAM address of a specific XY position on the VDP screen
; IN <= B = screen X position
;       C = screen Y position
; OUT => HL = address
        push    BC                      ; backup input parameters
        ld      IX, KRN_LKT_MULT_BY_32  ; To speed up, do multiplication
        ld      A, C                    ;   by using a pre-calculated table
        cp      0                       ; except when is 0,
        jr      z, _cursor_at_0         ;   that we don't need to multiply
        ; y_position * 32
        ld      B, A                    ; counter = Y position
        ld      D, 0                    ; We don't use D, so initialise to 0
        ld      E, 2                    ; the table is 2 bytes for each entry
_mult_loop:
        add     IX, DE                  ; IX = pointer to entry in table
        djnz    _mult_loop              ; repeat until IX equals entry number

        ld      L, (IX)                 ; L = entry MSB
        ld      H, (IX + 1)             ; H = entry LSB
        ld      D, 0                    ; We don't use D, so initialise to 0
        pop     BC                      ; restore input parameters
        ld      A, B
        ld      E, A
        add     HL, DE
        ex      DE, HL                  ; DE  = (y_position * 32) + x_position
        ; Do VDP_NAMETAB_addr + (y_position * 32) + x_position
        ld      HL, (VDP_NAMETAB_addr)
        add     HL, DE
        ret                             ; end of get_cursor_addr
_cursor_at_0:
        ld      HL, (VDP_NAMETAB_addr)  ; When cursor at 0, return the address
        ret                             ;   of the Name Table start
;-----------------------------------------------------------------------------
KRN_VDP_CLEARSCREEN:
; Clears the VDP screen, by filling the Name Table with zeros
;   Name Table sizes:
;       0 - Text Mode                   = 960 bytes
;       1 - Graphics I Mode             = 1024 bytes
;       2 - Graphics II Mode            = 768 bytes
;       3 - Multicolour Mode            = 768 bytes
;       4 - Graphics II Bitmapped Mode  = 768 bytes

        ; Check which is the current mode
        ld      A, (VDP_cur_mode)
        cp      $00
        jr      z, _cls_mode_0
        cp      $01
        jr      z, _cls_mode_1
        cp      $02
        jr      z, _cls_mode_others
        cp      $03
        jr      z, _cls_mode_others
        cp      $04
        jr      z, _cls_mode_others

        ; Unknown mode. Show error and exit
        ld      HL, error_3002
        ld      A, (col_kernel_error)
        call    F_KRN_SERIAL_WRSTRCLR
        ret

_cls_mode_0:
        ; Fill 960 bytes of the Name Table with zeros
        ; 256 * 3 = 768 + 192 = 960
        ld      HL, (VDP_NAMETAB_addr)
        call    F_BIOS_VDP_SET_ADDR_WR
        ; fill frist 768 bytes
        ld      D, 3                    ; outer loop is 3
        ld      B, 0                    ; inner loop is 256
        xor     A                       ; fill with zeros
        call    _cls_loop
        ; fill remaining 192 bytes
        ld      D, 0
        ld      B, 192
        xor     A
        jr      _cls_loop
        ret
_cls_mode_1:
        ; Fill 1024 bytes of the Name Table with zeros
        ; 256 * 4 = 768
        ld      HL, (VDP_NAMETAB_addr)
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      D, 4                    ; outer loop is 4
        ld      B, 0                    ; inner loop is 256
        xor     A                       ; fill with zeros
        jr      _cls_loop
_cls_mode_others:
        ; Fill 768 bytes of the Name Table with zeros
        ; 256 * 3 = 768
        ld      HL, (VDP_NAMETAB_addr)
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      D, 3                    ; outer loop is 3
        ld      B, 0                    ; inner loop is 256
        xor     A                       ; fill with zeros

_cls_loop:
        call    F_BIOS_VDP_BYTE_TO_VRAM ; fill VRAM address
        djnz    _cls_loop               ; until 256 times
        dec     D                       ; decrement outer loop counter
        jr      nz, _cls_loop           ; and repeat until 0
        ret
;-----------------------------------------------------------------------------
KRN_VDP_CHG_COLOUR_FGBG:
; Changes the Foreground and Background colours
; IN <= A = Foreground colour
;       B = Background colour
        rlc     A                       ; move the
        rlc     A                       ;   4 LSB
        rlc     A                       ;   to be
        rlc     A                       ;   the MSB
        add     A, B                    ; add B as LSB

        ld      B, A                    ; put result in B
; This subroutine continues with same code as KRN_VDP_CHG_COLOUR_BORDER
;   because it does the same.
; DO NOT WRITE ANY CODE BETWEEN THESE 2 SUBROUTINES
;-----------------------------------------------------------------------------
KRN_VDP_CHG_COLOUR_BORDER:
; IN <= B = Border colour
        ld      A, $07                  ; send the result
        call    F_BIOS_VDP_SET_REGISTER ;   to VDP register $07
        ret
;-----------------------------------------------------------------------------
KRN_VDP_SET_MODE:
; IN <= A = Mode to be set (0-4)
        cp      0
        jr      z, _set_mode0
        cp      1
        jr      z, _set_mode1
        cp      2
        jr      z, _set_mode2
        cp      3
        jr      z, _set_mode3
        cp      4
        jr      z, _set_mode4
        ret

_set_mode0:
        call    F_BIOS_VDP_SET_MODE_TXT
        ret
_set_mode1:
        call    F_BIOS_VDP_SET_MODE_G1
        ret
_set_mode2:
        call    F_BIOS_VDP_SET_MODE_G2
        ret
_set_mode3:
        call    F_BIOS_VDP_SET_MODE_MULTICLR
        ret
_set_mode4:
        call    F_BIOS_VDP_SET_MODE_G2BM
        ret