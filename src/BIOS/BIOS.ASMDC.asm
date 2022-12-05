;******************************************************************************
; BIOS.ASMDC.asm
;
; Arduino Serial Multi-Device Controller
; for dastaZ80's dzOS
; by David Asta (Nov 2022)
;
; Version 1.0.0
; Created on 02 Nov 2022
; Last Modification 02 Nov 2022
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
;  ______           _      _____ _                  _____ _            _
;  | ___ \         | |    |_   _(_)                /  __ \ |          | |
;  | |_/ /___  __ _| |______| |  _ _ __ ___   ___  | /  \/ | ___   ___| | __
;  |    // _ \/ _` | |______| | | | '_ ` _ \ / _ \ | |   | |/ _ \ / __| |/ /
;  | |\ \  __/ (_| | |      | | | | | | | | |  __/ | \__/\ | (_) | (__|   <
;  \_| \_\___|\__,_|_|      \_/ |_|_| |_| |_|\___|  \____/_|\___/ \___|_|\_\
;==============================================================================
;------------------------------------------------------------------------------
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

;==============================================================================
;                    _   ___      _______            __  __ 
;                   | \ | \ \    / /  __ \     /\   |  \/  |
;                   |  \| |\ \  / /| |__) |   /  \  | \  / |
;                   | . ` | \ \/ / |  _  /   / /\ \ | |\/| |
;                   | |\  |  \  /  | | \ \  / ____ \| |  | |
;                   |_| \_|   \/   |_|  \_\/_/    \_\_|  |_|
;==============================================================================
;------------------------------------------------------------------------------
BIOS_NVRAM_DETECT:
; OUT => A = $00 (Success) / $FF (Failure)
        ; Send command to ASMDC
        ld      A, NVRAM_CMD_DETECT
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ret

;==============================================================================
;                ___________   _____               _
;               /  ___|  _  \ /  __ \             | |
;               \ `--.| | | | | /  \/ __ _ _ __ __| |
;                `--. \ | | | | |    / _` | '__/ _` |
;               /\__/ / |/ /  | \__/\ (_| | | | (_| |
;               \____/|___/    \____/\__,_|_|  \__,_|
;==============================================================================
;------------------------------------------------------------------------------
BIOS_SD_GET_STATUS:
; OUT => SYSVARS.DISK_status
;           Low Nibble (0x00 if all OK)
;               bit 0 = set if SD card was not found
;               bit 1 = set if image file was not found
;               bit 2 = set if last command resulted in error
;               bit 3 = not used
;           High Nibble (number of disk image files found)

        ; Send command to ASMDC
        call    F_BIOS_SD_BUSY_WAIT
        ld      A, SD_CMD_GET_STATUS
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ld      (DISK_status), A
        ret
;------------------------------------------------------------------------------
BIOS_SD_GET_IMG_INFO:
; IN <= IX = address where to store the image file information

        ; Send command to ASMDC
        ld      A, SD_CMD_GET_IMG_INFO
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (DISK_current)           ; Send current DISK
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive image file name
        ld      B, 12
_rcv_name_loop:
        call    F_BIOS_SERIAL_CONIN_B
        ld      (IX), A
        inc     IX
        djnz    _rcv_name_loop
        ; Add string terminator ($00)
        ld      A, 0
        ld      (IX), A
        inc     IX
        ; Receive image file capacity
        call    F_BIOS_SERIAL_CONIN_B
        ld      (IX), A
        inc     IX
        ret
;------------------------------------------------------------------------------
BIOS_SD_PARK_DISKS:
; Tells the ASMDC to close the Image file(s)

        ; If DISK_current is 0, ignore this command
        ld      A, (DISK_current)
        cp      0
        jp      z, _nopark
        ; Send command to ASMDC
        call    F_BIOS_SD_BUSY_WAIT
        ld      A, SD_CMD_PARK_DISKS
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (DISK_current)           ; Send current DISK
        call    F_BIOS_SERIAL_CONOUT_B
_nopark
        ret
;------------------------------------------------------------------------------
BIOS_SD_MOUNT_DISKS:
        ; If DISK_current is 0, ignore this command
        ld      A, (DISK_current)
        cp      0
        jp      z, _nomount
        ; Send command to ASMDC
        call    F_BIOS_SD_BUSY_WAIT
        ld      A, SD_CMD_MOUNT_DISK
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (DISK_current)           ; Send current DISK
        call    F_BIOS_SERIAL_CONOUT_B
_nomount
        ret
;------------------------------------------------------------------------------
BIOS_SD_BUSY_WAIT:
; Check SD Card busy flag (0x00=ready, 0x01=busy)
; Loop here until 0=ready
        ; Send command to ASMDC
        ld      A, SD_CMD_GET_BUSY
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        cp      0
        jp      nz, BIOS_SD_BUSY_WAIT
        ret

;==============================================================================
;                         _____ ____  ____
;                        |  ___|  _ \|  _ \
;                        | |_  | | | | | | |
;                        |  _| | | | | | | |
;                        | |   | |_| | |_| |
;                        |_|   |____/|____/
;==============================================================================
;------------------------------------------------------------------------------
BIOS_FDD_BUSY_WAIT:
; Check FDD busy flag (0x00=ready, 0x01=busy)
; Loop here until 0=ready
        ; Send command to ASMDC
        ld      A, FDD_CMD_GET_BUSY
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        cp      0
        jp      nz, BIOS_FDD_BUSY_WAIT
        ret
;------------------------------------------------------------------------------
BIOS_FDD_MOTOR_ON:
; Tells ASMDC to turn the FDD motor on
        ; Send command to ASMDC
        ld      A, FDD_CMD_MOTOR_ON
        call    F_BIOS_SERIAL_CONOUT_B
        ret
;------------------------------------------------------------------------------
BIOS_FDD_MOTOR_OFF:
; Tells ASMDC to turn the FDD motor off
        ; Send command to ASMDC
        ld      A, FDD_CMD_MOTOR_OFF
        call    F_BIOS_SERIAL_CONOUT_B
        ret
;------------------------------------------------------------------------------
BIOS_FDD_GET_STATUS:
; OUT => SYSVARS.DISK_status
;           Low Nibble (0x00 if all OK)
;               bit 0 = not used
;               bit 1 = not used
;               bit 2 = set if last command resulted in error
;               bit 3 = not used
;           High Nibble (error code)

        ; Send command to ASMDC
        ld      A, FDD_CMD_GET_STATUS
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ld      (DISK_status), A
        ret
;------------------------------------------------------------------------------
BIOS_FDD_CHANGE:
; Tells the ASMDC that the DISK_current is now the FDD

        ; Send command to ASMDC
        ld      A, FDD_CMD_CHKDISKIN
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ret
;------------------------------------------------------------------------------
BIOS_FDD_LOWLVL_FORMAT:
; Tells the ASMD to low-level format a floppy disk
; OUT => A = Status (0x00 = All OK / bit 2 set if last command resulted in error)

        ; Send command to ASMDC
        ld      A, FDD_CMD_FORMAT
        call    F_BIOS_SERIAL_CONOUT_B
        ; Wait for ASMDC to confirm that the low-level format finished
        call    F_BIOS_SERIAL_CONIN_B
        ; Check for errors
        ld      A, FDD_CMD_GET_STATUS
        call    F_BIOS_SERIAL_CONOUT_B
        ret
;------------------------------------------------------------------------------
BIOS_FDD_CHECK_DISKIN:
; Asks ASMDC if a disk is inside the drive
; OUT => A = 0x00 yes / 0xFF no

        ; Send command to ASMDC
        ld      A, FDD_CMD_CHKDISKIN
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ret
;------------------------------------------------------------------------------
BIOS_FDD_CHECK_WPROTECT:
; Asks ASMDC if a disk is write protected
; OUT => A = 0x00 yes / 0xFF no

        ; Send command to ASMDC
        ld      A, FDD_CMD_CHKWPROTECT
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        call    F_BIOS_SERIAL_CONIN_B
        ret

;==============================================================================
;      ___________   _____               _            _____ ____  ____
;     /  ___|  _  \ /  __ \             | |          |  ___|  _ \|  _ \
;     \ `--.| | | | | /  \/ __ _ _ __ __| |          | |_  | | | | | | |
;      `--. \ | | | | |    / _` | '__/ _` |    &     |  _| | | | | | | |
;     /\__/ / |/ /  | \__/\ (_| | | | (_| |          | |   | |_| | |_| |
;     \____/|___/    \____/\__,_|_|  \__,_|          |_|   |____/|____/
;==============================================================================
;------------------------------------------------------------------------------
BIOS_DISK_READ_SEC:
; Read a Sector (512 bytes) from FF or SD card into RAM buffer
; IN <= E = sector address LBA 0 (bits 0-7)
;       D = sector address LBA 1 (bits 8-15)
;       C = sector address LBA 2 (bits 16-23)   Not used because max sector is 65,535
;       B = sector address LBA 3 (bits 24-27)   Not used because max sector is 65,535
;       DISK_current = selects FDD or SD
; OUT => SYSVARS.DISK Buffer

        ; If DISK_current is 0, then cmd to FDD. Otherwise, to SD
        ld      A, (DISK_current)
        cp      0
        jp      z, _readsec_fdd
        call    F_BIOS_SD_BUSY_WAIT
        ld      A, SD_CMD_READ_SECTOR       ; Read Sector from SD
        jp      _readsec
_readsec_fdd:
        call    F_BIOS_FDD_BUSY_WAIT
        ld      A, FDD_CMD_READ_SECTOR      ; Read Sector from FDD
_readsec:
        ; Send command to ASMDC
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (DISK_current)           ; Send current DISK
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, E                        ; Send LSB
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, D                        ; Send MSB
        call    F_BIOS_SERIAL_CONOUT_B
        ; Receive data from ASMDC
        ld      HL, DISK_BUFFER_START       ; Sector data will be stored at the DISK buffer in RAM
        ld      B, $0                       ; 256 words (512 bytes) will be read
_read_512:
; Read 2 bytes each time, 256 times
; Hence, 512 bytes are read in total
        ; 1st byte
        call    F_BIOS_SERIAL_CONIN_B
        ld      (HL), A
        inc     HL
        ; 2nd byte
        call    F_BIOS_SERIAL_CONIN_B
        ld      (HL), A
        inc     HL

        djnz    _read_512
        ret

;------------------------------------------------------------------------------
BIOS_DISK_WRITE_SEC:
; Write a Sector (512 bytes) from RAM buffer into FDD or SD Card
; IN <= E = sector address LBA 0 (bits 0-7)
;       D = sector address LBA 1 (bits 8-15)
;       C = sector address LBA 2 (bits 16-23)   Not used because max sector is 65,535
;       B = sector address LBA 3 (bits 24-27)   Not used because max sector is 65,535
;       DISK_current = selects FDD or SD

        ; If DISK_current is 0, then cmd to FDD. Otherwise, to SD
        ld      A, (DISK_current)
        cp      0
        jp      z, _writesec_fdd
        call    F_BIOS_SD_BUSY_WAIT
        ld      A, SD_CMD_WRITE_SECTOR       ; Write Sector to SD
        jp      _writesec
_writesec_fdd:
        call    F_BIOS_FDD_BUSY_WAIT
        ld      A, FDD_CMD_WRITE_SECTOR      ; Write Sector to FDD
_writesec:
        ; Send command to ASMDC
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, (DISK_current)           ; Send current DISK
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, E                        ; Send LSB
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, D                        ; Send MSB
        call    F_BIOS_SERIAL_CONOUT_B
        ; Send 512 bytes of data to be written
        ld      HL, DISK_BUFFER_START       ; Sector data is stored at the DISK buffer in RAM
        ; ld      B, $0                       ; 256 words (512 bytes) will be written
                                            ;  Not needed, as BC already comes as $0 from the calling subroutine
_write_512B:
; Write 2 bytes each time, 256 times
; Hence, 512 bytes are written in total
        ; 1st byte
        ld      A, (HL)                     ; A = byte to be written
        call    F_BIOS_SERIAL_CONOUT_B
        inc     HL
        ; 2nd byte
        ld      A, (HL)                     ; A = byte to be written
        call    F_BIOS_SERIAL_CONOUT_B
        inc     HL
        djnz    _write_512B                 ; did B went back to 0 (i.e. 256 times)?
                                            ; No, continue loop
        ret                                 ; yes, exit routine