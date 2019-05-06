;******************************************************************************
; kernel_jblks.asm
;
; Kernel Jumpblocks
; for dastaZ80's dzOS
; by David Asta (Apr 2019)
;
; Version 1.0.0
; Created on 25 Apr 2019
; Last Modification 25 Apr 2019
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
#include "exp/kernel.exp"

		    .ORG	KRN_JBLK_START

        jp      F_KRN_WRSTR
        jp      F_KRN_RDCHARECHO
        jp      F_KRN_SETMEMRNG

        .ORG	KRN_JBLK_END
				        .BYTE	0
        .END