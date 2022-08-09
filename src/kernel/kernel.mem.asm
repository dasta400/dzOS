;******************************************************************************
; kernel.mem.asm
;
; Kernel's Memory routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 2.0.0
; Created on 08 May 2019
; Last Modification 03 Jul 2022
;******************************************************************************
; CHANGELOG
;   - 20 Jun 2022: Shorter and faster routine for F_KRN_SETMEMRNG
;   - 03 Jul 2022: Added F_KRN_WHICH_RAMSIZE
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; MIT License
; 
; Copyright (c) 2019 David Asta
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
; Memory Routines
;==============================================================================
;------------------------------------------------------------------------------
KRN_SETMEMRNG:
; Sets a value in a memory position range
; IN <= HL = start position
;       BC = number of bytes to set
;       A value to set
        ld      (HL), A
        cpi
        jp      pe, KRN_SETMEMRNG
        ret
;------------------------------------------------------------------------------
KRN_WHICH_RAMSIZE:
; Check how much RAM we have
; OUT => Z set for 64 KB, cleare for 32 KB

; Test for 64 KB
        ; Write 1 byte to $FFFF
        ld      A, $AB
        ld      ($FFFF), A
        xor     A
        ; Read it back to see if it was stored
        ld      A, ($FFFF)
        cp      $AB
        ret
;------------------------------------------------------------------------------
KRN_COPYMEM512:
; Copy bytes from one area of memory to another, in group of 512 bytes (i.e. max. 512 bytes).
; If less than 512 bytes are to be copied, the rest will be filled with zeros.
; IN <= HL = start address (from where to copy the bytes)
;       DE = end address (to where to copy the bytes)
;       BC = number of bytes to copy (MUST be less or equal to 512)
        push    BC                      ; backup bytes counter
        ldir                            ; copy bytes from start to end
        ; if it were less than 512 bytes,
        ;   copy zeros until 512 are copied
        ld      HL, 512
        pop     BC                      ; restore bytes counter
        or      A                       ; clear Carry Flag before SBC
        sbc     HL, BC                  ; HL = remaining bytes to copy
        ld      B, H                    ; copy HL
        ld      C, L                    ;   to BC
copy512rest:
        ld      A, B                    ; check if BC
        or      C                       ;   has reached zero
        jp      z, copy512end           ; yes, we copied all 512 bytes
        ld      A, 0                    ; no,
        ld      (DE), A                 ;   copy zeros
        inc     DE                      ;   to the reamining addresses
        dec     BC                      ;   until counter reaches zero
        jp      copy512rest             ;   which means we copied 512
copy512end:
        ret
;------------------------------------------------------------------------------
KRN_SHIFT_BYTES_BY1:
; Moves bytes (by one) to the right
; and replaces first byte with bytes counter
; IN <= HL = address of last byte to move
;       B = number of bytes to move
        push    BC                      ; backup bytes counter
        ld      D, H
        ld      E, L                    ; DE = HL
        inc     DE                      ; DE = HL + 1
shift_loop:
        ld      A, (HL)                 ; get byte at HL
        ld      (DE), A                 ; copy it at HL + 1
        dec     HL                      ; point to previous byte
        dec     DE                      ; point to previous byte + 1
        djnz    shift_loop              ; loop if there are more bytes to move
        pop     BC                      ; restore bytes counter
        ld      A, B                    ; and store it
        ld      (DE), A                 ;   in first byte
        ret
;------------------------------------------------------------------------------
KRN_CLEAR_MEMAREA:
; Clears (with zeros) a number of bytes, starting at a specified address
; Maximum 256 bytes can be cleared.
; IN <= IX = first byte to clear
;       B = number of bytes to clear
        ld      A, 0
loop_clrmem:
        ld      (IX), A
        inc     IX
        djnz    loop_clrmem
        ret
;------------------------------------------------------------------------------
KRN_CLEAR_CFBUFFER:
; Clears (with zeros) the CF Card Buffer
        ld      IX, CF_BUFFER_START
        ld      B, 255
        call    F_KRN_CLEAR_MEMAREA
        ld      B, 255
        call    F_KRN_CLEAR_MEMAREA
        ld      B, 2
        call    F_KRN_CLEAR_MEMAREA
        ret