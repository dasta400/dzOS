;******************************************************************************
; BIOS_jblks.asm
;
; BIOS Jumpblocks
; for dastaZ80's dzOS
; by David Asta (Apr 2019)
;
; Version 1.0.0
; Created on 25 Apr 2019
; Last Modification 11 Nov 2023
;******************************************************************************
; CHANGELOG
;   - 17 Aug 2023 - Removed F_BIOS_VDP_SHOW_DZ_LOGO
;                 - Added F_BIOS_VDP_FNT_CHARSET
;   - 11 Nov 2023 - Changed RTC jumps for bq4845 RTC
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2019-2023 David Asta
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
F_BIOS_NMI_END:                 .EXPORT         F_BIOS_NMI_END
        jp      BIOS_NMI_END

        ; Serial subroutines
F_BIOS_SERIAL_CONIN_A:          .EXPORT         F_BIOS_SERIAL_CONIN_A
        jp      BIOS_SERIAL_CONIN_A
F_BIOS_SERIAL_CONIN_B:          .EXPORT         F_BIOS_SERIAL_CONIN_B
        jp      BIOS_SERIAL_CONIN_B
F_BIOS_SERIAL_CONOUT_A:         .EXPORT         F_BIOS_SERIAL_CONOUT_A
        jp      BIOS_SERIAL_CONOUT_A
F_BIOS_SERIAL_CONOUT_B:         .EXPORT         F_BIOS_SERIAL_CONOUT_B
        jp      BIOS_SERIAL_CONOUT_B
F_BIOS_SERIAL_INIT:             .EXPORT         F_BIOS_SERIAL_INIT
        jp      BIOS_SERIAL_INIT
F_BIOS_SERIAL_CKINCHAR_A:       .EXPORT         F_BIOS_SERIAL_CKINCHAR_A
        jp      BIOS_SERIAL_CKINCHAR_A

        ; SD Card subroutines
F_BIOS_SD_GET_STATUS:           .EXPORT         F_BIOS_SD_GET_STATUS
        jp      BIOS_SD_GET_STATUS
F_BIOS_SD_BUSY_WAIT:            .EXPORT         F_BIOS_SD_BUSY_WAIT
        jp      BIOS_SD_BUSY_WAIT
F_BIOS_SD_PARK_DISKS:           .EXPORT         F_BIOS_SD_PARK_DISKS
        jp      BIOS_SD_PARK_DISKS
F_BIOS_SD_MOUNT_DISKS:          .EXPORT         F_BIOS_SD_MOUNT_DISKS
        jp      BIOS_SD_MOUNT_DISKS
F_BIOS_SD_GET_IMG_INFO:         .EXPORT         F_BIOS_SD_GET_IMG_INFO
        jp      BIOS_SD_GET_IMG_INFO

        ; FDD subroutines
F_BIOS_FDD_BUSY_WAIT:           .EXPORT         F_BIOS_FDD_BUSY_WAIT
        jp      BIOS_FDD_BUSY_WAIT
F_BIOS_FDD_CHANGE:              .EXPORT         F_BIOS_FDD_CHANGE
        jp      BIOS_FDD_CHANGE
F_BIOS_FDD_LOWLVL_FORMAT:       .EXPORT         F_BIOS_FDD_LOWLVL_FORMAT
        jp      BIOS_FDD_LOWLVL_FORMAT
F_BIOS_FDD_MOTOR_ON:            .EXPORT         F_BIOS_FDD_MOTOR_ON
        jp      BIOS_FDD_MOTOR_ON
F_BIOS_FDD_MOTOR_OFF:           .EXPORT         F_BIOS_FDD_MOTOR_OFF
        jp      BIOS_FDD_MOTOR_OFF
F_BIOS_FDD_CHECK_DISKIN:        .EXPORT         F_BIOS_FDD_CHECK_DISKIN
        jp      BIOS_FDD_CHECK_DISKIN
F_BIOS_FDD_CHECK_WPROTECT:      .EXPORT         F_BIOS_FDD_CHECK_WPROTECT
        jp      BIOS_FDD_CHECK_WPROTECT

        ; Disk (FDD & SD Card) subroutines
F_BIOS_DISK_READ_SEC:           .EXPORT         F_BIOS_DISK_READ_SEC
        jp      BIOS_DISK_READ_SEC
F_BIOS_DISK_WRITE_SEC:          .EXPORT         F_BIOS_DISK_WRITE_SEC
        jp      BIOS_DISK_WRITE_SEC

        ; Real-Time Clock subroutines
F_BIOS_RTC_INIT:                .EXPORT         F_BIOS_RTC_INIT
        jp      BIOS_RTC_INIT
F_BIOS_RTC_CHECK_BATTERY:       .EXPORT         F_BIOS_RTC_CHECK_BATTERY
        jp      BIOS_RTC_CHECK_BATTERY
F_BIOS_RTC_CLOCK_INHIBIT:       .EXPORT         F_BIOS_RTC_CLOCK_INHIBIT
        jp      BIOS_RTC_CLOCK_INHIBIT
F_BIOS_RTC_CLOCK_RELEASE:       .EXPORT         F_BIOS_RTC_CLOCK_RELEASE
        jp      BIOS_RTC_CLOCK_RELEASE
