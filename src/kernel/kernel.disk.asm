;******************************************************************************
; Name:         kernel.disk.asm
; Description:  Kernel's DISK routines
; Author:       David Asta
; License:      The MIT License
; Created:      27 Dec 2023
; Version:      1.0.0
; Last Modif.:  27 Dec 2023
;******************************************************************************
; CHANGELOG
;   - 
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2023 David Asta
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

KRN_INIT_FDD:
; Detect FDD
        ld      HL, msg_fdd_init
        ld      A, (col_kernel_notice)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_left_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ; Added 13 Dec 2023 - Check if FDD is connected
        call    F_BIOS_FDD_GET_STATUS
        ld      A, (DISK_status)
        bit     0, A
        jp      nz, _fdd_no_connected
        ld      A, 1                    ; set value (detected)
        ld      (FDD_detected), A       ;   in SYSVARS
        ;   print DISKn message
        ld      HL, msg_disk
        ld      A, (col_kernel_disk)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, '0'                  ; FDD is always DISK0
        call    F_BIOS_SERIAL_CONOUT_A
        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret
_fdd_no_connected:
        xor     A                       ; set value (not detected)
        ld      (FDD_detected), A       ;   in SYSVARS
        ld      HL, error_4001
        ld      A, (col_kernel_error)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret
;------------------------------------------------------------------------------
KRN_INIT_SD:
; Detect SD Card
        ld      HL, msg_sd_init
        ld      A, (col_kernel_notice)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_left_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        call    F_BIOS_SD_GET_STATUS
        ld      HL, DISK_status         ; DISK_Status contains the number of images
                                        ;   files found by ASMDC in the Upper Nibble
                                        ;   and any errors in the Lower Nibble
        bit     0, (HL)                 ; Check if SD card was found
        jp      nz, sd_notfound
        ld      HL, msg_sd_found
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        bit     1, (HL)                 ; Check if an Image was found
        jp      nz, sd_image_notfound
        ld      HL, msg_sd_imgs_found
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR

        ; Print number of images found
        xor     A                       ; Clear Carry flag
        ld      A, (DISK_status)
        ;       Get Upper Nibble to Lower Nibble
        rra
        rra
        rra
        rra
        ld      (SD_images_num), A      ;       Store it in SYSVARS
        ;       Convert to ASCII
        ld      D, 0
        ld      E, A
        call    F_KRN_BIN_TO_ASCII
        ld      IX, CLI_buffer_pgm
        ld      B, (IX)
        ;       Print number of images
print_dskimages:
        ld      A, (IX + 1)
        call    F_BIOS_SERIAL_CONOUT_A
        inc     IX
        djnz    print_dskimages

        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR

        ; Get images' info
        ld      IX, FREERAM_END - 210   ; where to store the image files info
                                        ; for a max. of 15 disks and 14 bytes
                                        ; needed for each, we need a total max.
                                        ; of 210 bytes
KRN_DISK_LIST:
        ld      IY, DISK_current
        ld      A, 1                        ; image file number counter
        ld      (DISK_current), A
        ld      A, (SD_images_num)
        inc     A                           ; count 1 extra for FDD
        ld      (tmp_byte), A               ; total number of images to get
get_imgs_info:
        call    F_BIOS_SD_GET_IMG_INFO
        inc     (IY)                        ; increment counter
        ld      A, (DISK_current)
        ld      HL, tmp_byte
        cp      (HL)                        ; did get all images' info?
        jp      nz, get_imgs_info           ; if not, get more images

        ; Print images' information (name and capacity in MB)
        xor     A
        ld      (tmp_byte), A               ; images counter
        ld      HL, FREERAM_END - 211       ; start of images' info - 1
        push    HL                          ; HL = at the end of images' filename
info_loop:
        ;   print DISKn message
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        ld      HL, msg_sd_disk_sep
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_disk
        ld      A, (col_kernel_disk)
        call    F_KRN_SERIAL_WRSTRCLR

        ;   print disk number
        ld      A, (tmp_byte)
        inc     A                           ; SD disks start at 1
        call    F_KRN_BIN_TO_BCD4           ; HL = disk number in decimal
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII          ; DE = capacity in ASCII string
        ;   skip leading zeros
        ld      A, (tmp_addr1 + 4)
        cp      $30
        jp      z, skip_leading_zero
        call    F_BIOS_SERIAL_CONOUT_A      ; print first digit (if not a zero)
skip_leading_zero:
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A      ; print second digit
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A      ; print separator

        pop     HL                          ; restore pointer to images' filename
        ;   print image file filename
        inc     HL                          ; skip images' filename terminator
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR

        ;   print image file capacity
        inc     HL                          ; skip images' filename terminator
        ld      A, (HL)                     ; A = image file capacity
        push    HL                          ; HL = at the start of images' filename
        call    F_KRN_BIN_TO_BCD4           ; HL = capacity in decimal
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII          ; DE = capacity in ASCII string
        ld      A, SPACE
        call    F_BIOS_SERIAL_CONOUT_A      ; print separator
        ld      A, (tmp_addr1 + 3)
        cp      $30
        jp      nz, print_digit
        ld      A, SPACE                    ; substitute zero by a space
print_digit:
        call    F_BIOS_SERIAL_CONOUT_A      ; print first digit (if not a zero)
        ld      A, (tmp_addr1 + 4)
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_addr1 + 5)
        call    F_BIOS_SERIAL_CONOUT_A

        ;   print MB message
        ld      HL, msg_sd_MB
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR

        ;   print CR
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A

        ; increment images counter
        ld      HL, tmp_byte
        inc     (HL)
        ; did print all images' info already?
        ld      A, (tmp_byte)
        ld      HL, SD_images_num
        cp      (HL)
        jp      nz, info_loop
        pop     HL
        ret

sd_notfound:
        ld      HL, error_1002
        ld      A, (col_kernel_error)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret

sd_image_notfound:
        ld      HL, error_1003
        ld      A, (col_kernel_error)
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, msg_right_brkt
        ld      A, (col_kernel_info)
        call    F_KRN_SERIAL_WRSTRCLR
        ret
;------------------------------------------------------------------------------
KRN_DISK_CHANGE:
; Set default DISK = A
        push    AF                      ; backup new DISK number
        ; If DISK is 0, then cmd to FDD. Otherwise, to SD
        ; ld      A, (DISK_current)
        cp      0
        jr      nz, _chgdsk
_chgdsk_fdd:
        ; Added 14 Dec 2023 - Return error if FDD is not connected
        ld      A, (FDD_detected)
        cp      0
        jr      z, _chgdsk_fdd_error
        ; FDD is connected
        call    F_BIOS_FDD_CHANGE       ; 0x00=OK, 0xFF=No disk in drive
        cp      0                       ; Any error?
        jr      z, _chgdsk              ; No error
_chgdsk_fdd_error:
        ; Error. Restore AF to avoid crash and set A=0xFF, to indicate error
        pop     AF
        ld      A, $FF
        ret
_chgdsk:
        pop     AF                      ; restore new DISK number
        ld      (DISK_current), A       ; and set it as DISK_current
        call    F_KRN_DZFS_READ_SUPERBLOCK
        xor     A                       ; No errors
        ret