;******************************************************************************
; Name:         helloworld.asm
; Description:  A test to see if 'load' and 'run' command work
; Author:       David Asta
; License:      The MIT License 
; Created:      21 Jun 2022
; Version:      1.0
; Last Modif.:  21 Jun 2022
; Length bytes: 38
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2022 David Asta
;
; Permission is hereby granted, free of charge, to any person obtaining a copy 
; of this software and associated documentation files (the "Software"), to deal 
; in the Software without restriction, including without limitation the rights 
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
; copies of the Software, and to permit persons to whom the Software is furnished 
; to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all 
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
; -----------------------------------------------------------------------------

#include "src/equates.inc"
#include "exp/BIOS.exp"

        .ORG    $4570                   ; start of code at address 0x2570
        jp      $4575                   ; first instruction must jump to the executable code
        .BYTE   $70, $45                ; load address (values must be same as .org above)
        
        .ORG    $4575                   ; start of program (must be same as jp above)
        ld      HL, hellow
mypgmloop:
        ld      A, (HL)
        cp      0
        jp      z, mypgmend	
        call    F_BIOS_SERIAL_CONOUT_A
        inc     HL
        jp      mypgmloop
mypgmend:
        jp      $100B                   ; return control to CLI
hellow:
    .BYTE       "Hello World", $0D, $0A, 0
        
        .END