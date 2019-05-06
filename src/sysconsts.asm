;******************************************************************************
; sysconsts.asm
;
; System Constants
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

        .ORG    SYSCONSTS_START

BIOS_BUILD:			.EXPORT		BIOS_BUILD
				.BYTE	0, 0
BIOS_STATUS:        .EXPORT     BIOS_STATUS
                .BYTE   "a "             ; a = alpha / b = beta / rc = Release Candidate / st = Stable
KERNEL_BUILD:		.EXPORT		KERNEL_BUILD
				.BYTE	0, 0
KERNEL_STATUS:      .EXPORT		KERNEL_STATUS
				.BYTE	"a "            ; a = alpha / b = beta / rc = Release Candidate / st = Stable
CLI_BUILD:			.EXPORT		CLI_BUILD
				.BYTE	0, 0
CLI_STATUS          .EXPORT     CLI_STATUS
                .BYTE   "a "            ; a = alpha / b = beta / rc = Release Candidate / st = Stable

;==============================================================================
; END of CODE
;==============================================================================
		.ORG	SYSCONSTS_END
				.BYTE	0
		.END