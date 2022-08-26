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
BIOS_RTC_GET_TIME:
; Gets the current time from the RTC circuit,
; and stores hour, minutes and seconds as hexadecimal values in SYSVARS
; IN <= none
; OUT => time is stored in SYSVARS
; ToDo - BIOS_RTC_GET_TIME
        ld      A, 16
        ld      (RTC_hour), A
        ld      A, 24
        ld      (RTC_minutes), A
        ld      A, 45
        ld      (RTC_seconds), A
        ret
;------------------------------------------------------------------------------
BIOS_RTC_GET_DATE:
; Returns the current date from the RTC circuit,
; and stores day, month, year and day of the week as hexadecimal values in SYSVARS
; IN <= none
; OUT => date is stored in SYSVARS
; ToDo - BIOS_RTC_GET_DATE
        ld      A, 20
        ld      (RTC_century), A
        ld      A, 22
        ld      (RTC_year), A
        ld      HL, 2022
        ld      (RTC_year4), HL
        ld      A, 08
        ld      (RTC_month), A
        ld      A, 12
        ld      (RTC_day), A
        ld      A, 4
        ld      (RTC_day_of_the_week), A
        ret
;------------------------------------------------------------------------------
BIOS_RTC_SET_TIME:
; ToDo - BIOS_RTC_SET_TIME
        ret
;------------------------------------------------------------------------------
BIOS_RTC_SET_DATE:
; ToDo - BIOS_RTC_SET_DATE
        ret
;------------------------------------------------------------------------------
BIOS_RTC_CHECK_BATTERY:
; Checks if the battery is healthy or has to be replaced.
; The  Ricoh RP-5C01 hasn't, like more modern RTC chips, a way of telling
;   the status of the battery. Therefore I use the same trick that the MSX
;   computers do: Store a value at register $00 of RAM BLOCK 10
; Store $0C in bits 3 and 2 of register $00 of RAM BLOCK 10
; If the battery failed, reading this value will return a $00
        
; ToDo - BIOS_RTC_CHECK_BATTERY
        ; ld      A, (NVRAM_battery_status)   ; The value is stored in SYSVARS
        ld      A, $0C  ; ToDo - delete after tests
        ret
;------------------------------------------------------------------------------
BIOS_RTC_BATTERY_RPLCED:
; Tells the OS that the battery was replaced
; The OS will write $0A in the high nibble of register $00 of RAM BLOCK 10
; ToDo - BIOS_RTC_BATTERY_RPLCED
        ret