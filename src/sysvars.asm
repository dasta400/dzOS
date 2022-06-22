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
; 	-
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

		.ORG	SYSVARS_START
;==============================================================================
; SIO/2 buffers
;==============================================================================
SIO_CH_A_BUFFER:			.EXPORT     	SIO_CH_A_BUFFER
		    .FILL   SIO_BUFFER_SIZE, 0
SIO_CH_A_IN_PTR:			.EXPORT     	SIO_CH_A_IN_PTR
	        .BYTE   0, 0
SIO_CH_A_RD_PTR:			.EXPORT     	SIO_CH_A_RD_PTR
	        .BYTE   0, 0
SIO_CH_A_BUFFER_USED: 		.EXPORT     	SIO_CH_A_BUFFER_USED
	        .BYTE   0
SIO_CH_B_BUFFER:    		.EXPORT     	SIO_CH_B_BUFFER
		    .FILL   SIO_BUFFER_SIZE, 0
SIO_CH_B_IN_PTR:    		.EXPORT     	SIO_CH_B_IN_PTR
	        .BYTE   0, 0
SIO_CH_B_RD_PTR:			.EXPORT     	SIO_CH_B_RD_PTR
	        .BYTE   0, 0
SIO_CH_B_BUFFER_USED: 		.EXPORT     	SIO_CH_B_BUFFER_USED
	        .BYTE   0
SIO_PRIMARY_IO:				.EXPORT     	SIO_PRIMARY_IO
            .BYTE   0
;==============================================================================
; CLI buffers
;==============================================================================
buffer_cmd:					.EXPORT			buffer_cmd
				.FILL	16, 0
buffer_parm1_val:			.EXPORT			buffer_parm1_val
				.FILL	16, 0
buffer_parm2_val:			.EXPORT			buffer_parm2_val
				.FILL	16, 0
buffer_pgm:					.EXPORT			buffer_pgm
				.FILL	32, 0			; general buffer from programs
;==============================================================================
; CompactFlash buffers
;==============================================================================
cf_is_formatted:			.EXPORT			cf_is_formatted
				.BYTE	0				; Indicates if the CompactFlash can be used.
										; FF if it’s DZFS format. 00 otherwise
cur_partition:				.EXPORT			cur_partition
				.BYTE	0				; Current partition number. Used for LBA addressing.
cur_sector:					.EXPORT			cur_sector
				.BYTE	0, 0
; Current file specifications
cur_file_name:				.EXPORT			cur_file_name
				.FILL	14, 0
cur_file_attribs:			.EXPORT			cur_file_attribs
				.BYTE	0
cur_file_time_created:		.EXPORT			cur_file_time_created
				.BYTE	0, 0
cur_file_date_created:		.EXPORT			cur_file_date_created
				.BYTE	0, 0
cur_file_time_modified:		.EXPORT			cur_file_time_modified
				.BYTE	0, 0
cur_file_date_modified:		.EXPORT			cur_file_date_modified
				.BYTE	0, 0
cur_file_size_bytes:		.EXPORT			cur_file_size_bytes
				.BYTE	0, 0
cur_file_size_sectors:		.EXPORT			cur_file_size_sectors
				.BYTE	0
cur_file_entry_number:		.EXPORT			cur_file_entry_number
				.BYTE	0, 0
cur_file_1st_sector:		.EXPORT			cur_file_1st_sector
				.BYTE	0, 0
cur_file_load_addr:			.EXPORT			cur_file_load_addr
				.BYTE	0, 0
;==============================================================================
; Temporary variables
;==============================================================================
tmp_addr1:					.EXPORT			tmp_addr1
				.BYTE	0, 0			; Temporary storage for an address
tmp_addr2:					.EXPORT			tmp_addr2
				.BYTE	0, 0			; Temporary storage for an address
tmp_addr3:					.EXPORT			tmp_addr3
				.BYTE	0, 0			; Temporary storage for an address
tmp_byte:					.EXPORT			tmp_byte
				.BYTE	0				; Temporary storage for a Byte

;==============================================================================
; END of CODE
;==============================================================================
		.ORG	SYSVARS_END
		.END