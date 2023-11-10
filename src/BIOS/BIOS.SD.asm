;******************************************************************************
; BIOS.SD.asm
;
; SDcard
; for dastaZ80's dzOS
; by David Asta (Nov 2022)
;
; Version 1.0.0
; Created on 02 Nov 2022
; Last Modification 10 Nov 2023
;******************************************************************************
; CHANGELOG
;   - 
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
        xor     A
        ld      (IX), A
        inc     IX
        ; Receive image file capacity
        call    F_BIOS_SERIAL_CONIN_B
        ld      (IX), A
        inc     IX
        ret
;------------------------------------------------------------------------------
BIOS_SD_PARK_DISKS:
; Tells the ASMDC to close the all Image file(s)
        ld      A, (SD_images_num)          ; How many images are open?
        ld      B, A                        ; B = image counter
_parkimage:
        ; Send command to ASMDC to close each image
        call    F_BIOS_SD_BUSY_WAIT
        ld      A, SD_CMD_PARK_DISKS
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, B                        ; image number to close
        call    F_BIOS_SERIAL_CONOUT_B
        djnz    _parkimage                  ; continue if not done with all images
        ret
;------------------------------------------------------------------------------
BIOS_SD_MOUNT_DISKS:
; Tells the ASMDC to open the all Image file(s)
        ld      A, (SD_images_num)          ; How many images were open?
        ld      B, A                        ; B = image counter
_mountimage:
        ; Send command to ASMDC to open each image
        call    F_BIOS_SD_BUSY_WAIT
        ld      A, SD_CMD_MOUNT_DISK
        call    F_BIOS_SERIAL_CONOUT_B
        ld      A, B                        ; image number to open
        call    F_BIOS_SERIAL_CONOUT_B
        djnz    _mountimage
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