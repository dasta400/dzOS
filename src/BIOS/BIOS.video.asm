;******************************************************************************
; BIOS.video.asm
;
; BIOS' Video routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 08 May 2019
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
; Video Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_CLRSCR:			.EXPORT		F_BIOS_CLRSCR
; Clear all contents from the screen
		ret
;------------------------------------------------------------------------------
F_BIOS_CONIN:			.EXPORT		F_BIOS_CONIN
; Console input character
; Read character from Console and store it in register A.
; IN <= None
; OUT => A received character
		rst		10h						; get character in A, using subroutine ininitACIA.asm
		ret
;------------------------------------------------------------------------------
F_BIOS_CONOUT:			.EXPORT		F_BIOS_CONOUT
; Console output character
; Write the character in register A to the Console.
; IN <= A character to write
; OUT => None
		rst		08h						; print character in A, using subroutine ininitACIA.asm
		ret