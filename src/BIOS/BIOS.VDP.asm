;******************************************************************************
; BIOS.VDP.asm
;
; BIOS' VDP (TMS9918A) routines
; for dastaZ80's dzOS
; by David Asta (December 2022)
;
; Version 1.0.0
; Created on 19 Dec 2022
; Last Modification 21 Sep 2023
;******************************************************************************
; CHANGELOG
;   - 17 Aug 2023 - Added parameters Sprite Size and Sprite Magnification to
;                       all F_BIOS_VDP_SET_MODE_ functions.
;   - 21 Sep 2023 - Changed BIOS_VDP_VBLANK_WAIT due to VDP bug
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2022-2023 David Asta
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

;==============================================================================
; Tables
;==============================================================================
VDP_G1_REG_TAB:     ; Graphics I Mode
        .BYTE   VDP_G1_REG_0
        .BYTE   VDP_G1_REG_1
        .BYTE   VDP_G1_REG_2
        .BYTE   VDP_G1_REG_3
        .BYTE   VDP_G1_REG_4
        .BYTE   VDP_G1_REG_5
        .BYTE   VDP_G1_REG_6
        .BYTE   VDP_G1_REG_7
VDP_G2_REG_TAB:     ; Graphics II Mode
        .BYTE   VDP_G2_REG_0
        .BYTE   VDP_G2_REG_1
        .BYTE   VDP_G2_REG_2
        .BYTE   VDP_G2_REG_3
        .BYTE   VDP_G2_REG_4
        .BYTE   VDP_G2_REG_5
        .BYTE   VDP_G2_REG_6
        .BYTE   VDP_G2_REG_7
VDP_MM_REG_TAB:     ; Multicolour Mode
        .BYTE   VDP_MM_REG_0
        .BYTE   VDP_MM_REG_1
        .BYTE   VDP_MM_REG_2
        .BYTE   VDP_MM_REG_3
        .BYTE   VDP_MM_REG_4
        .BYTE   VDP_MM_REG_5
        .BYTE   VDP_MM_REG_6
        .BYTE   VDP_MM_REG_7
VDP_TXT_REG_TAB:    ; Text Mode
        .BYTE   VDP_TXT_REG_0
        .BYTE   VDP_TXT_REG_1
        .BYTE   VDP_TXT_REG_2
        .BYTE   VDP_TXT_REG_3
        .BYTE   VDP_TXT_REG_4
        .BYTE   VDP_TXT_REG_5
        .BYTE   VDP_TXT_REG_6
        .BYTE   VDP_TXT_REG_7
;------------------------------------------------------------------------------
VDP_MULT_32Y:
; Result of (32 * Y)
        .WORD   $0000
        .WORD   $0020
        .WORD   $0040
        .WORD   $0060
        .WORD   $0080
        .WORD   $00A0
        .WORD   $00C0
        .WORD   $00E0
        .WORD   $0100
        .WORD   $0120
        .WORD   $0140
        .WORD   $0160
        .WORD   $0180
        .WORD   $01A0
        .WORD   $01C0
        .WORD   $01E0
        .WORD   $0200
        .WORD   $0220
        .WORD   $0240
        .WORD   $0260
        .WORD   $0280
        .WORD   $02A0
        .WORD   $02C0
        .WORD   $02E0
VDP_MULT_40Y:
; Result of (40 * Y)
        .WORD   $0000
        .WORD   $0028
        .WORD   $0050
        .WORD   $0078
        .WORD   $00A0
        .WORD   $00C8
        .WORD   $00F0
        .WORD   $0118
        .WORD   $0140
        .WORD   $0168
        .WORD   $0190
        .WORD   $01B8
        .WORD   $01E0
        .WORD   $0208
        .WORD   $0230
        .WORD   $0258
        .WORD   $0280
        .WORD   $02A8
        .WORD   $02D0
        .WORD   $02F8
        .WORD   $0320
        .WORD   $0348
        .WORD   $0370
        .WORD   $0398
