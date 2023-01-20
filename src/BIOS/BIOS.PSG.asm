;******************************************************************************
; BIOS.PSG.asm
;
; BIOS' PSH (AY-3-8912) routines
; for dastaZ80's dzOS
; by David Asta (December 2022)
;
; Version 0.1.0
; Created on 27 Dec 2022
; Last Modification 27 Dec 2022
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
;

;==============================================================================
; DATA
;==============================================================================
;------------------------------------------------------------------------------
_PSG_REGS_INI:
; noise OFF, audio OFF, I/O Port as Output (1=off, 0=on)
; Initialisation value for Registers
              ; R0   R1   R2   R3   R4   R5   R6   R7
        .BYTE   $00, $00, $00, $00, $00, $00, $00, $FF
              ; R10  R11  R12  R13  R14  R15  R16  R17
        .BYTE   $00, $00, $00, $00, $00, $00, $00  ; AY-3-8912 does not have I/O Port B
;------------------------------------------------------------------------------
_PSG_BEEPON:
; 4010 Hz tone on Channel C
        .BYTE   $07, %10111110          ; R7 (Mixer) = Turn Tone Channel A only
        .BYTE   $00, $FF                ; R0 (Channel A 8-bit Fine Tune)
        .BYTE   $01, $01                ; R1 (Channel A 4-bit coarse Tune)
        .BYTE   $08, $0F                ; R8 = Set Channel A Volume to maximum
        .BYTE   $13, %00001010          ; R13 (Envelope)
_PSG_BEEPOFF:
        .BYTE   $08, $00                ; R8 = Set Channel A Volume to minimum
        .BYTE   $07, $FF                ; R7 (Mixer) = Turn off everything

;==============================================================================
; SUBROUTINES
;==============================================================================
;------------------------------------------------------------------------------
BIOS_PSG_SET_REGISTER:
; Set a value to a PSG Register
; IN <= A = register number
;       E = value to set
        ld      C, PSG_REG
        out     (C), A                  ; Select Register (number in A)

        ld      C, PSG_DATA
        out     (C), E                  ; Write value to selected register
        ret
;------------------------------------------------------------------------------
BIOS_PSG_READ_REGISTER:
; Read a PSG Register's value
; IN <= A = register number
; OUT => A = read value
        ld      C, PSG_REG
        out     (C), A                  ; Select Register (number in A)

        ld      C, PSG_DATA
        in      A, (C)                  ; Read from selected register
        ret
;------------------------------------------------------------------------------
BIOS_PSG_INIT:
; Initialises the PSG (noise OFF, audio OFF, I/O Port as Output)
        ld      B, $0F                  ; 15 Registers to initialise
        ld      HL, _PSG_REGS_INI       ; HL = pointer to 1st byte of the values array
        ld      D, 0                    ; Register counter
_psg_ini_loop:
        ld      A, D                    ; A = register number
        ld      E, (HL)                 ; E = value to set
        call    F_BIOS_PSG_SET_REGISTER
        inc     D                       ; next register
        inc     HL                      ; next value
        djnz    _psg_ini_loop
        ret
;------------------------------------------------------------------------------
BIOS_PSG_BEEP:
; Makes a beep-like sound
        ld      HL, _PSG_BEEPON
_psg_beepon:
        ld      B, $05                  ; 4 pairs (register num,, value) to send
_psg_beepon_loop:
        call    _psg_send_regpairs
        djnz    _psg_beepon_loop

        ld      HL, _PSG_BEEPOFF

        call    F_BIOS_VDP_VBLANK_WAIT  ; Wait a bit

_psg_beepoff:
        ld      B, $02                  ; 4 pairs (register num,, value) to send
_psg_beepoff_loop:
        call    _psg_send_regpairs
        djnz    _psg_beepoff_loop
        ret

_psg_send_regpairs:
        ld      A, (HL)                 ; A = register number
        inc     HL                      ; next value in the array
        ld      E, (HL)                 ; E = value to set
        call    F_BIOS_PSG_SET_REGISTER
        inc     HL                      ; next value in the array
        ret
