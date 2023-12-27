;******************************************************************************
; Name:         kernel.rtc.asm
; Description:  Kernel's RTC routines
; Author:       David Asta
; License:      The MIT License
; Created:      12 Aug 2022
; Version:      1.1.0
; Last Modif.:  27 Dec 2023
;******************************************************************************
; CHANGELOG
;   - 27 Dec 2023 - Added KRN_INIT_RTC
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

KRN_INIT_RTC:
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Detect RTC
        ld      HL, msg_rtc_detect
        ld      A, (col_kernel_notice)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_left_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ; Show battery status
        call    F_BIOS_RTC_CHECK_BATTERY    ; Z flag set if battery not healthy
        jp      z, battery_failed
battery_healthy:
        ld      HL, msg_rtc_batok
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ; Initialise RTC
        call    F_BIOS_RTC_INIT
rtc_show_datetime:
        ; Show current Date
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_KRN_RTC_GET_DATE
        call    F_KRN_RTC_SHOW_DATE
        ; Separate Date and Time
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, '-'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ; Show current Time
        call    F_BIOS_RTC_GET_TIME
        call    F_KRN_RTC_SHOW_TIME
        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret

battery_failed:
        ld      HL, error_2001
        ld      A, (col_kernel_error)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret
;-----------------------------------------------------------------------------
KRN_RTC_GET_DATE:
; Call BIOS function to get date from the RTC, and then calculate
; the year in four digits
        call    F_BIOS_RTC_GET_DATE

        ld      A, (RTC_century)
        ld      DE, 100
        call    F_KRN_MULTIPLY816_SLOW  ; century * 100
        ld      A, (RTC_year)
        ld      D, 0
        ld      E, a
        xor     A
        adc     HL, DE                  ; add year to (century * 100)
        ld      (RTC_year4), HL
        ret

;-----------------------------------------------------------------------------
KRN_RTC_SHOW_TIME:
; Display on Serial Channel A the values of hour, minutes and seconds from SYSVARS
; as hh:mm:ss
        ld      A, (RTC_hour)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A

        ld      A, (RTC_minutes)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A

        ld      A, (RTC_seconds)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ret

;-----------------------------------------------------------------------------
KRN_RTC_SHOW_DATE:
; Display on Serial Channel A the values of day, month, year (4 digits) and 
; day of the week (3 letters) from SYSVARS

        ; Day
        ld      A, (RTC_day)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ; Separator
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ; Month
        ld      A, (RTC_month)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ; Separator
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ; Year 4 digits
        ld      HL, (RTC_year4)
        call    F_KRN_BIN_TO_BCD6
        ld      C, 0
        ex      DE, HL
        ld      DE, tmp_addr1
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 2)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 3)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ; Separator
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ; Day Of the Week
        ld      A, (RTC_day_of_the_week)
        cp      2
        jp      z, is_monday
        cp      3
        jp      z, is_tuesday
        cp      4
        jp      z, is_wednesday
        cp      5
        jp      z, is_thursday
        cp      6
        jp      z, is_friday
        cp      7
        jp      z, is_saturday
is_sunday:
        ld      HL, weekdays
        jp      output_dow
is_monday:
        ld      HL, weekdays + 4
        jp      output_dow
is_tuesday:
        ld      HL, weekdays + 8
        jp      output_dow
is_wednesday:
        ld      HL, weekdays + 12
        jp      output_dow
is_thursday:
        ld      HL, weekdays + 16
        jp      output_dow
is_friday:
        ld      HL, weekdays + 20
        jp      output_dow
is_saturday:
        ld      HL, weekdays + 24

output_dow:
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret

;-----------------------------------------------------------------------------
KRN_RTC_SET_TIME:
; Converts ASCII values to Hexadecimal, moves it into SYSVARS RTC_hour,
; RTC_minutes, RTC_seconds, and calls BIOS function to change time via ASMDC
; IN <= IX = address where the new time is stored in ASCII format
        ld      A, (IX)
        ld      H, A
        ld      A, (IX + 1)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_hour), A

        ld      A, (IX + 2)
        ld      H, A
        ld      A, (IX + 3)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_minutes), A

        ld      A, (IX + 4)
        ld      H, A
        ld      A, (IX + 5)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_seconds), A

        call    F_BIOS_RTC_SET_TIME
        ret

;-----------------------------------------------------------------------------
KRN_RTC_SET_DATE:
; Converts ASCII values to Hexadecimal, moves it into SYSVARS RTC_year, 
; RTC_month, RTC_day, RTC_day_of_the_week, and calls BIOS function to change
; date via ASMDC
; IN <= IX = address where the new date is stored in ASCII format
        ; year
        ld      A, (IX)                 ; get first character (year 1st digit)
        ld      H, A                    ; store it in H
        ld      A, (IX + 1)             ; get second character (year 2nd digit)
        ld      L, A                    ; store it in H
        call    F_KRN_ASCII_TO_HEX      ; convert HL to Hex, and put it in A
        call    F_KRN_BCD_TO_BIN        ; convert A to BCD
        ld      (RTC_year), A           ; store BCD in SYSVARS
        ; month
        ld      A, (IX + 2)
        ld      H, A
        ld      A, (IX + 3)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_month), A
        ; day
        ld      A, (IX + 4)
        ld      H, A
        ld      A, (IX + 5)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        call    F_KRN_BCD_TO_BIN
        ld      (RTC_day), A
        ; day of week
        ld      A, (IX + 6)
        sub     $30                     ; convert from ASCII to hex by just
                                        ; subtracting $30, as the possible values
                                        ; are from $30 to $36
        ld      (RTC_day_of_the_week), A
        ; send to RTC
        call    F_BIOS_RTC_SET_DATE
        ret

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
weekdays:
        .BYTE "Sun", 0
        .BYTE "Mon", 0
        .BYTE "Tue", 0
        .BYTE "Wed", 0
        .BYTE "Thu", 0
        .BYTE "Fri", 0
        .BYTE "Sat", 0
