;******************************************************************************
; BIOS.NVRAM.asm
;
; Non-volatile RAM
; for dastaZ80's dzOS
; by David Asta (Nov 2022)
;
; Version 1.0.0
; Created on 02 Nov 2022
; Last Modification 10 Nov 2023
;******************************************************************************
; CHANGELOG
;   - 
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

BIOS_NVRAM_DETECT:
; OUT => A = $00 (Success) / $FF (Failure)
        ; Send command to ASMDC
        ld      A, NVRAM_CMD_DETECT
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ret
