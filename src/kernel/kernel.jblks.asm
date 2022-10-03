;******************************************************************************
; kernel_jblks.asm
;
; Kernel Jumpblocks
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

        .ORG    KRN_JBLK_START

        ; Serial subroutines
F_KRN_SERIAL_SETFGCOLR:             .EXPORT         F_KRN_SERIAL_SETFGCOLR
        jp      KRN_SERIAL_SETFGCOLR
F_KRN_SERIAL_WRSTRCLR:              .EXPORT         F_KRN_SERIAL_WRSTRCLR
        jp      KRN_SERIAL_WRSTRCLR
F_KRN_SERIAL_WRSTR:                 .EXPORT         F_KRN_SERIAL_WRSTR
        jp      KRN_SERIAL_WRSTR
F_KRN_SERIAL_WR6DIG_NOLZEROS        .EXPORT         F_KRN_SERIAL_WR6DIG_NOLZEROS
        jp      KRN_SERIAL_WR6DIG_NOLZEROS
F_KRN_SERIAL_RDCHARECHO:            .EXPORT         F_KRN_SERIAL_RDCHARECHO
        jp      KRN_SERIAL_RDCHARECHO
F_KRN_SERIAL_EMPTYLINES:            .EXPORT         F_KRN_SERIAL_EMPTYLINES
        jp      KRN_SERIAL_EMPTYLINES
F_KRN_SERIAL_PRN_BYTES:             .EXPORT         F_KRN_SERIAL_PRN_BYTES
        jp      KRN_SERIAL_PRN_BYTES
F_KRN_SERIAL_PRN_BYTE:              .EXPORT         F_KRN_SERIAL_PRN_BYTE
        jp      KRN_SERIAL_PRN_BYTE
F_KRN_SERIAL_PRN_NIBBLE:            .EXPORT         F_KRN_SERIAL_PRN_NIBBLE
        jp      KRN_SERIAL_PRN_NIBBLE
F_KRN_SERIAL_PRN_WORD:              .EXPORT         F_KRN_SERIAL_PRN_WORD
        jp      KRN_SERIAL_PRN_WORD
F_KRN_SERIAL_BACKSPACE:             .EXPORT         F_KRN_SERIAL_BACKSPACE
        jp      KRN_SERIAL_BACKSPACE
F_KRN_SERIAL_SEND_ANSI_CODE:        .EXPORT         F_KRN_SERIAL_SEND_ANSI_CODE
        jp      KRN_SERIAL_SEND_ANSI_CODE

        ; String subroutines
F_KRN_TOUPPER:                      .EXPORT         F_KRN_TOUPPER
        jp      KRN_TOUPPER
F_KRN_IS_PRINTABLE:                 .EXPORT         F_KRN_IS_PRINTABLE
        jp      KRN_IS_PRINTABLE
F_KRN_IS_NUMERIC:                   .EXPORT         F_KRN_IS_NUMERIC
        jp      KRN_IS_NUMERIC
F_KRN_STRCMP:                       .EXPORT         F_KRN_STRCMP
        jp      KRN_STRCMP
F_KRN_STRCPY:                       .EXPORT         F_KRN_STRCPY
        jp      KRN_STRCPY
F_KRN_STRLEN:                       .EXPORT         F_KRN_STRLEN
        jp      KRN_STRLEN

        ; Memory subroutines
F_KRN_SETMEMRNG:                    .EXPORT         F_KRN_SETMEMRNG
        jp      KRN_SETMEMRNG
F_KRN_COPYMEM512:                   .EXPORT         F_KRN_COPYMEM512
        jp      KRN_COPYMEM512
F_KRN_SHIFT_BYTES_BY1:              .EXPORT         F_KRN_SHIFT_BYTES_BY1
        jp      KRN_SHIFT_BYTES_BY1
F_KRN_CLEAR_MEMAREA:                .EXPORT         F_KRN_CLEAR_MEMAREA
        jp      KRN_CLEAR_MEMAREA
F_KRN_CLEAR_CFBUFFER:               .EXPORT         F_KRN_CLEAR_CFBUFFER
        jp      KRN_CLEAR_CFBUFFER

        ; Conversion subroutines
F_KRN_ASCIIADR_TO_HEX:              .EXPORT         F_KRN_ASCIIADR_TO_HEX
        jp      KRN_ASCIIADR_TO_HEX
F_KRN_ASCII_TO_HEX:                 .EXPORT         F_KRN_ASCII_TO_HEX
        jp      KRN_ASCII_TO_HEX
F_KRN_HEX_TO_ASCII:                 .EXPORT         F_KRN_HEX_TO_ASCII
        jp      KRN_HEX_TO_ASCII
F_KRN_BIN_TO_BCD4:                  .EXPORT         F_KRN_BIN_TO_BCD4
        jp      KRN_BIN_TO_BCD4
F_KRN_BIN_TO_BCD6:                  .EXPORT         F_KRN_BIN_TO_BCD6
        jp      KRN_BIN_TO_BCD6
F_KRN_BCD_TO_ASCII:                 .EXPORT         F_KRN_BCD_TO_ASCII
        jp      KRN_BCD_TO_ASCII
F_KRN_BITEXTRACT:                   .EXPORT         F_KRN_BITEXTRACT
        jp      KRN_BITEXTRACT
