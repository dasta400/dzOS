;******************************************************************************
; BIOS.bootstrap.asm
;
; The contents of the ROM are transferred to the RAM, 
;   so that the ROM can be paged out and all is working from RAM
; for dastaZ80's dzOS
; by David Asta (Aug 2022)
;
; Version 1.0.0
; Created on 08 Aug 2022
; Last Modification 08 Aug 2022
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

;==============================================================================
; Includes
;==============================================================================
#include "src/equates.inc"
#include "exp/BIOS.exp"

;------------------------------------------------------------------------------
        .ORG    BOOSTRAP_START

        ; Copy the contents of the ROM to High RAM ($8000)
        ; We won't need the boostrap anymore, so we only copy from
        ;   start of the ROM ($0000) until CLI_END
        ld      BC, CLI_END             ; set byte counter to copy until CLI_END
        ld      HL, $0000               ; copy from $0000
        ld      DE, $8000               ; to start of High RAM
        ldir

        ; Disable (page out) ROM
        ld      A, 1
        out     (ROMRAM_PAGING), A

        ; Copy the copy of ROM in $8000 RAM to $0000 RAM
        ld      BC, CLI_END             ; set byte counter to copy until CLI_END
        ld      HL, $8000               ; copy from $8000
        ld      DE, $0000               ; to start of Low RAM
        ldir
        ; Continue with BIOS
        ld      SP, STACK_END           ; Set Stack address in RAM
        jp      F_BIOS_SERIAL_INIT      ; Initialise SIO/2

;==============================================================================
; END of CODE
;==============================================================================
        .ORG    BOOSTRAP_END
        .BYTE    0
        .END