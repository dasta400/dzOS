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

; ToDo - Calls to functions should be to RAM jumpblock addresses

;==============================================================================
; Includes
;==============================================================================
#include "src/equates.inc"
#include "exp/sysvars.exp"

        .ORG    $0000
;==============================================================================
; General Routines
;==============================================================================
;------------------------------------------------------------------------------
; Cold Boot
F_BIOS_CBOOT:
        di
        ld      SP, STACK_END           ; Set Stack address in RAM
        jp      F_BIOS_SERIAL_INIT      ; Initialise SIO/2
        call    F_BIOS_WIPE_RAM         ; wipe (with zeros) the entire RAM,
                                        ; except Stack area, SYSVARS and Buffers
        .ORG    INITSIO2_END + 1        ; To avoid overwritting RST08, RST10, RST18,
                                        ; RST20 and the SIO/2 Interrupt Vector at 60h
        call    F_BIOS_PIO_INIT         ; Initialise PIO
;------------------------------------------------------------------------------
; Warm Boot
F_BIOS_WBOOT:           .EXPORT         F_BIOS_WBOOT
        ld      A, $00                  ; Set SIO/2 Channel A as the default
        ld      (SIO_PRIMARY_IO), A     ; channel to be used (connected to Keyboard)

        jp      KRN_START               ; transfer control to Kernel

;------------------------------------------------------------------------------
; Halts the system
F_BIOS_SYSHALT:         .EXPORT         F_BIOS_SYSHALT
        di                              ; disable interrupts
        halt                            ; halt the computer

;==============================================================================
; RAM Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_WIPE_RAM:        ; TODO - is not working
; Sets zeros (00h) in all RAM addresses except Stack area, SYSVARS and Buffers
        ld      BC, FREERAM_TOTAL       ; total bytes
        inc     BC                      ;    to wipe + 1
        ld      HL, FREERAM_START       ; start address to wipe
        ld      A, 0                    ; 00h is the wipe value that will written
        ld      (HL), A                 ; wipe 1st address
        ld      DE, FREERAM_START + 1   ; point DE to next address to wipe
        ldir                            ; (DE)=(HL), HL=HL+1, until BC=0
        ret

;==============================================================================
; Messages
;==============================================================================
msg_bios_version:               .EXPORT         msg_bios_version
        .BYTE   CR, LF
        .BYTE   "BIOS v1.0.0", 0

;==============================================================================
; BIOS Modules
;==============================================================================
#include "src/BIOS/BIOS.cf.asm"
#include "src/BIOS/BIOS.rtc.asm"
#include "src/BIOS/BIOS.pio.asm"
#include "src/BIOS/BIOS.serial.asm"     ; this include MUST be always the last

;==============================================================================
; END of CODE
;==============================================================================
        .ORG    BIOS_END
        .BYTE 0
        .END