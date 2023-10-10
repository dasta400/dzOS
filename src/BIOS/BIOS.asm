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
        push    AF                      ; Backup AF                             ; 11 T cycles
        ld      A, (NMI_enable)         ; If the flag                           ; 13 T cycles
        cp      0                       ;   is 0, NMI is disabled               ; 7 T cycles
        jr      z, _NMI_is_disabled     ;   so don't do anything                ; 12 T cycles

        ; Backup all other registers
        push    BC                                                              ; 11 T cycles
        push    DE                                                              ; 11 T cycles
        push    HL                                                              ; 11 T cycles
        push    IX                                                              ; 15 T cycles
        push    IY                                                              ; 15 T cycles

        call    F_BIOS_VDP_JIFFY_COUNTER                                        ; 17  T cycles

        ld      A, (NMI_usr_jump)       ; If the flag                           ; 13 T cycles
        cp      0                       ;   is 0,                               ; 7 T cycles
        jr      z, BIOS_NMI_END         ;   do not jump                         ; 12 T cycles
        ; If the flag is 1, jump to the specified address
BIOS_NMI_JP:                    .EXPORT         BIOS_NMI_JP
        jp      F_BIOS_NMI_END          ; Just reserve space for a JUMP         ; 10 T cycles
                                        ; Programs that want to use the NMI
                                        ;   should change this jump to their
                                        ;   subroutine address, and set the 
                                        ;   _nmi_flag byte to 1
BIOS_NMI_END:
        ; Restore all registers
        pop     IY                                                              ; 14 T cycles
        pop     IX                                                              ; 14 T cycles
        pop     HL                                                              ; 10 T cycles
        pop     DE                                                              ; 10 T cycles

        call    F_BIOS_VDP_READ_STATREG ; Acknowledge interrupt to allow more   ; 17  T cycles
                                        ;   interrupts coming
        ; Restore the remaining registers
        pop     BC                                                              ; 10 T cycles
_NMI_is_disabled:
        pop     AF                                                              ; 10 T cycles
        retn                                                                    ; 14 T cycles
                                                                                ;-------------
                                                                                ; 264 T cycles
; As per Zilog Z80 User's Manual, 7 T States take 1.75 microseconds for a 4 MHz clock.
; Therefore the formula is: T States / Frequency in 1/s (i.e. 7 / 4000000 = 1.75)
; For a 7.3728 Mhz clock, 264 / 7372800 = 35.81 microseconds

;------------------------------------------------------------------------------
        .ORG    INITSIO2_END + 1        ; To avoid overwritting RST08, RST10, RST18,
                                        ; RST20 and the SIO/2 Interrupt Vector
;------------------------------------------------------------------------------
; Warm Boot
BIOS_WBOOT:
        ; Enable NMI (VDP) Interrupts
        ld      A, 1
        ld      (NMI_enable), A
        ; Disable usr configurable jump
        xor     A
        ld      (NMI_usr_jump), A
        ; Set NMI jp to default. In case it was modified by a program
        ld      IX, BIOS_NMI_JP
        ld      HL, BIOS_NMI_END
        ld      (IX + 1), L
        ld      (IX + 2), H
        ; transfer control to Kernel
        jp      KRN_START

;------------------------------------------------------------------------------
; Halts the system
BIOS_SYSHALT:
        ; disable Maskable Interrupts
        di
        ; disable Non-Maskable Interrupts
        call    F_BIOS_VDP_DI           
        ld      B, 0                    
        xor     A
        call    F_BIOS_VDP_SET_REGISTER
        ld      A, 1
        call    F_BIOS_VDP_SET_REGISTER
        ; halt the computer
        halt

;==============================================================================
; Messages
;==============================================================================
msg_bios_version:               .EXPORT         msg_bios_version
        .BYTE   CR, LF
        .BYTE   "BIOS v0.1.0", 0
