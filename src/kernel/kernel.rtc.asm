;******************************************************************************
; kernel.rtc.asm
;
; Kernel's RTC routines
; for dastaZ80's dzOS
; by David Asta (Aug 2022)
;
; Version 2.0.0
; Created on 12 Aug 2022
; Last Modification 12 Aug 2022
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

;-----------------------------------------------------------------------------
KRN_RTC_SHOW_TIME:
; Display on Serial Channel A the values of hour, minutes and seconds from SYSVARS
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
; Display on Serial Channel A the values of day, month and year from SYSVARS
        call    F_BIOS_RTC_GET_DATE     ; SYSVARS = day, month, year in hex
        ld      A, (RTC_day)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        
        ld      A, (RTC_month)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A

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
        ret