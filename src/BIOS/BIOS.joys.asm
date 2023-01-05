;******************************************************************************
; BIOS.joys.asm
;
; BIOS' Dual Digital Joystick Port routines
; for dastaZ80's dzOS
; by David Asta (December 2022)
;
; Version 0.1.0
; Created on 30 Dec 2022
; Last Modification 30 Dec 2022
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
; -----------------------------------------------------------------------------
BIOS_JOYS_GET_STAT:
; Get status of Joysticks
;   $00 = None
;   $01 = Up
;   $02 = Down
;   $04 = Left
;   $08 = Right
;   $10 = Fire
;   $1F = ????
; IN <=  A = Joystick to get (1=JOY1, 2=JOY2)
; OUT => A = pressed buttons
;            The value is the sum of any direction or fire
;            (e.g. Up and Left and Fire = $01 + $08 + $10 = $19)

        cp      1
        jp      z, _stat_joy1
_stat_joy2:
        ld      C, JOY2_STAT
        in      A, (C)
        cp      $1F
        ret     nz
        ld      A, JOY_NONE             ; If joy reports $1F, reset as None
        ret
_stat_joy1:
        ld      C, JOY1_STAT
        in      A, (C)
        cp      $1F
        ret     nz
        ld      A, JOY_NONE             ; If joy reports $1F, reset as None
        ret
