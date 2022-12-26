;******************************************************************************
; BIOS.VDPlogo.asm
;
; BIOS' VDP (TMS9918A) Splash Screen Logo
; for dastaZ80's dzOS
; by David Asta (December 2022)
;
; Version 0.1.0
; Created on 20 Dec 2022
; Last Modification 20 Dec 2022
;******************************************************************************
; CHANGELOG
; , $-
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

        .ORG    VDP_LOGO_NAME_START
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $01, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $01, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $01, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $02, $01, $03, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $02, $01, $00, $08, $01, $01,
        .BYTE $07, $00, $08, $01, $01, $01, $07, $00,
        .BYTE $01, $01, $01, $00, $08, $01, $01, $07,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $08, $01, $01, $01, $00, $09, $05, $00,
        .BYTE $01, $00, $01, $03, $00, $04, $0A, $00,
        .BYTE $04, $01, $05, $00, $09, $05, $04, $01,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $01, $05, $04, $01, $00, $00, $00, $02,
        .BYTE $01, $00, $0A, $01, $07, $03, $00, $00,
        .BYTE $00, $01, $00, $00, $00, $00, $02, $01,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $01, $00, $00, $01, $00, $08, $01, $01,
        .BYTE $01, $00, $00, $04, $0A, $01, $07, $00,
        .BYTE $00, $01, $00, $00, $08, $01, $01, $01,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $01, $00, $00, $01, $00, $01, $05, $04,
        .BYTE $01, $00, $00, $00, $00, $04, $01, $00,
        .BYTE $00, $01, $00, $00, $01, $05, $04, $01,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $01, $03, $02, $01, $00, $01, $03, $02,
        .BYTE $01, $00, $07, $03, $00, $02, $01, $00,
        .BYTE $00, $01, $03, $00, $01, $03, $02, $01,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $0A, $01, $01, $09, $00, $0A, $01, $01,
        .BYTE $09, $00, $0A, $01, $01, $01, $09, $00,
        .BYTE $00, $0A, $09, $00, $0A, $01, $01, $09,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $00, $00, $00, $01, $01, $01, $01, $01,
        .BYTE $01, $01, $01, $00, $00, $02, $08, $01,
        .BYTE $01, $01, $07, $03, $00, $00, $00, $02,
        .BYTE $08, $01, $01, $07, $03, $00, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $02,
        .BYTE $01, $09, $05, $00, $02, $08, $09, $05,
        .BYTE $00, $04, $0A, $07, $03, $00, $02, $08,
        .BYTE $09, $05, $04, $0A, $07, $03, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $00, $08,
        .BYTE $01, $05, $00, $00, $08, $01, $05, $00,
        .BYTE $00, $00, $04, $01, $07, $00, $08, $01,
        .BYTE $05, $00, $00, $04, $01, $07, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $02, $01,
        .BYTE $09, $00, $00, $00, $0A, $01, $03, $00,
        .BYTE $00, $00, $02, $01, $09, $00, $01, $01,
        .BYTE $00, $00, $00, $00, $01, $01, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $00, $08, $01,
        .BYTE $05, $00, $00, $00, $04, $0A, $07, $03,
        .BYTE $00, $02, $08, $09, $05, $00, $01, $01,
        .BYTE $00, $00, $00, $00, $01, $01, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $02, $01, $09,
        .BYTE $00, $00, $00, $00, $00, $04, $01, $01,
        .BYTE $01, $01, $01, $05, $00, $00, $01, $01,
        .BYTE $00, $00, $00, $00, $01, $01, $00, $00,
        .BYTE $00, $00, $00, $00, $00, $08, $01, $05,
        .BYTE $00, $00, $00, $00, $00, $02, $01, $01,
        .BYTE $01, $01, $01, $03, $00, $00, $01, $01,
        .BYTE $00, $00, $00, $00, $01, $01, $00, $00,
        .BYTE $00, $00, $00, $00, $02, $01, $09, $00,
        .BYTE $00, $00, $00, $00, $02, $08, $09, $05,
        .BYTE $00, $04, $0A, $07, $03, $00, $01, $01,
        .BYTE $00, $00, $00, $00, $01, $01, $00, $00,
        .BYTE $00, $00, $00, $00, $08, $01, $05, $00,
        .BYTE $00, $00, $00, $00, $08, $01, $05, $00,
        .BYTE $00, $00, $04, $01, $07, $00, $01, $01,
        .BYTE $00, $00, $00, $00, $01, $01, $00, $00,
        .BYTE $00, $00, $00, $02, $01, $09, $00, $00,
        .BYTE $00, $00, $00, $00, $0A, $01, $03, $00,
        .BYTE $00, $00, $02, $01, $09, $00, $0A, $01,
        .BYTE $03, $00, $00, $02, $01, $09, $00, $00,
        .BYTE $00, $00, $00, $08, $09, $05, $00, $00,
        .BYTE $00, $00, $00, $00, $04, $0A, $07, $03,
        .BYTE $00, $02, $08, $09, $05, $00, $04, $0A,
        .BYTE $07, $03, $02, $08, $09, $05, $00, $00,
        .BYTE $00, $00, $00, $0A, $01, $01, $01, $01,
        .BYTE $01, $01, $01, $00, $00, $04, $0A, $01,
        .BYTE $01, $01, $09, $05, $00, $00, $00, $04,
        .BYTE $0A, $01, $01, $09, $05, $00, $00, $00

        .ORG VDP_LOGO_PATT_START
        .BYTE $00, $00, $00, $00, $00, $00, $00, $00,
        .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
        .BYTE $00, $00, $00, $00, $00, $01, $03, $07,
        .BYTE $00, $00, $00, $00, $00, $80, $C0, $E0,
        .BYTE $07, $03, $01, $00, $00, $00, $00, $00,
        .BYTE $E0, $C0, $80, $00, $00, $00, $00, $00,
        .BYTE $F0, $F0, $F0, $F0, $00, $00, $00, $00,
        .BYTE $F0, $F8, $FC, $FE, $FF, $FF, $FF, $FF,
        .BYTE $0F, $1F, $3F, $7F, $FF, $FF, $FF, $FF,
        .BYTE $FF, $FF, $FF, $FF, $FE, $FC, $F8, $F0,
        .BYTE $FF, $FF, $FF, $FF, $7F, $3F, $1F, $0F