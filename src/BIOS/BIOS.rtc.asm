;******************************************************************************
; BIOS.rtc.asm
;
; BIOS' Real-Time Clock routines
; for dastaZ80's dzOS
; by David Asta (Jun 2022)
;
; Version 1.0.0
; Created on 25 Jun 2022
; Last Modification 25 Jun 2022
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
; Real-Time Clock Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_RTC_GET_TIME:        .EXPORT     F_BIOS_RTC_GET_TIME
; Returns the current time from the RTC circuit, in HEX values
; IN <= none
; OUT => time is stored in SYSVARS
; TODO - F_BIOS_RTC_GET_TIME - get time from RTC chip
        ld      A, 19
        ld      (RTC_hour), A
        ld      A, 23
        ld      (RTC_minutes), A
        ld      A, 42
        ld      (RTC_seconds), A
        ret
;------------------------------------------------------------------------------
F_BIOS_RTC_GET_DATE:        .EXPORT     F_BIOS_RTC_GET_DATE
; Returns the current date from the RTC circuit, in HEX values
; IN <= none
; OUT => date is stored in SYSVARS
; TODO - F_BIOS_RTC_GET_DATE - get date from RTC chip
        ld      A, 20
        ld      (RTC_century), A
        ld      A, 22
        ld      (RTC_year), A
        ld      A, 11
        ld      (RTC_month), A
        ld      A, 09
        ld      (RTC_day), A
        ld      A, $01
        ld      (RTC_day_of_the_week), A
        ret
;------------------------------------------------------------------------------
F_BIOS_RTC_SET_TIME:        .EXPORT     F_BIOS_RTC_SET_TIME
; TODO - F_BIOS_RTC_SET_TIME
        ret
;------------------------------------------------------------------------------
F_BIOS_RTC_SET_DATE:        .EXPORT     F_BIOS_RTC_SET_DATE
; TODO - F_BIOS_RTC_SET_DATE
        ret