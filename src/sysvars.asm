;******************************************************************************
; sysvars.asm
;
; System Variables
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 03 Jan 2018
;******************************************************************************
; CHANGELOG
; 	-
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; This file is part of dzOS
; Copyright (C) 2017-2018 David Asta

; dzOS is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; dzOS is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with dzOS.  If not, see <http://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------

;==============================================================================
; Includes
;==============================================================================
#include "src/equates.asm"
;==============================================================================
; Buffers
;==============================================================================
;		.ORG	SYSVARS
		.ORG	ACIA_BUFFERS_END
buffer_cmd:			.EXPORT		buffer_cmd
				.BYTE	0

		.ORG	buffer_cmd + 10h
buffer_parm1:		.EXPORT		buffer_parm1
				.BYTE	0

		.ORG	buffer_parm1 + 10h
buffer_parm1_val:	.EXPORT		buffer_parm1_val
				.BYTE	0

		.ORG	buffer_parm1_val + 10h
buffer_parm2:		.EXPORT		buffer_parm2
				.BYTE	0

		.ORG	buffer_parm2 + 10h
buffer_parm2_val:	.EXPORT		buffer_parm2_val
				.BYTE	0

		.ORG	buffer_parm2_val + 10h
buffer_pgm:		.EXPORT		    buffer_pgm
				.BYTE	0				; general buffer from programs

        .ORG	SYSVARS_END
		        .BYTE	0
        .END