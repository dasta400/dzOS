;******************************************************************************
; BIOS.RTC.asm
;
; Real-Time Clock (RTC)
; for dastaZ80's dzOS
; by David Asta (Nov 2022)
;
; Version 1.0.0
; Created on 02 Nov 2022
; Last Modification 11 Nov 2023
;******************************************************************************
; CHANGELOG
;   - 11 Nov 2023 - Changed RTC to bq4845 chip
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

BIOS_RTC_INIT:
        ; set RTC as: 24 hours format, oscillator running
        ld      A, BQ4845_CTRL_24HOURS | BQ4845_CTRL_STOP
        out     (BQ4845_CTRL), A
        ; disable Interrupts
        xor     A
        out     (BQ4845_PRG_RATES), A
        out     (BQ4845_INTERRUPT), A
        ret

;------------------------------------------------------------------------------
BIOS_RTC_CHECK_BATTERY:
; The bq4845 checks the battery on power-up. When the battery voltage is
;   approximately 2.1V, the battery-valid flag BVF (bit 0) in the flags
;   register (0x0D) is set to a 0 indicating that clock and RAM data may be invalid.
; OUT => Z flag set if battery is unhealthy
        ; Send command to ASMDC
        in      A, (BQ4845_FLAGS)
        bit     0, A                    ; check Battery Valid Flag (BVF)
        ret
;------------------------------------------------------------------------------
BIOS_RTC_CLOCK_INHIBIT:
; To prevent reading data in transition, updates to the BQ4845 clock registers
;   should be halted, by setting the Update Transfer Inhibit (UTI) bit D3 of the
;   control register E. As long as the UTI bit is 1, updates to user-accessible
;   clock locations are inhibited
        in      A, (BQ4845_CTRL)        ; read current value of Control register
        or      BQ4845_CTRL_UTI         ; set the UTI bit
        out     (BQ4845_CTRL), A        ; update the Control register
        ret
; -----------------------------------------------------------------------------
BIOS_RTC_CLOCK_RELEASE:
; Set Update Transfer Inhibit (UTI) to 0
        in      A, (BQ4845_CTRL)        ; read current value of Control register
        xor     BQ4845_CTRL_UTI         ; unset the UTI bit
        out     (BQ4845_CTRL), A        ; update the Control register
        ret
; -----------------------------------------------------------------------------
BIOS_RTC_SET_TIME:
; gets the time values (hours, minutes, seconds) from SYSVARS
;   converts them from Hexadecimal to BCD and sends them to the bq4845 RTC
        call    BIOS_RTC_CLOCK_INHIBIT  ; stop the update of time on the outputs

        ld      A, (RTC_hour)           ; A = hours in Hexadecimal
        call    F_KRN_BIN_TO_BCD4       ; convert it to BCD
        ld      A, L                    ; we are only interested in the last digits
        out     (BQ4845_TIME_HOURS), A  ; send it to BQ4845

        ld      A, (RTC_minutes)        ; A = minutes in Hexadecimal
        call    F_KRN_BIN_TO_BCD4       ; convert it to BCD
        ld      A, L                    ; we are only interested in the last digits
        out     (BQ4845_TIME_MINS), A   ; send it to BQ4845

        ld      A, (RTC_seconds)        ; A = seconds in Hexadecimal
        call    F_KRN_BIN_TO_BCD4       ; convert it to BCD
        ld      A, L                    ; we are only interested in the last digits
        out     (BQ4845_TIME_SECS), A   ; send it to BQ4845
        
        call    BIOS_RTC_CLOCK_RELEASE  ; re-start the update on outputs
        ret
; -----------------------------------------------------------------------------
BIOS_RTC_GET_TIME:
; get the current time on the RTC, and store it in SYSVARS
; OUT => SYSVARS RTC_hour, RTC_minutes, RTC_seconds
        call    BIOS_RTC_CLOCK_INHIBIT  ; stop the update of time on the outputs

        ; get time from bq4845 in BCD
        in      A, (BQ4845_TIME_HOURS)  ; get hours
        ld      (RTC_hour), A
        in      A, (BQ4845_TIME_MINS)   ; get minutes
        ld      (RTC_minutes), A
        in      A, (BQ4845_TIME_SECS)   ; get seconds
        ld      (RTC_seconds), A

        call    BIOS_RTC_CLOCK_RELEASE  ; re-start the update on outputs

        ; convert hours to Hexadecimal
        ld      A, (RTC_hour)
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_hour), A
        ; convert minutes to Hexadecimal
        ld      A, (RTC_minutes)
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_minutes), A
        ; convert seconds to Hexadecimal
        ld      A, (RTC_seconds)
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_seconds), A

        ret
; -----------------------------------------------------------------------------
BIOS_RTC_SET_DATE:
; gets the date values (day, month, year, day of the week) from SYSVARS
;   converts them from Hexadecimal to BCD and sends them to the bq4845 RTC
        call    BIOS_RTC_CLOCK_INHIBIT  ; stop the update of time on the outputs

        ld      A, (RTC_year)           ; A = year (no century) in Hexadecimal
        call    F_KRN_BIN_TO_BCD4       ; convert it to BCD
        ld      A, L                    ; we are only interested in the last digits
        out     (BQ4845_DATE_YEAR), A

        ld      A, (RTC_month)          ; A = month in Hexadecimal
        call    F_KRN_BIN_TO_BCD4       ; convert it to BCD
        ld      A, L                    ; we are only interested in the last digits
        out     (BQ4845_DATE_MONTH), A

        ld      A, (RTC_day)            ; A = day in Hexadecimal
        call    F_KRN_BIN_TO_BCD4       ; convert it to BCD
        ld      A, L                    ; we are only interested in the last digits
        out     (BQ4845_DATE_DAY), A

        ld      A, (RTC_day_of_the_week)
        out     (BQ4845_DATE_DOW), A

        call    BIOS_RTC_CLOCK_RELEASE  ; re-start the update on outputs
        ret
; -----------------------------------------------------------------------------
BIOS_RTC_GET_DATE:
; get the current date on the RTC, and store it in SYSVARS
; OUT => SYSVARS RTC_day, RTC_month, RTC_year, RTC_day_of_the_week
        call    BIOS_RTC_CLOCK_INHIBIT  ; stop the update of time on the outputs

        in      A, (BQ4845_DATE_DAY)    ; get day
        ld      (RTC_day), A
        in      A, (BQ4845_DATE_MONTH)  ; get month
        ld      (RTC_month), A
        in      A, (BQ4845_DATE_YEAR)   ; get year
        ld      (RTC_year), A
        in      A, (BQ4845_DATE_DOW)    ; get day of the week
        ld      (RTC_day_of_the_week), A

        call    BIOS_RTC_CLOCK_RELEASE  ; re-start the update on outputs

        ; convert day to Hexadecimal
        ld      A, (RTC_day)
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_day), A
        ; convert month to Hexadecimal
        ld      A, (RTC_month)
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_month), A
        ; convert year to Hexadecimal
        ld      A, (RTC_year)
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_year), A
        ; hardcode century to 20
        ld      A, 20
        ld      (RTC_century), A

        ret
