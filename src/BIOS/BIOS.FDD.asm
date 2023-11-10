;******************************************************************************
; BIOS.FDD.asm
;
; Floppy Disk Drive (FDD)
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
