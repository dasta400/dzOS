;******************************************************************************
; kernel.asm
;
; Kernel
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 21 Jun 2022
;******************************************************************************
; CHANGELOG
;     -
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2018-2022 David Asta
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

; ToDo - Calls to functions should be to RAM jumpblock addresses

;==============================================================================
; Includes
;==============================================================================
#include "src/equates.inc"
#include "exp/BIOS.exp"
#include "exp/sysvars.exp"

        .ORG    KRN_START

        ; Kernel start up messages
        ld      HL, msg_dzos            ; dzOS welcome message
        ld      A, ANSI_COLR_BLU
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, dzos_version        ; dzOS version
        ld      A, ANSI_COLR_BLU
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ld      HL, msg_bios_version    ; BIOS version
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_krn_version     ; Kernel version
        ld      A, ANSI_COLR_CYA
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

        ; Detect RAM size
        ld      HL, krn_msg_ramsize_detect
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, krn_msg_ramsize_lead
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_KRN_WHICH_RAMSIZE
        jp      nz, ramsize_32k
ramsize_64k:
        ld      HL, krn_msg_ramsize_64k
        jp      ramsize_print
ramsize_32k:
        ld      HL, krn_msg_ramsize_32k
ramsize_print:
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, krn_msg_ramsize_trail
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES

        ; Initialise CF card reader
        ld      hl, krn_msg_cf_init
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_BIOS_CF_INIT
        ld      HL, krn_msg_OK
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ; Read Superblock
        call    F_KRN_DZFS_READ_SUPERBLOCK

        ; Copy BIOS Jumpblocks from ROM to RAM
        ld      HL, krn_msg_cpybiosjblks
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, BIOS_JBLK_START      ; pointer to address of start of BIOS Jumpblocks in ROM
        ld      DE, BIOS_JBLK_COPY_START ; pointer to address of start of BIOS Jumpblocks in RAM
        ld      BC, 256                  ; jumpblocks are 256 bytes max.
        ldir                             ; copy from ROM to RAM
        ld      HL, krn_msg_OK
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ; Copy Kernel Jumpblocks from ROM to RAM
        ld      HL, krn_msg_cpykrnjblks
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, KRN_JBLK_START       ; pointer to address of start of Kernel Jumpblocks in ROM
        ld      DE, KRN_JBLK_COPY_START  ; pointer to address of start of Kernel Jumpblocks in RAM
        ld      BC, 256                  ; jumpblocks are 256 bytes max.
        ldir                             ; copy from ROM to RAM
        ld      HL, krn_msg_OK
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR

        jp      CLI_START                ; transfer control to CLI

;==============================================================================
; General Subroutines
;==============================================================================
F_KRN_DZFS_SHOW_DISKINFO:           .EXPORT     F_KRN_DZFS_SHOW_DISKINFO
        ; Volume Label
        ld      HL, msg_vol_label
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 16                   ; counter = 4 bytes
        ld      HL, CF_SBLOCK_LABEL     ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
        ; Volume Serial Number
        ld      HL, msg_volsn
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, (CF_SBLOCK_SERNUM)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $01)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $02)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $03)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ')'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; File System id
        ld      HL, msg_filesys
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 8                            ; counter = 4 bytes
        ld      HL, CF_SBLOCK_FSID              ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
        ld        B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Volume Date/Time Creation
        ld      HL, msg_vol_creation
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA          ; day
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 2      ; month
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 4                            ; counter = 4 bytes
        ld      HL, CF_SBLOCK_DATECREA + 4      ; year
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 8      ; hour
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 10     ; minutes
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 12     ; seconds
        call    F_KRN_SERIAL_PRN_BYTES
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Number of partitions
        ld      HL, msg_num_partitions
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, (CF_SBLOCK_NUMPARTITIONS)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
;TODO        ; Bytes per Sector
        ld      HL, msg_bytes_sector
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
;TODO        ; Sectors per Block
        ld      HL, msg_sectors_block
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
        ; ld      A, (CF_SBLOCK_SECBLOCK)
        ; call    F_KRN_BIN_TO_BCD4
        ; ld      A, 64
        ; call    F_KRN_HEX_TO_ASCII
        ; ld      A, H
        ; call    F_BIOS_SERIAL_CONOUT_A
        ; ld      A, L
        ; call    F_BIOS_SERIAL_CONOUT_A
        ret
;==============================================================================
; Kernel Modules
;==============================================================================
#include "src/kernel/kernel.kbd.asm"
#include "src/kernel/kernel.serial.asm"
#include "src/kernel/kernel.mem.asm"
#include "src/kernel/kernel.string.asm"
#include "src/kernel/kernel.conv.asm"
#include "src/kernel/kernel.math.asm"
#include "src/kernel/kernel.dzfs.asm"

;==============================================================================
; Messages
;==============================================================================
msg_dzos:
        .BYTE    CR, LF
        .BYTE    "#####   ######   ####    ####  ", CR, LF
        .BYTE    "##  ##     ##   ##  ##   ##    ", CR, LF
        .BYTE    "##  ##   ##     ##  ##     ##  ", CR, LF
        .BYTE    "#####   ######   ####    ####  ", 0
msg_krn_version:
        .BYTE    CR, LF
        .BYTE    "Kernel v1.0.0", 0
krn_msg_cf_init:
        .BYTE    "....Initialising CompactFlash reader ", 0
krn_msg_cpybiosjblks:
        .BYTE    "....Copying BIOS Jumblocks to RAM ", 0
krn_msg_cpykrnjblks:
        .BYTE    "....Copying Kernel Jumblocks to RAM ", 0
krn_msg_ramsize_detect:
        .BYTE   "....Detecting RAM size", 0
krn_msg_ramsize_32k:
        .BYTE   "32", 0
krn_msg_ramsize_64k:
        .BYTE   "64", 0
krn_msg_ramsize_lead:
        .BYTE   " [ ", 0
krn_msg_ramsize_trail:
        .BYTE   " KB ]", 0
krn_msg_OK:
        .BYTE   "[ OK ]", CR, LF, 0
msg_volsn:
        .BYTE   " (S/N: ",0
msg_vol_label:
        .BYTE   "            Volume . . : ",0
msg_vol_creation:
        .BYTE   "            Created on : ",0
msg_num_partitions:
        .BYTE   "            Partitions : ",0
msg_filesys:
        .BYTE   "            File System: ", 0
msg_bytes_sector:
        .BYTE   "       Bytes per Sector: ", 0
msg_sectors_block:
        .BYTE   "      Sectors per Block: ", 0

        .ORG    KRN_DZOS_VERSION
dzos_version:            .EXPORT        dzos_version
        .BYTE    "vYYYY.MM.DD.   ", 0    ; This is overwritten by Makefile with
                                        ; compilation date and compile number
;==============================================================================
; END of CODE
;==============================================================================
        .ORG    KRN_END
        .BYTE    0
        .END