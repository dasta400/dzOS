;******************************************************************************
; BIOS.VDP.asm
;
; BIOS' VDP (TMS9918A) routines
; for dastaZ80's dzOS
; by David Asta (December 2022)
;
; Version 0.1.0
; Created on 19 Dec 2022
; Last Modification 19 Dec 2022
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
;
; VDP
;   /CSW Low = /IORQ Low & /CS ($10-$1F) Low & /WR Low
;   /CSR Low = /IORQ Low & /CS ($10-$1F) Low & /RD Low
;   MODE = A0

;------------------------------------------------------------------------------
BIOS_VDP_SET_ADDR_WR:
; Set a VRAM address for writting
; IN <= HL = address to be set
        ld      C, VDP_REG              ; MODE 1
        set     6, H                    ; set VDP to write to VRAM
        out     (C), L                  ; send low nibble
        nop                             ; recommended delay between sends
        out     (C), H                  ; send high nibble
        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_ADDR_RD:
; Set a VRAM address for reading
; IN <= HL = address to be read
        ld      C, VDP_REG              ; MODE 1
        ld      A, H                    ; set VDP to
        and     $3F                     ;   read from VRAM
        out     (C), L                  ; send low nibble
        nop                             ; recommended delay between sends
        out     (C), A                  ; send high nibble
        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_REGISTER:
; Set a value to a VDP register
; IN <= A = register number
;       B = value to set
        add     A, $80                  ; set VDP to write to registers
        ld      C, VDP_REG
        out     (C), B                  ; send value
        nop                             ; recommended delay between sends
        out     (C), A                  ; send register to receive the value
        ret
;------------------------------------------------------------------------------
BIOS_VDP_VRAM_CLEAR:
; Set all cells of the VRAM ($0000-$3FFF) to zero
        ld      HL, $0000               ; HL = first address of VRAM
        call    F_BIOS_VDP_SET_ADDR_WR  ; Set first address. VDP will autoincrement
        ; Doing a loop using D as a counter, can only do 256 ($FF).
        ;   But we need to test 16384 cells.
        ;   So do another loop with B, 16384 / 256 = 64 times
        ld      B, 64                   ; outer loop decrementing
        xor     A                       ; all cells to zero
        ld      D, A                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0
_clearvram:
        out     (C), A
        inc     D
        jr      nz, _clearvram          ; inner loop
        djnz    _clearvram              ; outer loop
        ret
;------------------------------------------------------------------------------
BIOS_VDP_VRAM_TEST:
; Sets a value to each VRAM cell and then reads it back. If the value is not
;   the same, something went wrong.
; OUT => Carry Flag set if an error ocurred

        ; Write values to VRAM
        ld      HL, $0000               ; HL = first address of VRAM
        call    F_BIOS_VDP_SET_ADDR_WR  ; Set first address. VDP will autoincrement
        ; Doing a loop using D as a counter, can only do 256 ($FF).
        ;   But we need to test 16384 cells.
        ;   So do another loop with B, 16384 / 256 = 64 times
        ld      B, 64                   ; outer loop decrementing
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
_testram_write:
        ld      A, D                    ; write same value as inner loop counter
        out     (C), A
        inc     D
        jr      nz, _testram_write      ; inner loop
        djnz    _testram_write          ; outer loop

        ; Read and test values from VRAM
        ld      HL, $0000               ; HL = first address of VRAM
        call    F_BIOS_VDP_SET_ADDR_RD  ; Set first address. VDP will autoincrement
        ld      B, 64
        ld      HL, tmp_byte            ; Will use SYSVARS.tmp_byte
        ld      (HL), 0                 ;   as the comparator
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
_testram_read:
        in      A, (C)
        cp      (HL)                    ; is the same as expected?
        jp      nz, _testram_error      ; no, set error flag
        inc     (HL)                    ; yes, continue
        jr      nz, _testram_read
        djnz    _testram_read
        xor     A                       ; Teset Carry Flag to indicate no error
        ret

_testram_error:
        scf                             ; Set Carry Flag to indicate error
        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_MODE_G2:
