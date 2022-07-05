;******************************************************************************
; portmap_dastaZ80.inc
;
; Port Mapping to run on dastaZ80
; for dastaZ80's dzOS
; by David Asta (Jul 2018)
;
; Create a symbolic link to this file, with name portmappings.inc
;      ln -s portmap_dastaZ80.inc portmappings.inc
;
; Version 1.0.0
; Created on 03 Jul 2022
; Last Modification 03 Jul 2022
;******************************************************************************
; CHANGELOG
; 	-
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2022 David Asta
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
; Memory
;==============================================================================
; ROMRAM_PAGING           .EQU    $38

;==============================================================================
; SIO/2
;==============================================================================
SIO_CH_A_CONTROL        .EQU	$20
SIO_CH_A_DATA           .EQU	$21
SIO_CH_B_CONTROL        .EQU	$22
SIO_CH_B_DATA		    .EQU	$23

;==============================================================================
; CompactFlash
;==============================================================================
CFLASH_PORT				.EQU	$00