;==============================================================================
; Subroutines
;==============================================================================
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
        push    AF
        add     A, $80                  ; set VDP to write to registers
        ld      C, VDP_REG
        out     (C), B                  ; send value
        nop                             ; recommended delay between sends
        out     (C), A                  ; send register to receive the value
        pop     AF
        ret
;------------------------------------------------------------------------------
BIOS_VDP_EI:
; Enable VDP Interrupt.
; NOTE: this is independent of the value (bit 5) in VDP Register 1. What this
;       does is that the NMI subroutine reads the VDP Status Register again in
;       each run, and therefore it does allow more interrupts to happen.
        ld      A, 1
        ld      (NMI_enable), A
        call    F_BIOS_VDP_READ_STATREG ; Acknowledge interrupt to allow more interrupts coming
        ret
;------------------------------------------------------------------------------
BIOS_VDP_DI:
; Disable VDP Interrupt
; NOTE: this is independent of the value (bit 5) in VDP Register 1. What this
;       does is that the NMI subroutine doesn't read the VDP Status Register
;       anymore, and therefore doesn't allow more interrupts to happen.
        xor     A
        ld      (NMI_enable), A
        ret
;------------------------------------------------------------------------------
BIOS_VDP_READ_STATREG:
; Read the read-only Status Register
; If interrupts are enabled, the Status Register needs to be read frame-by-frame
;   in order to clear the interrupt and receive the new interrupt for the next
;   frame.
; OUT => A = Status Register byte
;               bits 0-4 = 5th Sprite Number
;               bit 5    = Coincidence Flag
;               bit 6    = 5th Sprite Flag
;               bit 7    = Interrupt Flag
        ld      C, VDP_REG
        in      A, (C)
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
_clearvram:
        call    F_BIOS_VDP_BYTE_TO_VRAM
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
_testram_write:
        ld      A, D                    ; write same value as inner loop counter
        call    F_BIOS_VDP_BYTE_TO_VRAM
        inc     D
        jr      nz, _testram_write      ; inner loop
        djnz    _testram_write          ; outer loop

        ; Read and test values from VRAM
        ld      HL, $0000               ; HL = first address of VRAM
        call    F_BIOS_VDP_SET_ADDR_RD  ; Set first address. VDP will autoincrement
        ld      B, 64
        ld      HL, tmp_byte            ; Will use SYSVARS.tmp_byte
        ld      (HL), 0                 ;   as the comparator
_testram_read:
        call    F_BIOS_VDP_VRAM_TO_BYTE
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
; Initialises VDP registers 0 to 6 according with values from table
; IN <= IX = table with initialisation values
BIOS_VDP_INIT_REGS:
        xor     A                       ; initialise register counter
_ini_regs_loop:
        ld      B, (IX)
        call    BIOS_VDP_SET_REGISTER
        inc     IX
        inc     A
        cp      7                       ; did we initialise already 6 registers
        jr      nz, _ini_regs_loop      ; no, do more registers
        ret
;------------------------------------------------------------------------------
BIOS_VDP_INIT_TAB:
; Initialises an entire Table with a value
; IN <= A = value to initialise to
;       B = outer loop counter (how many times the inner loop will be repeated)
;       D = inner loop counter (how many bytes to copy in this loop)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        inc     D
        jr      nz, BIOS_VDP_INIT_TAB   ; inner loop
        djnz    BIOS_VDP_INIT_TAB       ; outer loop
        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_MODE_TXT:
