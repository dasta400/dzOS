;******************************************************************************
; BIOS_jblks.asm
;
; BIOS Jumpblocks
; for dastaZ80's dzOS
; by David Asta (Apr 2019)
;
; Version 1.0.0
; Created on 25 Apr 2019
; Last Modification 21 Jun 2022
;******************************************************************************
; CHANGELOG
;   -
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2019-2022 David Asta
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

        .ORG    BIOS_JBLK_START

F_BIOS_WBOOT:                   .EXPORT         F_BIOS_WBOOT
        jp      BIOS_WBOOT
F_BIOS_SYSHALT:                 .EXPORT         F_BIOS_SYSHALT
        jp      BIOS_SYSHALT

        ; Serial subroutines
F_BIOS_SERIAL_CONIN_A:          .EXPORT         F_BIOS_SERIAL_CONIN_A
        jp      BIOS_SERIAL_CONIN_A
F_BIOS_SERIAL_CONIN_B:          .EXPORT         F_BIOS_SERIAL_CONIN_B
        jp      BIOS_SERIAL_CONIN_B
F_BIOS_SERIAL_CONOUT_A:         .EXPORT         F_BIOS_SERIAL_CONOUT_A
        jp      BIOS_SERIAL_CONOUT_A
F_BIOS_SERIAL_CONOUT_B:         .EXPORT         F_BIOS_SERIAL_CONOUT_B
        jp      BIOS_SERIAL_CONOUT_B
F_BIOS_SERIAL_INIT              .EXPORT         F_BIOS_SERIAL_INIT
        jp      BIOS_SERIAL_INIT

        ; SD Card subroutines
F_BIOS_SD_GET_STATUS:           .EXPORT         F_BIOS_SD_GET_STATUS
        jp      BIOS_SD_GET_STATUS
F_BIOS_SD_BUSY_WAIT             .EXPORT         F_BIOS_SD_BUSY_WAIT
        jp      BIOS_SD_BUSY_WAIT
F_BIOS_SD_READ_SEC              .EXPORT         F_BIOS_SD_READ_SEC
        jp      BIOS_SD_READ_SEC
F_BIOS_SD_WRITE_SEC             .EXPORT         F_BIOS_SD_WRITE_SEC
        jp      BIOS_SD_WRITE_SEC
F_BIOS_SD_PARK_DISKS            .EXPORT         F_BIOS_SD_PARK_DISKS
        jp      BIOS_SD_PARK_DISKS
F_BIOS_SD_MOUNT_DISKS           .EXPORT         F_BIOS_SD_MOUNT_DISKS
        jp      BIOS_SD_MOUNT_DISKS

        ; Real-Time Clock subroutines
F_BIOS_RTC_GET_TIME:            .EXPORT         F_BIOS_RTC_GET_TIME
        jp      BIOS_RTC_GET_TIME
F_BIOS_RTC_GET_DATE:            .EXPORT         F_BIOS_RTC_GET_DATE
        jp      BIOS_RTC_GET_DATE
F_BIOS_RTC_SET_TIME:            .EXPORT         F_BIOS_RTC_SET_TIME
        jp      BIOS_RTC_SET_TIME
F_BIOS_RTC_SET_DATE:            .EXPORT         F_BIOS_RTC_SET_DATE
        jp      BIOS_RTC_SET_DATE
F_BIOS_RTC_CHECK_BATTERY        .EXPORT         F_BIOS_RTC_CHECK_BATTERY
        jp      BIOS_RTC_CHECK_BATTERY
F_BIOS_NVRAM_DETECT             .EXPORT         F_BIOS_NVRAM_DETECT
        jp      BIOS_NVRAM_DETECT

        .ORG    BIOS_JBLK_END
        .BYTE   0