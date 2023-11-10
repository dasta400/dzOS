;******************************************************************************
; BIOS.RTC.asm
;
; Real-Time Clock (RTC)
; for dastaZ80's dzOS
; by David Asta (Nov 2022)
;
; Version 1.0.0
; Created on 02 Nov 2022
; Last Modification 02 Nov 2022
;******************************************************************************
; CHANGELOG
;   -
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

BIOS_RTC_GET_TIME:
; Gets the current time from the ASMDC,
; and stores hour, minutes and seconds as hexadecimal values in SYSVARS
; IN <= none
; OUT => time is stored in SYSVARS

        ; Send command to ASMDC
        ld      A, RTC_CMD_GET_TIME     ; ASMDC command: Get current Time in Hex
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive time from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_hour), A
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_minutes), A
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_seconds), A
        ret
;------------------------------------------------------------------------------
BIOS_RTC_GET_DATE:
; Returns the current date from the RTC circuit,
; and stores day, month, year and day of the week as hexadecimal values in SYSVARS
; IN <= none
; OUT => date is stored in SYSVARS

        ld      HL, 0
        ld      (RTC_year4), HL         ; year4 is set to 0
        ; Send command to ASMDC
        ld      A, RTC_CMD_GET_DATE     ; ASMDC command: Get current Date in Hex
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_century), A
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_year), A
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_month), A
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_day), A
        call    F_BIOS_SERIAL_CONIN_B
        ld      (RTC_day_of_the_week), A
        ret
;------------------------------------------------------------------------------
BIOS_RTC_SET_TIME:
; IN <= time variables (hours, minutes, seconds) from SYSVARS
        ; Send command to ASMDC
        ld      A, RTC_CMD_SET_TIME     ; ASMDC command: Set Date in Hex
        call    F_BIOS_SERIAL_CONOUT_B
        ; Send time (HHMMSS) to ASMDC
        ld      A, (RTC_hour)
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (RTC_minutes)
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (RTC_seconds)
        call    F_BIOS_SERIAL_CONOUT_B
        ret
;------------------------------------------------------------------------------
BIOS_RTC_SET_DATE:
; IN <= date variables (year, month, dat, day of week) from SYSVARS
        ; Send command to ASMDC
        ld      A, RTC_CMD_SET_DATE     ; ASMDC command: Set Date in Hex
        call    F_BIOS_SERIAL_CONOUT_B
        ; Send date (YYMMDDW) to ASMDC
        ld      A, (RTC_year)
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (RTC_month)
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (RTC_day)
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (RTC_day_of_the_week)
        call    F_BIOS_SERIAL_CONOUT_B
        ret
;------------------------------------------------------------------------------
BIOS_RTC_CHECK_BATTERY:
; Checks if the battery is healthy or has to be replaced.
        ; Send command to ASMDC
        ld      A, RTC_CMD_GET_BATT
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ret
