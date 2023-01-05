;******************************************************************************
; dzOS.asm
;
; dzOS main structure for assembly
; for dastaZ80's dzOS
; by David Asta (Dec 2022)
;
; Version 1.0.0
; Created on 23 Dec 2022
; Last Modification 23 Dec 2022
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

;-----------------------------------------------------------------------------
; System Variables (SYSVARS)
;-----------------------------------------------------------------------------
#include "exp/sysvars.exp"

;-----------------------------------------------------------------------------
; BIOS
;-----------------------------------------------------------------------------
#include "src/BIOS/BIOS.asm"            ; BIOS routines
#include "src/BIOS/BIOS.ASMDC.asm"      ; Arduino Serial Multi Device Controller
#include "src/BIOS/BIOS.VDP.asm"        ; TMS9918A VDP
#include "src/BIOS/BIOS.joys.asm"       ; Dual Digital Joystick Port
#include "src/BIOS/BIOS.jblks.asm"      ; BIO Jumpblocks
#include "src/BIOS/BIOS.serial.asm"     ; this include MUST be always the last of src/BIOS/

;-----------------------------------------------------------------------------
; Kernel
;-----------------------------------------------------------------------------
#include "src/kernel/kernel.asm"        ; Kernel routines
#include "src/kernel/kernel.jblks.asm"  ; Kernel Jumpblocks

;-----------------------------------------------------------------------------
; Command-Line Interface (CLI)
;-----------------------------------------------------------------------------
#include "src/CLI/CLI.asm"              ; CLI routines

;-----------------------------------------------------------------------------
; Bootstrap
;-----------------------------------------------------------------------------
#include "src/BIOS/BIOS.bootstrap.asm"

;-----------------------------------------------------------------------------
; dastaZ80 logo's Name and Pattern Table for VDP
;-----------------------------------------------------------------------------
#include "src/BIOS/BIOS.VDPlogo.asm"
