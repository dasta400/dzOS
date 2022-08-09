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
SIO_CH_A_BUFFER:            .EXPORT         SIO_CH_A_BUFFER
            .FILL   SIO_BUFFER_SIZE, 0
SIO_CH_A_IN_PTR:            .EXPORT         SIO_CH_A_IN_PTR
            .BYTE   0, 0
SIO_CH_A_RD_PTR:            .EXPORT         SIO_CH_A_RD_PTR
            .BYTE   0, 0
SIO_CH_A_BUFFER_USED:       .EXPORT         SIO_CH_A_BUFFER_USED
            .BYTE   0
SIO_CH_B_BUFFER:            .EXPORT         SIO_CH_B_BUFFER
            .FILL   SIO_BUFFER_SIZE, 0
SIO_CH_B_IN_PTR:            .EXPORT         SIO_CH_B_IN_PTR
            .BYTE   0, 0
SIO_CH_B_RD_PTR:            .EXPORT         SIO_CH_B_RD_PTR
            .BYTE   0, 0
SIO_CH_B_BUFFER_USED:       .EXPORT         SIO_CH_B_BUFFER_USED
            .BYTE   0
SIO_PRIMARY_IO:             .EXPORT         SIO_PRIMARY_IO
            .BYTE   0
;==============================================================================
; CompactFlash buffers
;==============================================================================
CF_is_formatted:            .EXPORT         CF_is_formatted
                .BYTE    0                ; Indicates if the CompactFlash can be used.
                                        ; FF if it’s DZFS format. 00 otherwise
CF_cur_partition:           .EXPORT         CF_cur_partition
                .BYTE    0                ; Current partition number. Used for LBA addressing.
CF_cur_sector:              .EXPORT         CF_cur_sector
                .BYTE    0, 0
; Current file specifications
CF_cur_file_name:           .EXPORT         CF_cur_file_name
                .FILL    14, 0
CF_cur_file_attribs:        .EXPORT         CF_cur_file_attribs
                .BYTE    0
CF_cur_file_time_created:   .EXPORT         CF_cur_file_time_created
                .BYTE    0, 0
CF_cur_file_date_created:   .EXPORT         CF_cur_file_date_created
                .BYTE    0, 0
CF_cur_file_time_modified:  .EXPORT         CF_cur_file_time_modified
                .BYTE    0, 0
CF_cur_file_date_modified:  .EXPORT         CF_cur_file_date_modified
                .BYTE    0, 0
CF_cur_file_size_bytes:     .EXPORT         CF_cur_file_size_bytes
                .BYTE    0, 0
CF_cur_file_size_sectors:   .EXPORT         CF_cur_file_size_sectors
                .BYTE    0
CF_cur_file_entry_number:   .EXPORT         CF_cur_file_entry_number
                .BYTE    0, 0
CF_cur_file_1st_sector:     .EXPORT         CF_cur_file_1st_sector
                .BYTE    0, 0
CF_cur_file_load_addr:      .EXPORT         CF_cur_file_load_addr
                .BYTE    0, 0
;==============================================================================
; CLI buffers
;==============================================================================
CLI_buffer_cmd:             .EXPORT         CLI_buffer_cmd
                .FILL    16, 0
CLI_buffer_parm1_val:       .EXPORT         CLI_buffer_parm1_val
                .FILL    16, 0
CLI_buffer_parm2_val:       .EXPORT         CLI_buffer_parm2_val
                .FILL    16, 0
CLI_buffer_pgm:             .EXPORT         CLI_buffer_pgm
                .FILL    32, 0            ; general buffer from programs
CLI_buffer_full_cmd:        .EXPORT         CLI_buffer_full_cmd
                .FILL    64, 0
;==============================================================================
; Temporary variables
;==============================================================================
tmp_addr1:                  .EXPORT         tmp_addr1
                .BYTE    0, 0            ; Temporary storage for an address
tmp_addr2:                  .EXPORT         tmp_addr2
                .BYTE    0, 0            ; Temporary storage for an address
tmp_addr3:                  .EXPORT         tmp_addr3
                .BYTE    0, 0            ; Temporary storage for an address
tmp_byte:                   .EXPORT         tmp_byte
                .BYTE    0                ; Temporary storage for a Byte
;==============================================================================
; Real-Time Clock variables
;==============================================================================
RTC_hour                    .EXPORT         RTC_hour
                .BYTE    0
RTC_minutes                 .EXPORT         RTC_minutes
                .BYTE    0
RTC_seconds                 .EXPORT         RTC_seconds
                .BYTE    0
RTC_century                 .EXPORT         RTC_century
                .BYTE    0
RTC_year                    .EXPORT         RTC_year
                .BYTE    0
RTC_month                   .EXPORT         RTC_month
                .BYTE    0
RTC_day                     .EXPORT         RTC_day
                .BYTE    0
RTC_day_of_the_week         .EXPORT         RTC_day_of_the_week
                .BYTE    0

;==============================================================================
; END of CODE
;==============================================================================
        .ORG    SYSVARS_END
        .END