F_BIOS_RTC_SET_TIME:            .EXPORT         F_BIOS_RTC_SET_TIME
        jp      BIOS_RTC_SET_TIME
F_BIOS_RTC_GET_TIME:            .EXPORT         F_BIOS_RTC_GET_TIME
        jp      BIOS_RTC_GET_TIME
F_BIOS_RTC_SET_DATE:            .EXPORT         F_BIOS_RTC_SET_DATE
        jp      BIOS_RTC_SET_DATE
F_BIOS_RTC_GET_DATE:            .EXPORT         F_BIOS_RTC_GET_DATE
        jp      BIOS_RTC_GET_DATE

        ; TMS9918A VDP
F_BIOS_VDP_SET_ADDR_WR:         .EXPORT         F_BIOS_VDP_SET_ADDR_WR
        jp      BIOS_VDP_SET_ADDR_WR
F_BIOS_VDP_SET_ADDR_RD:         .EXPORT         F_BIOS_VDP_SET_ADDR_RD
        jp      BIOS_VDP_SET_ADDR_RD
F_BIOS_VDP_SET_REGISTER:        .EXPORT         F_BIOS_VDP_SET_REGISTER
        jp      BIOS_VDP_SET_REGISTER
F_BIOS_VDP_EI:                  .EXPORT         F_BIOS_VDP_EI
        jp      BIOS_VDP_EI
F_BIOS_VDP_DI:                  .EXPORT         F_BIOS_VDP_DI
        jp      BIOS_VDP_DI
F_BIOS_VDP_READ_STATREG:        .EXPORT         F_BIOS_VDP_READ_STATREG
        jp      BIOS_VDP_READ_STATREG
F_BIOS_VDP_VRAM_CLEAR:          .EXPORT         F_BIOS_VDP_VRAM_CLEAR
        jp      BIOS_VDP_VRAM_CLEAR
F_BIOS_VDP_VRAM_TEST:           .EXPORT         F_BIOS_VDP_VRAM_TEST
        jp      BIOS_VDP_VRAM_TEST
F_BIOS_VDP_SET_MODE_G1:         .EXPORT         F_BIOS_VDP_SET_MODE_G1
        jp      BIOS_VDP_SET_MODE_G1
F_BIOS_VDP_SET_MODE_G2:         .EXPORT         F_BIOS_VDP_SET_MODE_G2
        jp      BIOS_VDP_SET_MODE_G2
F_BIOS_VDP_SET_MODE_G2BM:       .EXPORT         F_BIOS_VDP_SET_MODE_G2BM
        jp      BIOS_VDP_SET_MODE_G2BM
F_BIOS_VDP_SET_MODE_MULTICLR:   .EXPORT         F_BIOS_VDP_SET_MODE_MULTICLR
        jp      BIOS_VDP_SET_MODE_MULTICLR
F_BIOS_VDP_SET_MODE_TXT:        .EXPORT         F_BIOS_VDP_SET_MODE_TXT
        jp      BIOS_VDP_SET_MODE_TXT
F_BIOS_VDP_FNT_CHARSET:         .EXPORT         F_BIOS_VDP_FNT_CHARSET
        jp      BIOS_VDP_FNT_CHARSET
F_BIOS_VDP_BYTE_TO_VRAM:        .EXPORT         F_BIOS_VDP_BYTE_TO_VRAM
        jp      BIOS_VDP_BYTE_TO_VRAM
F_BIOS_VDP_VRAM_TO_BYTE:        .EXPORT         F_BIOS_VDP_VRAM_TO_BYTE
        jp      BIOS_VDP_VRAM_TO_BYTE
F_BIOS_VDP_JIFFY_COUNTER:       .EXPORT         F_BIOS_VDP_JIFFY_COUNTER
        jp      BIOS_VDP_JIFFY_COUNTER
F_BIOS_VDP_VBLANK_WAIT:         .EXPORT         F_BIOS_VDP_VBLANK_WAIT
        jp      BIOS_VDP_VBLANK_WAIT
F_BIOS_VDP_LDIR_VRAM:           .EXPORT         F_BIOS_VDP_LDIR_VRAM
        jp      BIOS_VDP_LDIR_VRAM
F_BIOS_VDP_CHAROUT_ATXY:        .EXPORT         F_BIOS_VDP_CHAROUT_ATXY
        jp      BIOS_VDP_CHAROUT_ATXY

        ; AY-3-8912 PSG
F_BIOS_PSG_SET_REGISTER:        .EXPORT         F_BIOS_PSG_SET_REGISTER
        jp      BIOS_PSG_SET_REGISTER
F_BIOS_PSG_READ_REGISTER:       .EXPORT         F_BIOS_PSG_READ_REGISTER
        jp      BIOS_PSG_READ_REGISTER
F_BIOS_PSG_INIT:              .EXPORT           F_BIOS_PSG_INIT
        jp      BIOS_PSG_INIT
F_BIOS_PSG_BEEP:                .EXPORT         F_BIOS_PSG_BEEP
        jp      BIOS_PSG_BEEP
        
        ; Dual Digital Joystick Port
F_BIOS_JOYS_GET_STAT:           .EXPORT         F_BIOS_JOYS_GET_STAT
        jp      BIOS_JOYS_GET_STAT

        .ORG    BIOS_JBLK_END