; Set VDP to Graphics II Mode as Bit-mapped display
;   Initialise Pattern Table with all zeros
;   Set all colours the same
;   Write consecutive numbers for each entry in the Name Table
;       (i.e. 0x00-0xFF three times)
        ld      A, 0
        ld      B, VDP_G2_REG_0
        call    BIOS_VDP_SET_REGISTER

        ld      A, 1
        ld      B, VDP_G2_REG_1
        call    BIOS_VDP_SET_REGISTER

        ld      A, 2
        ld      B, VDP_G2_REG_2
        call    BIOS_VDP_SET_REGISTER

        ld      A, 3
        ld      B, VDP_G2_REG_3
        call    BIOS_VDP_SET_REGISTER

        ld      A, 4
        ld      B, VDP_G2_REG_4
        call    BIOS_VDP_SET_REGISTER

        ld      A, 5
        ld      B, VDP_G2_REG_5
        call    BIOS_VDP_SET_REGISTER

        ld      A, 6
        ld      B, VDP_G2_REG_6
        call    BIOS_VDP_SET_REGISTER


        ; Initialise the 6144 bytes of the Pattern Table, with all zeros
        ld      HL, VDP_G2_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 24                   ; outer loop decrementing (6144 / 256 = 24 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
        ld      A, 0                    ; write zeros
_ini_patt_tab:
        out     (C), A
        inc     D
        jr      nz, _ini_patt_tab       ; inner loop
        djnz    _ini_patt_tab           ; outer loop

        ; Initialise the Color Table with White pixels over Black background
        ld      HL, VDP_G2_COLR_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 24                   ; outer loop decrementing (6144 / 256 = 24 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
        ld      A, $F1                  ; White pixels over Black background
_ini_colr_tab:
        out     (C), A
        inc     D
        jr      nz, _ini_colr_tab       ; inner loop
        djnz    _ini_colr_tab           ; outer loop

        ; Write consecutive numbers for each entry in the Name Table
        ; Write values to VRAM
        ld      HL, VDP_G2_NAME_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 3                    ; outer loop decrementing (3 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
_ini_name_tab:
        ld      A, D                    ; write same value as inner loop counter
        out     (C), A
        inc     D
        jr      nz, _ini_name_tab       ; inner loop
        djnz    _ini_name_tab           ; outer loop

        ret
;------------------------------------------------------------------------------
BIOS_VDP_SHOW_DZ_LOGO:  ; ToDo - Optimise this
; Show dastaZ80 logo on the screen
        ; Copy Logo patterns (88 bytes) to 
        ;   Pattern Table (Repeated for each of the 3 blocks)
        ld      HL, VDP_G2_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      IX, VDP_LOGO_PATT_START ; DE = pointer to Logo patterns start
        ld      B, 88
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
_logo_fill_patt_tab1:
        ld      A, (IX)
        out     (C), A
        inc     IX
        djnz    _logo_fill_patt_tab1    ; outer loop

        ld      HL, VDP_G2_PATT_TAB
        ld      DE, 2048
        xor     A
        add     HL, DE
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      IX, VDP_LOGO_PATT_START ; DE = pointer to Logo patterns start
        ld      B, 88
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
_logo_fill_patt_tab2:
        ld      A, (IX)
        out     (C), A
        inc     IX
        djnz    _logo_fill_patt_tab2    ; outer loop

        ld      HL, VDP_G2_PATT_TAB
        ld      DE, 4096
        xor     A
        add     HL, DE
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      IX, VDP_LOGO_PATT_START ; DE = pointer to Logo patterns start
        ld      B, 88
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
_logo_fill_patt_tab3:
        ld      A, (IX)
        out     (C), A
        inc     IX
        djnz    _logo_fill_patt_tab3    ; outer loop

        ; Set background colour (3 bands of RGB, every 2048 bytes)
        ld      HL, VDP_G2_COLR_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 8                    ; outer loop decrementing (2048 / 256 = 8 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
        ld      A, $16                  ; Black pixels over Dark Red background
_logo_fill_bck_clr1:
        out     (C), A
        inc     D
        jr      nz, _logo_fill_bck_clr1 ; inner loop
        djnz    _logo_fill_bck_clr1     ; outer loop

        ld      B, 8                    ; outer loop decrementing (2048 / 256 = 8 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
        ld      A, $1C                  ; Black pixels over Dark Green background
_logo_fill_bck_clr2:
        out     (C), A
        inc     D
        jr      nz, _logo_fill_bck_clr2 ; inner loop
        djnz    _logo_fill_bck_clr2     ; outer loop

        ld      B, 8                    ; outer loop decrementing (2048 / 256 = 8 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
        ld      A, $14                  ; Black pixels over Dark Blue background
_logo_fill_bck_clr3:
        out     (C), A
        inc     D
        jr      nz, _logo_fill_bck_clr3 ; inner loop
        djnz    _logo_fill_bck_clr3     ; outer loop

        ; Copy Logo names (768 bytes) to Name Table
        ld      IX, VDP_LOGO_NAME_START ; DE = pointer to Logo patterns start
        ld      HL, VDP_G2_NAME_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 3                   ; outer loop decrementing (768 / 256 = 3 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
_logo_fill_name_tab:
        ld      A, (IX)                 ; White pixels over Black background
        out     (C), A
        inc     IX
        inc     D
        jr      nz, _logo_fill_name_tab ; inner loop
        djnz    _logo_fill_name_tab     ; outer loop
        ret