;******************************************************************************
; sysvars.asm
;
; System Variables
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 21 Jun 2022
;******************************************************************************
; CHANGELOG
; -
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

;==============================================================================
; Includes
;==============================================================================
#include "src/equates.inc"

        .ORG    SYSVARS_START
;==============================================================================
; SIO/2 buffers
;==============================================================================
SIO_CH_A_BUFFER:                .EXPORT         SIO_CH_A_BUFFER
            .FILL       SIO_BUFFER_SIZE, 0
SIO_CH_A_IN_PTR:                .EXPORT         SIO_CH_A_IN_PTR
            .BYTE       0, 0
SIO_CH_A_RD_PTR:                .EXPORT         SIO_CH_A_RD_PTR
            .BYTE       0, 0
SIO_CH_A_BUFFER_USED:           .EXPORT         SIO_CH_A_BUFFER_USED
            .BYTE       0
SIO_CH_B_BUFFER:                .EXPORT         SIO_CH_B_BUFFER
            .FILL       SIO_BUFFER_SIZE, 0
SIO_CH_B_IN_PTR:                .EXPORT         SIO_CH_B_IN_PTR
            .BYTE       0, 0
SIO_CH_B_RD_PTR:                .EXPORT         SIO_CH_B_RD_PTR
            .BYTE       0, 0
SIO_CH_B_BUFFER_USED:           .EXPORT         SIO_CH_B_BUFFER_USED
            .BYTE       0
;==============================================================================
; DISK buffers
;==============================================================================
DISK_is_formatted:              .EXPORT         DISK_is_formatted
                .BYTE   0                   ; Indicates if the DISK can be used.
                                            ; FF if it’s DZFS format. 00 otherwise
DISK_show_deleted:              .EXPORT         DISK_show_deleted
                .BYTE   0
DISK_cur_sector:                .EXPORT         DISK_cur_sector
                .BYTE   0, 0
; Current file specifications
DISK_cur_file_name:             .EXPORT         DISK_cur_file_name
                .FILL   14, 0
DISK_cur_file_attribs:          .EXPORT         DISK_cur_file_attribs
                .BYTE   0
DISK_cur_file_time_created:     .EXPORT         DISK_cur_file_time_created
                .BYTE   0, 0
DISK_cur_file_date_created:     .EXPORT         DISK_cur_file_date_created
                .BYTE   0, 0
DISK_cur_file_time_modified:    .EXPORT         DISK_cur_file_time_modified
                .BYTE   0, 0
DISK_cur_file_date_modified:    .EXPORT         DISK_cur_file_date_modified
                .BYTE   0, 0
DISK_cur_file_size_bytes:       .EXPORT         DISK_cur_file_size_bytes
                .BYTE   0, 0
DISK_cur_file_size_sectors:     .EXPORT         DISK_cur_file_size_sectors
                .BYTE   0
DISK_cur_file_entry_number:     .EXPORT         DISK_cur_file_entry_number
                .BYTE   0, 0
DISK_cur_file_1st_sector:       .EXPORT         DISK_cur_file_1st_sector
                .BYTE   0, 0
DISK_cur_file_load_addr:        .EXPORT         DISK_cur_file_load_addr
                .BYTE   0, 0
;==============================================================================
; CLI buffers
;==============================================================================
CLI_buffer:                     .EXPORT         CLI_buffer
                .FILL   6, 0
CLI_buffer_cmd:                 .EXPORT         CLI_buffer_cmd
                .FILL   16, 0
CLI_buffer_parm1_val:           .EXPORT         CLI_buffer_parm1_val
                .FILL   16, 0
CLI_buffer_parm2_val:           .EXPORT         CLI_buffer_parm2_val
                .FILL   16, 0
CLI_buffer_pgm:                 .EXPORT         CLI_buffer_pgm
                .FILL   32, 0                   ; general buffer from programs
CLI_buffer_full_cmd:            .EXPORT         CLI_buffer_full_cmd
                .FILL   64, 0
;==============================================================================
; Real-Time Clock variables
;==============================================================================
RTC_hour                        .EXPORT         RTC_hour
                .BYTE   0
RTC_minutes                     .EXPORT         RTC_minutes
                .BYTE   0
RTC_seconds                     .EXPORT         RTC_seconds
                .BYTE   0
RTC_century                     .EXPORT         RTC_century
                .BYTE   0
RTC_year                        .EXPORT         RTC_year
                .BYTE   0
RTC_year4                       .EXPORT         RTC_year4
                .BYTE   0, 0
RTC_month                       .EXPORT         RTC_month
                .BYTE   0
RTC_day                         .EXPORT         RTC_day
                .BYTE   0
RTC_day_of_the_week             .EXPORT         RTC_day_of_the_week
                .BYTE   0
;==============================================================================
; Math variables
;==============================================================================
MATH_CRC                        .EXPORT         MATH_CRC
                .BYTE   0, 0
MATH_polynomial                 .EXPORT         MATH_polynomial
                .BYTE   0, 0
;==============================================================================
; Generic variables
;==============================================================================
SD_images_num                   .EXPORT         SD_images_num
                .BYTE   0                       ; Number of Image Files found by ASMDC
DISK_current                    .EXPORT         DISK_current
                .BYTE   0                       ; Current DISK active.
                                                ; All disk operations will be on this DISK
DISK_status                     .EXPORT         DISK_status
                .BYTE   0
tmp_addr1:                      .EXPORT         tmp_addr1
                .BYTE   0, 0                    ; Temporary storage for an address
tmp_addr2:                      .EXPORT         tmp_addr2
                .BYTE   0, 0                    ; Temporary storage for an address
tmp_addr3:                      .EXPORT         tmp_addr3
                .BYTE   0, 0                    ; Temporary storage for an address
tmp_byte:                       .EXPORT         tmp_byte
                .BYTE   0                       ; Temporary storage for a Byte
tmp_byte2:                      .EXPORT         tmp_byte2
                .BYTE   0                       ; Temporary storage for a Byte
;==============================================================================
; END of CODE
;==============================================================================
        .ORG    SYSVARS_END
        .END