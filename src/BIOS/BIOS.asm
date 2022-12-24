;******************************************************************************
; BIOS.asm
;
; BIOS (Basic Input/Output System)
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 22 Jun 2022
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

#include "src/equates.inc"

        .ORG    $0000
;------------------------------------------------------------------------------
; Cold Boot
BIOS_CBOOT:
        di
        jp      BOOTSTRAP_START         ; Copy ROM to RAM and disable ROM chip
        .FILL   4, 0                    ; Empty space

        .ORG    $0066
;------------------------------------------------------------------------------
;Non-Maskable Interrupt (NMI) Vector
BIOS_NMI:
        ; Backup all registers
;         push    AF
;         push    BC
;         push    DE
;         push    HL
;         push    IX
;         push    IY

;         ld      A, (BIOS_NMI_FLAG)      ; If the flag
;         cp      0                       ;   is 0,
;         jp      z, BIOS_NMI_END         ;   do nothing and end the interrupt
;         ; If the flag is 1, jump to the specified address
; BIOS_NMI_JP:                    .EXPORT         BIOS_NMI_JP
;         jp      F_BIOS_NMI_END          ; Just reserve space for a JUMP
;                                         ; Programs that want to use the NMI
;                                         ;   should change this jump to their
;                                         ;   subroutine address, and set the 
;                                         ;   _nmi_flag byte to 1
BIOS_NMI_END:
;         ; Restore all registers
;         pop    AF
;         pop    BC
;         pop    DE
;         pop    HL
;         pop    IX
;         pop    IY
        retn
BIOS_NMI_FLAG:                  .EXPORT         BIOS_NMI_FLAG
; This flag enables (1) or disables (0) the second jump above that should
;   be set up by programs
        .BYTE   0

;------------------------------------------------------------------------------
        .ORG    INITSIO2_END + 1        ; To avoid overwritting RST08, RST10, RST18,
                                        ; RST20 and the SIO/2 Interrupt Vector
;------------------------------------------------------------------------------
; Warm Boot
BIOS_WBOOT:
        ; ; Set NMI jp to default. In case it was modified by a program
        ; ld      IX, BIOS_NMI
        ; ld      HL, _nmi_end
        ; ld      (IX + 1), L
        ; ld      (IX + 2), H
        ; transfer control to Kernel
        jp      KRN_START

;------------------------------------------------------------------------------
; Halts the system
BIOS_SYSHALT:
        di                              ; disable interrupts
        halt                            ; halt the computer

;==============================================================================
; Messages
;==============================================================================
msg_bios_version:               .EXPORT         msg_bios_version
        .BYTE   CR, LF
        .BYTE   "BIOS v0.1.0", 0
