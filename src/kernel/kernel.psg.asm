;******************************************************************************
; Name:         kernel.psg.asm
; Description:  Kernel's PSG routines
; Author:       David Asta
; License:      The MIT License
; Created:      27 Dec 2023
; Version:      1.0.0
; Last Modif.:  27 Dec 2023
;******************************************************************************
; CHANGELOG
;   - 
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

KRN_INIT_PSG:
; Detect PSG
        ld      HL, msg_psg_detect
        ld      A, (col_kernel_notice)
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_BIOS_PSG_INIT         ; Initialise PSG chip
        call    F_BIOS_PSG_BEEP         ; Make a beep sound
        ld      HL, msg_left_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_OK
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret
;------------------------------------------------------------------------------