; Set VDP to Text Mode
;   Pattern Table           = 2048 bytes, arranged as 256 6x8 patterns
;   Name Table              = 960 bytes
;   Colour Table            = No colour table
;   Sprite Patterns Table   = No sprites
;   Sprite Attributes Table = No sprites
; IN <= B = Sprite size (0=8×8, 1=16×16)
;       C = Sprite magnification (0=no magnification, 1=magnification)

        ; Change Register 1 value in table according to input parameters
        ld      A, (VDP_TXT_REG_1)      ; get value from table
        rlc     B                       ; move B to be bit 6
        or      B                       ; Register 1 bit 6 = B
        or      C                       ; Register 1 bit 7 = C
        ld      (VDP_TXT_REG_1), A      ; store value in table

        ; Initialise registers
        ld      IX, VDP_TXT_REG_TAB     ; register table of initialisation values
        call    BIOS_VDP_INIT_REGS

        ; Initialise the 2048 bytes of the Pattern Table, with all zeros
        ld      HL, VDP_TXT_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        xor     A                       ; write zeros
        ld      B, 8                    ; outer loop decrementing (2048 / 256 = 8 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        call    BIOS_VDP_INIT_TAB

        ; Initialise the 960 bytes of the Name Table, with all zeros
        ; ld      HL, VDP_TXT_NAME_TAB      ; Name table is next to the Pattern Table
        ; call    F_BIOS_VDP_SET_ADDR_WR    ;   so no need to reposition VRAM pointer
        xor     A                       ; write zeros
        ld      B, 3                    ; outer loop decrementing (960 / 256 = 3 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        call    BIOS_VDP_INIT_TAB
        xor     A                       ; write zeros
        ld      B, 0                    ; outer loop decrementing (0 times)
        ld      D, 192                  ; inner loop incrementing (960 mod 256 = 192 times)
        call    BIOS_VDP_INIT_TAB

        ; Set Text and Background colours
        ld      A, 7
        ld      B, VDP_TXT_REG_7
        call    BIOS_VDP_SET_REGISTER

        ; Set SYSVARS
        ld      A, VDP_MODE_TXT
        ld      (VDP_cur_mode), A
        ld      HL, VDP_TXT_PATT_TAB
        ld      (VDP_PTRNTAB_addr), HL
        ld      HL, VDP_TXT_NAME_TAB
        ld      (VDP_NAMETAB_addr), HL
        ld      HL, $0000
        ld      (VDP_COLRTAB_addr), HL  ; No Colour Table for Text Mode
        ld      (VDP_SPRPTAB_addr), HL  ; No Sprites for Text Mode
        ld      (VDP_SPRATAB_addr), HL  ; No Sprites for Text Mode

        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_MODE_G1:
; Set VDP to Graphics I Mode
;   Pattern Table           = 2048 bytes, arranged as 256 8x8 patterns
;   Name Table              = 768 bytes
;   Colour Table            = 32 bytes
;   Sprite Patterns Table   = 2048 bytes
;   Sprite Attributes Table = 128 bytes
; IN <= B = Sprite size (0=8×8, 1=16×16)
;       C = Sprite magnification (0=no magnification, 1=magnification)

        ; Change Register 1 value in table according to input parameters
        ld      A, (VDP_G1_REG_1)       ; get value from table
        rlc     B                       ; move B to be bit 6
        or      B                       ; Register 1 bit 6 = B
        or      C                       ; Register 1 bit 7 = C
        ld      (VDP_G1_REG_1), A       ; store value in table

        ; Initialise registers
        ld      IX, VDP_G1_REG_TAB      ; register table of initialisation values
        call    BIOS_VDP_INIT_REGS

        ; Initialise the 2048 bytes of the Pattern Table, with all zeros
        ld      HL, VDP_G1_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 8                    ; outer loop decrementing (2048 / 256 = 8 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        xor     A                       ; write zeros
        call    BIOS_VDP_INIT_TAB

        ; Initialise the Color Table
        ld      HL, VDP_G1_COLR_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      A, VDP_G1_DEFT_TBC
        ld      B, 0                    ; Graphics I Mode Colour Table
        ld      D, 32                   ;   is just 32 bytes long
        call    BIOS_VDP_INIT_TAB

        ; Initialise the Name Table with Black Text on Light Blue
        ld      HL, VDP_G1_NAME_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ; ld      A, $05
        xor     A                       ; write zeros
        ld      B, 3                    ; outer loop decrementing (768 / 256 = 3 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        call    BIOS_VDP_INIT_TAB

        ; Set Backdrop colour
        ld      A, 7
        ld      B, VDP_G1_REG_7
        call    BIOS_VDP_SET_REGISTER

        ; Set SYSVARS
        ld      A, VDP_MODE_G1
        ld      (VDP_cur_mode), A
        ld      HL, VDP_G1_PATT_TAB
        ld      (VDP_PTRNTAB_addr), HL
        ld      HL, VDP_G1_NAME_TAB
        ld      (VDP_NAMETAB_addr), HL
        ld      HL, VDP_G1_COLR_TAB
        ld      (VDP_COLRTAB_addr), HL
        ld      HL, VDP_G1_SPRP_TAB
        ld      (VDP_SPRPTAB_addr), HL
        ld      HL, VDP_G1_SPRA_TAB
        ld      (VDP_SPRATAB_addr), HL

        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_MODE_G2:
; Set VDP to Graphics II Mode
;   Pattern Table           = 6144 bytes, arranged in three blocks of 2048 as 256 8x8 patterns each
;   Name Table              = 768 bytes
;   Colour Table            = 6144 bytes
;   Sprite Patterns Table   = 2048 bytes
;   Sprite Attributes Table = 256 bytes
; IN <= B = Sprite size (0=8×8, 1=16×16)
;       C = Sprite magnification (0=no magnification, 1=magnification)

        ; Change Register 1 value in table according to input parameters
        ld      A, (VDP_G2_REG_1)       ; get value from table
        rlc     B                       ; move B to be bit 6
        or      B                       ; Register 1 bit 6 = B
        or      C                       ; Register 1 bit 7 = C
        ld      (VDP_G2_REG_1), A       ; store value in table

        ; Initialise registers
        ld      IX, VDP_G2_REG_TAB      ; register table of initialisation values
        call    BIOS_VDP_INIT_REGS

        ; Initialise the 6144 bytes of the Pattern Table, with all zeros
        ld      HL, VDP_G2_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        xor     A                       ; write zeros
        ld      B, 24                   ; outer loop decrementing (6144 / 256 = 24 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        call    BIOS_VDP_INIT_TAB

        ; ; Initialise the 6144 bytes of the Colour Table
        ; ld      HL, VDP_G2_PATT_TAB
        ; call    F_BIOS_VDP_SET_ADDR_WR
        ; ld      B, 24                   ; outer loop decrementing (6144 / 256 = 24 times)
        ; ld      D, 0                    ; inner loop incrementing (256 times)
        ; ld      A, VDP_G2_REG_7
        ; call    BIOS_VDP_INIT_TAB

        ; ; Initialise the 6144 bytes of the Colour Table
        ld      HL, VDP_G2_COLR_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      A, VDP_G1_DEFT_TBC
        ld      B, 24                   ; outer loop decrementing (6144 / 256 = 24 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        call    BIOS_VDP_INIT_TAB

        ; Initialise the Name Table with zeros
        ; ld      HL, VDP_G2_NAME_TAB     ; Name table is next to the Colour Table
        ; call    F_BIOS_VDP_SET_ADDR_WR  ;   so no need to reposition VRAM pointer
        xor     A
        ld      B, 3                    ; outer loop decrementing (768 / 256 = 3 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        call    BIOS_VDP_INIT_TAB

        ; Set Backdrop colour
        ld      A, 7
        ld      B, VDP_G2_REG_7
        call    BIOS_VDP_SET_REGISTER

        ; Set SYSVARS
        ld      A, VDP_MODE_G2
        ld      (VDP_cur_mode), A
        ld      HL, VDP_G2_PATT_TAB
        ld      (VDP_PTRNTAB_addr), HL
        ld      HL, VDP_G2_NAME_TAB
        ld      (VDP_NAMETAB_addr), HL
        ld      HL, VDP_G2_COLR_TAB
        ld      (VDP_COLRTAB_addr), HL
        ld      HL, VDP_G2_SPRP_TAB
        ld      (VDP_SPRPTAB_addr), HL
        ld      HL, VDP_G2_SPRA_TAB
        ld      (VDP_SPRATAB_addr), HL

        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_MODE_G2BM:
; Set VDP to Graphics II Mode as Bit-mapped display
;   Initialise Pattern Table with all zeros
;   Set all colours the same
;   Write consecutive numbers for each entry in the Name Table
;       (i.e. 0x00-0xFF three times)
; IN <= B = Sprite size (0=8×8, 1=16×16)
;       C = Sprite magnification (0=no magnification, 1=magnification)

        ; Change Register 1 value in table according to input parameters
        ld      A, (VDP_G2_REG_1)       ; get value from table
        rlc     B                       ; move B to be bit 6
        or      B                       ; Register 1 bit 6 = B
        or      C                       ; Register 1 bit 7 = C
        ld      (VDP_G2_REG_1), A       ; store value in table

        ; Initialise registers
        ld      IX, VDP_G2_REG_TAB      ; register table of initialisation values
        call    BIOS_VDP_INIT_REGS

        ; Initialise the 6144 bytes of the Pattern Table, with all zeros
        ld      HL, VDP_G2_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 24                   ; outer loop decrementing (6144 / 256 = 24 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        xor     A                       ; write zeros
        call    BIOS_VDP_INIT_TAB

        ; Initialise the Color Table with White pixels over Black background
        ld      HL, VDP_G2_COLR_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 24                   ; outer loop decrementing (6144 / 256 = 24 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        ld      A, $F1                  ; White pixels over Black background
        call    BIOS_VDP_INIT_TAB

        ; Write consecutive numbers for each entry in the Name Table
        ; Write values to VRAM
        ld      HL, VDP_G2_NAME_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 3                    ; outer loop decrementing (3 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
_ini_name_tab:
        ld      A, D                    ; write same value as inner loop counter
        call    F_BIOS_VDP_BYTE_TO_VRAM
        inc     D
        jr      nz, _ini_name_tab       ; inner loop
        djnz    _ini_name_tab           ; outer loop

        ; Set SYSVARS
        ld      A, VDP_MODE_G2BM
        ld      (VDP_cur_mode), A
        ld      HL, VDP_G2_PATT_TAB
        ld      (VDP_PTRNTAB_addr), HL
        ld      HL, VDP_G2_NAME_TAB
        ld      (VDP_NAMETAB_addr), HL
        ld      HL, VDP_G2_COLR_TAB
        ld      (VDP_COLRTAB_addr), HL
        ld      HL, VDP_G2_SPRP_TAB
        ld      (VDP_SPRPTAB_addr), HL
        ld      HL, VDP_G2_SPRA_TAB
        ld      (VDP_SPRATAB_addr), HL

        ret
;------------------------------------------------------------------------------
BIOS_VDP_SET_MODE_MULTICLR:
; Set VDP to Multicolour Mode
;   Pattern Table           = 1536 bytes, arranged as 256 8x8 patterns
;   Name Table              = 768 bytes
;   Colour Table            = No colour table
;   Sprite Patterns Table   = 2048 bytes
;   Sprite Attributes Table = 128
; IN <= B = Sprite size (0=8×8, 1=16×16)
;       C = Sprite magnification (0=no magnification, 1=magnification)

        ; Change Register 1 value in table according to input parameters
        ld      A, (VDP_MM_REG_1)       ; get value from table
        rlc     B                       ; move B to be bit 6
        or      B                       ; Register 1 bit 6 = B
        or      C                       ; Register 1 bit 7 = C
        ld      (VDP_MM_REG_1), A       ; store value in table

        ; Initialise registers
        ld      IX, VDP_MM_REG_TAB      ; register table of initialisation values
        call    BIOS_VDP_INIT_REGS

        ; Initialise the 1536 bytes of the Pattern Table, with all zeros
        ld      HL, VDP_MM_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 6                    ; outer loop decrementing (1536 / 256 = 6 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        xor     A                       ; write zeros
        call    BIOS_VDP_INIT_TAB

        ; Initialise the 768 bytes of the Name Table, with all zeros
        ld      HL, VDP_MM_PATT_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      B, 3                    ; outer loop decrementing (768 / 256 = 3 times)
        ld      D, 0                    ; inner loop incrementing (256 times)
        xor     A                       ; write zeros
        call    BIOS_VDP_INIT_TAB

        ; Set Backdrop colour
        ld      A, 7
        ld      B, VDP_MM_REG_7
        call    BIOS_VDP_SET_REGISTER

        ; Set SYSVARS
        ld      A, VDP_MODE_MM
        ld      (VDP_cur_mode), A
        ld      HL, VDP_MM_PATT_TAB
        ld      (VDP_PTRNTAB_addr), HL
        ld      HL, VDP_MM_NAME_TAB
        ld      (VDP_NAMETAB_addr), HL
        ld      HL, $0000
        ld      (VDP_COLRTAB_addr), HL  ; No Colour Table for Multicolour Mode
        ld      HL, VDP_MM_SPRP_TAB
        ld      (VDP_SPRPTAB_addr), HL
        ld      HL, VDP_MM_SPRA_TAB
        ld      (VDP_SPRATAB_addr), HL
        ret
;------------------------------------------------------------------------------
BIOS_VDP_FNT_CHARSET:
; Copies the Default Font Charset from RAM to VRAM
; The ASCII table goes from 0x00 to 0x7F (128 bytes)
; Each character is made of 8 bytes
        ld      HL, (VDP_PTRNTAB_addr)  ; HL = Pattern Table address
        call    F_BIOS_VDP_SET_ADDR_WR
        call    F_BIOS_VDP_DI
        ;   From characters 0x0000 to 0x0020 (33*8=264 bytes) = Fill with 0x00
        ld      B, 0                  ; byte counter for 256
        xor     A
_fnt_fill_with_zeros1:
        call    F_BIOS_VDP_BYTE_TO_VRAM
        djnz    _fnt_fill_with_zeros1
        ;   Fill the remaining 264-256=8 bytes
        ld      B, 8
_fnt_fill_with_zeros2:
        call    F_BIOS_VDP_BYTE_TO_VRAM
        djnz    _fnt_fill_with_zeros2
        ;   From characters 0x0021 to 0x007E (94*8=752 bytes) = Fill with contents of BIOS.FNTcharset.asm
        ld      DE, VDP_FNT_CHARSET
        ld      B, 0                   ; byte counter for 256
_fnt_fill_with_data1: ; fill a pair of bytes in each step (256) of the loop
        ld      A, (DE)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        inc     DE
        ld      A, (DE)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        inc     DE
        djnz    _fnt_fill_with_data1
        ld      B, 240                  ; byte counter for 240 (752-512)
_fnt_fill_with_data2: ; fill the remaining 240 bytes
        ld      A, (DE)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        inc     DE
        djnz    _fnt_fill_with_data2
        ;   Fill character 0x007F with zeros (8 bytes)
        xor     A
        ld      B, 8
_fnt_fill_with_zeros3:
        call    F_BIOS_VDP_BYTE_TO_VRAM
        djnz    _fnt_fill_with_zeros3
;------------------------------------------------------------------------------
        call    F_BIOS_VDP_EI
        ret
;------------------------------------------------------------------------------
BIOS_VDP_BYTE_TO_VRAM:
; Writes a byte to VRAM
; IN <= A = byte to be written
; The VDP needs 2 microseconds to read or write a byte to its RAM
; With the three instructions, plus the time it takes to do the call to this
;   subroutine (call nn = 17 T States = 2.30 microsecs), we have a more than
;   enough delay (6.23 microsecs)
;   ld  r,n     =    7 T States     (7 / 7372800 Hz) * 1000000  = 0.95 microsecs
;   out (C), r  =   12 T States     (12 / 7372800 Hz) * 1000000 = 1.63 microsecs
;   ret         =   10 T States     (10 / 7372800 Hz) * 1000000 = 1.35 microsecs
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
        out     (C), A
        ret
;------------------------------------------------------------------------------
BIOS_VDP_VRAM_TO_BYTE:
; Read a byte from VRAM
; OUT => A = read byte
; The VDP needs 2 microseconds to read or write a byte to its RAM
; With the three instructions, plus the time it takes to do the call to this
;   subroutine (call nn = 17 T States = 2.30 microsecs), we have a more than
;   enough delay (6.24 microsecs)
;   ld  C, n    =   7 T States     (7 / 7372800 Hz) * 1000000  = 0.95 microsecs
;   in  A, (C)  =  12 T States     (12 / 7372800 Hz) * 1000000 = 1.63 microsecs
;   ret         =  10 T States     (10 / 7372800 Hz) * 1000000 = 1.35 microsecs
        ld      C, VDP_VRAM             ; MODE 0 (VRAM)
        in      A, (C)
        ret
;------------------------------------------------------------------------------
BIOS_VDP_JIFFY_COUNTER:
; A Jiffy is time the between two ticks of the system timer interrupt.
; On the dastaZ80, this timer is generated by the TMS9918A at roughly each
;   1/60th second.
; This counter is made of 3 bytes. Byte 1 is incremented in each VDP interrupt.
;   Once it rolls over (256 increments), the byte 2 is incremented. Once the
;   byte 2 rolls over, the byte 3 is incremented.
;   Once the three bytes together (24-bit) reach the value 0x4F1A00, the three
;   bytes are initialised to 0.
; 0x4F1A00 (5,184,000) is the number of jiffies in 24 hours:
;   24h x 60 minutes in an hour x 60 seconds in a minute x 60 jiffies in a second
; Here we need speed, so we do all jumps with jp instead of jr
_jiffy_loop:
        ld      IX, VDP_jiffy_byte1
        inc     (IX)                    ; increment byte 1
        ld      A, (IX)                 ; if it didn't
        cp      0                       ;   roll over
        jp      nz, _nomoreinc          ;   do not touch the other bytes
        inc     (IX + 1)                ; increment byte 2
        ld      A, (IX + 1)             ; if it didn't
        cp      0                       ;   roll over
        jp      nz, _nomoreinc          ;   do not touch the other byte
        inc     (IX + 2)                ; increment byte 3
_nomoreinc:
        ; Check if we reached the end of the 24h counter (0x4F1A00)
        scf
        ld      A, (IX + 1)
        sbc     A, $1A
        ld      A, (IX + 2)
        sbc     A, $4F
        jp      nc, _reset_jiffies      ; 24h reached, reset bytes to zero
        jp      _jiffy_end              ; not reached
_reset_jiffies:
        ld      (IX), 0
        ld      (IX + 1), 0
        ld      (IX + 2), 0
_jiffy_end:
        ret
;------------------------------------------------------------------------------
BIOS_VDP_VBLANK_WAIT:
; Test Status Register for Interrupt Flag ($80) and loop here until flag is raised
; 21 Sep 2023 - After some tests, and confirmed with some information found on
;               the Internet: reading continuously the Status Register can lead
;               to miss the flag. This happens when the register is read and the
;               VDP is about to set it, because as specified in the VDP manual
;               "the Status Register is reset after it's read"
;               Therefore I change this code:
        ; call    F_BIOS_VDP_READ_STATREG
        ; and     $80
        ; jr      z, BIOS_VDP_VBLANK_WAIT
;               For this one:
        ld      A, (VDP_jiffy_byte1)        ; get current jiffy
        ld      B, A                        ; store it in B
_wait_for_jiffy_change:
        ld      A, (VDP_jiffy_byte1)        ; get current jiffy
        cp      B                           ; if it's same as the one we stored
        jr      z, _wait_for_jiffy_change   ;   before, loop until changes
        ret
;------------------------------------------------------------------------------
BIOS_VDP_LDIR_VRAM:
; Block transfer from RAM to VRAM
; IN <= BC = Block length (total number of bytes to copy)
;       DE = Start address of RAM
;       HL = Start address of VRAM
        push    DE                      ; Backup Start address of RAM
        push    HL                      ; Backup Start address of VRAM
        ld      DE, 256
        call    F_KRN_DIV1616           ; BC = BC / DE, HL = remainder
                                        ; As VRAM is 16KB (16384 bytes),
                                        ;   max. will have is 16384/256 = 64
                                        ; Meaning, B will be 0 and C will have
                                        ;   the result. And remainder max. is 255

        ld      (tmp_byte), HL          ; backup remainder

        ld      A, C                    ; If the division resulted in 0, then
        cp      0                       ;   will do only one pass of the outer
        jr      nz, _ldir_256ormore     ;   loop. And inner loop = remainder
        ld      B, L                    ; inner loop = remainder
        pop     HL                      ; Restore Start address of VRAM
        pop     DE                      ; Restore Start address of RAM
        jr      _ldir_remainder

_ldir_256ormore
        ld      A, C                    ; Otherwise, transfer result to B
        ld      B, A                    ; B is the outer loop
        ld      C, 0                    ; C is the inner loop
        pop     HL                      ; Restore Start address of VRAM
        call    F_BIOS_VDP_SET_ADDR_WR  ; Set start of VRAM to HL
        pop     DE                      ; Restore Start address of RAM

_ldir_loop:
        ld      A, (DE)                 ; Read byte from RAM
        call    F_BIOS_VDP_BYTE_TO_VRAM ;   and copy it to VRAM
        inc     DE                      ; next byte in RAM
        inc     C                       ; increment inner loop counter
        jr      nz, _ldir_loop          ; if inner loop didn't reach 0, repeat
        djnz    _ldir_loop              ; if outer loop didn't reach 0, repeat

        ; Do remainder
        ld      A, (tmp_byte)
        add     A, 1
        ld      B, A                    ; loop = remainder + 1
_ldir_remainder:
        ld      A, (DE)                 ; Read byte from RAM
        call    F_BIOS_VDP_BYTE_TO_VRAM ;   and copy it to VRAM
        inc     DE                      ; next byte in RAM
        djnz    _ldir_remainder

        ret
;------------------------------------------------------------------------------
BIOS_VDP_CHAROUT_ATXY:
; Print a character in the current VDP_cursor_X, VDP_cursor_Y postition
; IN <= A = Character to be printed in Hexadecimal ASCII
        push    AF                      ; backup character to be printed
        ld      HL, (VDP_NAMETAB_addr)  ; HL = address of Name Table
        ld      B, H
        ld      C, L                    ; BC = address of Name Table (NAMTAB)
        push    BC

        ; VRAM cell to be modified: NAMTAB + (width * Y) + X
        ld      A, (VDP_cursor_y)
        add     A, A                    ; addresses in lookup table are 16-bit
        push    AF                      ; multiply by pre-calculated lookup table
        call    _mult_by_y              ;   IX = lookup table for 32 or 40 width
        pop     AF                      ; restore A+A
        ld      D, 0
        ld      E, A                    ; DE = A+A
        add     IX, DE                  ; IX = pre-calculated multiplication + A+A
        ld      L, (IX)
        ld      H, (IX+1)               ; HL = 32 * Y
        pop     BC                      ; BC = address of Name Table (NAMTAB)
        add     HL, BC                  ; HL = NAMTAB + (32 * Y)
        ld      B, 0
        ld      A, (VDP_cursor_x)
        ld      C, A                    ; BC = X
        add     HL, BC                  ; HL = NAMTAB  + (32 * Y) + X

        ; Output char, but before check for special characters
        call    F_BIOS_VDP_SET_ADDR_WR
        pop     AF                      ; restore character to be printed
        ; ; Check for special characters CarriageReturn and Backspace
        ; cp      CR
        ; jr      z, _resetX
        ; cp      BSPACE                  ; ToDo - add support for Backspace
        ; cp      TAB                     ; ToDo - add support for TAB
        ; cp      DELETE                  ; ToDo - add support for Delete

        ; Output char
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ret

_mult_by_y:
        ld      A, (VDP_cur_mode)
        cp      0
        jp      z, _mult_by_y_by40
_mult_by_y_by32:
        ld      IX, VDP_MULT_32Y
        ret
_mult_by_y_by40:
        ld      IX, VDP_MULT_40Y
        ret