F_KRN_BIN_TO_ASCII:                 .EXPORT         F_KRN_BIN_TO_ASCII
        jp      KRN_BIN_TO_ASCII
F_KRN_DEC_TO_BIN:                   .EXPORT         F_KRN_DEC_TO_BIN
        jp      KRN_DEC_TO_BIN
F_KRN_PKEDDATE_TO_DMY:              .EXPORT         F_KRN_PKEDDATE_TO_DMY
        jp      KRN_PKEDDATE_TO_DMY
F_KRN_PKEDTIME_TO_HMS:              .EXPORT         F_KRN_PKEDTIME_TO_HMS
        jp      KRN_PKEDTIME_TO_HMS

        ; Math subroutines
F_KRN_MULTIPLY816_SLOW:             .EXPORT         F_KRN_MULTIPLY816_SLOW
        jp      KRN_MULTIPLY816_SLOW
F_KRN_MULTIPLY1616:                 .EXPORT         F_KRN_MULTIPLY1616
        jp      KRN_MULTIPLY1616
F_KRN_DIV1616:                      .EXPORT         F_KRN_DIV1616
        jp      KRN_DIV1616
F_KRN_CRC16_INI:                    .EXPORT         F_KRN_CRC16_INI
        jp      KRN_CRC16_INI
F_KRN_CRC16_GEN:                    .EXPORT         F_KRN_CRC16_GEN
        jp      KRN_CRC16_GEN

        ; DZFS subroutines
F_KRN_DZFS_READ_SUPERBLOCK:         .EXPORT         F_KRN_DZFS_READ_SUPERBLOCK
        jp      KRN_DZFS_READ_SUPERBLOCK
F_KRN_DZFS_READ_BAT_SECTOR:         .EXPORT         F_KRN_DZFS_READ_BAT_SECTOR
        jp      KRN_DZFS_READ_BAT_SECTOR
F_KRN_DZFS_BATENTRY_TO_BUFFER:      .EXPORT         F_KRN_DZFS_BATENTRY_TO_BUFFER
        jp      KRN_DZFS_BATENTRY_TO_BUFFER
F_KRN_DZFS_SEC_TO_BUFFER:           .EXPORT         F_KRN_DZFS_SEC_TO_BUFFER
        jp      KRN_DZFS_SEC_TO_BUFFER
F_KRN_DZFS_GET_FILE_BATENTRY:       .EXPORT         F_KRN_DZFS_GET_FILE_BATENTRY
        jp      KRN_DZFS_GET_FILE_BATENTRY
F_KRN_DZFS_LOAD_FILE_TO_RAM:        .EXPORT         F_KRN_DZFS_LOAD_FILE_TO_RAM
        jp      KRN_DZFS_LOAD_FILE_TO_RAM
F_KRN_DZFS_DELETE_FILE:             .EXPORT         F_KRN_DZFS_DELETE_FILE
        jp      KRN_DZFS_DELETE_FILE
F_KRN_DZFS_CHGATTR_FILE:            .EXPORT         F_KRN_DZFS_CHGATTR_FILE
        jp      KRN_DZFS_CHGATTR_FILE
F_KRN_DZFS_RENAME_FILE:             .EXPORT         F_KRN_DZFS_RENAME_FILE
        jp      KRN_DZFS_RENAME_FILE
F_KRN_DZFS_FORMAT_CF:               .EXPORT         F_KRN_DZFS_FORMAT_CF
        jp      KRN_DZFS_FORMAT_CF
F_KRN_DZFS_SECTOR_TO_CF:            .EXPORT         F_KRN_DZFS_SECTOR_TO_CF
        jp      KRN_DZFS_SECTOR_TO_CF
F_KRN_DZFS_GET_BAT_FREE_ENTRY:      .EXPORT         F_KRN_DZFS_GET_BAT_FREE_ENTRY
        jp      KRN_DZFS_GET_BAT_FREE_ENTRY
F_KRN_DZFS_ADD_BAT_ENTRY:           .EXPORT         F_KRN_DZFS_ADD_BAT_ENTRY
        jp      KRN_DZFS_ADD_BAT_ENTRY
F_KRN_DZFS_CREATE_NEW_FILE:         .EXPORT         F_KRN_DZFS_CREATE_NEW_FILE
        jp      KRN_DZFS_CREATE_NEW_FILE
F_KRN_DZFS_SHOW_DISKINFO_SHORT      .EXPORT         F_KRN_DZFS_SHOW_DISKINFO_SHORT
        jp      KRN_DZFS_SHOW_DISKINFO_SHORT
F_KRN_DZFS_SHOW_DISKINFO:           .EXPORT         F_KRN_DZFS_SHOW_DISKINFO
        jp      KRN_DZFS_SHOW_DISKINFO
F_KRN_DZFS_CHECK_FILE_EXISTS:       .EXPORT         F_KRN_DZFS_CHECK_FILE_EXISTS
        jp      KRN_DZFS_CHECK_FILE_EXISTS

        ; RTC subroutines
F_KRN_RTC_SHOW_TIME                 .EXPORT         F_KRN_RTC_SHOW_TIME
        jp      KRN_RTC_SHOW_TIME
F_KRN_RTC_SHOW_DATE                 .EXPORT         F_KRN_RTC_SHOW_DATE
        jp      KRN_RTC_SHOW_DATE

        .ORG	KRN_JBLK_END
        .BYTE	0