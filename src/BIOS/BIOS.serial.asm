;******************************************************************************
; BIOS.serial.asm
;
; BIOS' Serial (SIO/2) routines
; for dastaZ80's dzOS
; by David Asta (June 2022)
; Adapted from original routines by Grant Searle 
;                                   at http://searle.hostei.com/grant/index.html
; No need for SIO_PRIMARY_IO anymore, as it jumps to the corresponding subroutine
;   based on the Status Affects Vector (D2). 
;
; IMPORTANT: Adding code to this file requires changing INITSIO2_END in equates.inc
;
; Version 1.0.0
; Created on 04 Jun 2022
; Last Modification 04 Jun 2022
;******************************************************************************
; CHANGELOG
;  -
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

; Restarts are not used directly by dzOS,
; but are kept for compatibility with for example MS BASIC
;------------------------------------------------------------------------------
; Transmit a character over Channel A
        .ORG    $0008
        jp      F_BIOS_SERIAL_CONOUT_A
;------------------------------------------------------------------------------
; Receive a character over Channel A
        .ORG    $0010
        jp      F_BIOS_SERIAL_CONIN_A
;------------------------------------------------------------------------------
; Transmit a character over Channel B
        .ORG    $0018
        jp      F_BIOS_SERIAL_CKINCHAR_A
;------------------------------------------------------------------------------
; Receive a character over Channel B
        .ORG    $0020
;        jp      F_BIOS_SERIAL_CONIN_B

;------------------------------------------------------------------------------
; SIO INTerrupt Vector
        .ORG    SIO_INT_VECT
        .WORD   int_chB_60              ; Ch B Transmit Buffer Empty
        .ORG    SIO_INT_VECT + $2
        .WORD   int_chB_62              ; Ch B External/Status Change
        .ORG    SIO_INT_VECT + $4
        .WORD   int_chB_64              ; Ch B Receive Character Available
        .ORG    SIO_INT_VECT + $6
        .WORD   int_chB_66              ; Ch B Special Receive Condition
        .ORG    SIO_INT_VECT + $8
        .WORD   int_chA_68              ; Ch A Transmit Buffer Empty
        .ORG    SIO_INT_VECT + $A
        .WORD   int_chA_6A              ; Ch A External/Status Change
        .ORG    SIO_INT_VECT + $C
        .WORD   int_chA_6C              ; Ch A Receive Character Available
        .ORG    SIO_INT_VECT + $E
        .WORD   int_chA_6E              ; Ch A Special Receive Condition

;------------------------------------------------------------------------------
int_chB_60:
        nop
        ei
        reti
int_chB_62:
        nop
        ei
        reti
int_chB_66:
        nop
        ei
        reti
int_chA_68:
        nop
        ei
        reti
int_chA_6A:
        nop
        ei
        reti
int_chA_6E:
        nop
        ei
        reti

;------------------------------------------------------------------------------
; Ch A Receive Character Available
int_chA_6C:
        push    AF
        push    HL
        ld      HL, (SIO_CH_A_IN_PTR)
        inc     HL
        ld      A, L
        cp      (SIO_CH_A_BUFFER + SIO_BUFFER_SIZE) & $FF
        jr      nz, not_A_wrap
        ld      HL, SIO_CH_A_BUFFER
not_A_wrap:
        ld      (SIO_CH_A_IN_PTR), HL
        in      A, (SIO_CH_A_DATA)
        ld      (HL), A
        ld      A,  (SIO_CH_A_BUFFER_USED)
        inc     A
        ld      (SIO_CH_A_BUFFER_USED), A
        cp      SIO_FULL_SIZE
        jr      c, rts_ch_a
        ld      A, $05
        out     (SIO_CH_A_CONTROL), A
        ld      A, SIO_RTS_HIGH
        out     (SIO_CH_A_CONTROL), A
rts_ch_a:
        pop     HL
        pop     AF
        ei
        reti

;------------------------------------------------------------------------------
; Ch B Receive Character Available
int_chB_64:
        push    AF
        push    HL
        ld      HL, (SIO_CH_B_IN_PTR)
        inc     HL
        ld      A, L
        cp      (SIO_CH_B_BUFFER + SIO_BUFFER_SIZE) & $FF
        jr      nz, not_B_wrap
        ld      HL, SIO_CH_B_BUFFER
not_B_wrap:
        ld      (SIO_CH_B_IN_PTR), HL
        in      A, (SIO_CH_B_DATA)
        ld      (HL), A
        ld      A, (SIO_CH_B_BUFFER_USED)
        inc     A
        ld      (SIO_CH_B_BUFFER_USED), A
        cp      SIO_FULL_SIZE
        jr      c, rts_ch_b
        ld      A, $05
        out     (SIO_CH_B_CONTROL), A
        ld      A, SIO_RTS_HIGH
        out     (SIO_CH_B_CONTROL), A
rts_ch_b:
        pop     HL
        pop     AF
        ei
        reti

;------------------------------------------------------------------------------
; Serial input Channel A
; OUT => A = character read from serial Channel A
BIOS_SERIAL_CONIN_A:
        push    HL
waitForCharA:
        ld      A, (SIO_CH_A_BUFFER_USED)
        cp      $00
        jr      z, waitForCharA
        ld      HL, (SIO_CH_A_RD_PTR)
        inc     HL
        ld      A, L
        cp      (SIO_CH_A_BUFFER + SIO_BUFFER_SIZE) & $FF
        jr      nz, notRdWrapA
        ld      HL, SIO_CH_A_BUFFER
notRdWrapA:
        di
        ld      (SIO_CH_A_RD_PTR), HL
        ld      A, (SIO_CH_A_BUFFER_USED)
        dec     A
        ld      (SIO_CH_A_BUFFER_USED), A
        cp      SIO_EMPTY_SIZE
        jr      nc, rtsA1
        ld      A, $05
        out     (SIO_CH_A_CONTROL), A
        ld      A, SIO_RTS_LOW
        out     (SIO_CH_A_CONTROL), A
rtsA1:
        ld      A, (HL)
        ei
        pop     HL
        ret

;------------------------------------------------------------------------------
; Serial input Channel B
; OUT => A = character read from serial Channel B
BIOS_SERIAL_CONIN_B:
        push    HL
waitForCharB:
        ld      A, (SIO_CH_B_BUFFER_USED)
        cp      $00
        jr      z, waitForCharB
        ld      HL, (SIO_CH_B_RD_PTR)
        inc     HL
        ld      A, L
        cp      (SIO_CH_B_BUFFER + SIO_BUFFER_SIZE) & $FF
        jr      nz, notRdWrapB
        ld      HL, SIO_CH_B_BUFFER
notRdWrapB:
        di
        ld      (SIO_CH_B_RD_PTR), HL
        ld      A, (SIO_CH_B_BUFFER_USED)
        dec     A
        ld      (SIO_CH_B_BUFFER_USED), A
        cp      SIO_EMPTY_SIZE
        jr      nc, rtsB1
        ld      A, $05
        out     (SIO_CH_B_CONTROL), A
        ld      A, SIO_RTS_LOW
        out     (SIO_CH_B_CONTROL), A
rtsB1:
        ld      A, (HL)
        ei
        pop     HL
        ret

;------------------------------------------------------------------------------
; Serial output Channel A
; IN <= A = character to be sent to the serial Channel A
BIOS_SERIAL_CONOUT_A:
        push    AF
conoutA1:
        ; Check if still transmitting
        sub     A
        out     (SIO_CH_A_CONTROL), A
        in      A, (SIO_CH_A_CONTROL)   ; Status byte D2=TX Buff Empty, D0=RX char ready	
        rrca                            ; Rotates RX status into Carry Flag,	
        bit     1, A                    ; Set Zero flag if still transmitting character
        jr      z, conoutA1             ; Loop until SIO flag signals ready
        ; No transmitting, then send
        pop     AF
        out     (SIO_CH_A_DATA), A      ; OUTput the character
        ret

;------------------------------------------------------------------------------
; Serial output Channel B
; IN <= A = character to be sent to the serial Channel B
BIOS_SERIAL_CONOUT_B:
        push    AF
conoutB1:
        ; Check if still transmitting
        sub     A
        out     (SIO_CH_B_CONTROL), A
        in      A, (SIO_CH_B_CONTROL)   ; Status byte D2=TX Buff Empty, D0=RX char ready	
        rrca                            ; Rotates RX status into Carry Flag,	
        bit     1, A                    ; Set Zero flag if still transmitting character
        jr      z, conoutB1             ; Loop until SIO flag signals ready
        ; No transmitting, then send
        pop     AF
        out     (SIO_CH_B_DATA), A      ; OUTput the character
        ret

;------------------------------------------------------------------------------
; Initialise SIO/2
BIOS_SERIAL_INIT:
        ; Initialise buffers
        ld      HL, SIO_CH_A_BUFFER
        ld      (SIO_CH_A_IN_PTR), HL
        ld      (SIO_CH_A_RD_PTR), HL

        ld      HL, SIO_CH_B_BUFFER
        ld      (SIO_CH_B_IN_PTR), HL
        ld      (SIO_CH_B_RD_PTR), HL

        xor     A
        ld      (SIO_CH_A_BUFFER_USED), A
        ld      (SIO_CH_B_BUFFER_USED), A

        ; Initialise SIO/2 Channel A
        ld      A, SIO_WR0
        out     (SIO_CH_A_CONTROL), A   ; Select WR0
        ld      A, SIO_CH_RESET
        out     (SIO_CH_A_CONTROL), A   ; Channel Reset

        nop                             ; The manual says "After a Z80 SIO 
                                        ; Channel Reset, add four system clock
                                        ; cycles before additional commands or
                                        ; controls write to that channel."

        ld      A, SIO_WR4
        out     (SIO_CH_A_CONTROL), A   ; Select WR4
        ld      A, SIO_N81
        out     (SIO_CH_A_CONTROL), A   ; 8 bits, no parity, 1 stop bit, 115,200 bps

        ld      A, SIO_WR1
        out     (SIO_CH_A_CONTROL), A   ; Select WR1
        ld      A, SIO_INT_ALLRX
        out     (SIO_CH_A_CONTROL), A   ; Interrupt on all Rx characters (parity irrelevant)

        ld      A, SIO_WR3
        out     (SIO_CH_A_CONTROL), A   ; Select WR3
        ld      A, SIO_ENRX
        out     (SIO_CH_A_CONTROL), A   ; 8 bits per Rx character, 
                                        ; disable Auto Enables (RTS/CTS flow control),
                                        ; enable RX

        ld      A, SIO_WR5
        out     (SIO_CH_A_CONTROL), A   ; Select WR5
        ld      A, SIO_ENTX
        out     (SIO_CH_A_CONTROL), A   ; 8 bits per Tx character, 
                                        ; enable TX, disable DTR & RTS

        ; Initialise SIO/2 Channel B
        ld      A, SIO_WR0
        out     (SIO_CH_B_CONTROL), A   ; Select WR0
        ld      A, SIO_CH_RESET
        out     (SIO_CH_B_CONTROL), A   ; Channel Reset

        nop                             ; The manual says "After a Z80 SIO 
                                        ; Channel Reset, add four system clock
                                        ; cycles before additional commands or
                                        ; controls write to that channel."
        ld      A, SIO_WR4
        out     (SIO_CH_B_CONTROL), A   ; Select WR4
        ld      A, SIO_N81
        out     (SIO_CH_B_CONTROL), A   ; 8 bits, no parity, 1 stop bit, 115,200 bps

        ld      A, SIO_WR1
        out     (SIO_CH_B_CONTROL), A   ; Select WR1
        ld      A, SIO_INT_ALLRX
        out     (SIO_CH_B_CONTROL), A   ; INT on All Rx Characters

        ld      A, SIO_WR2
        out     (SIO_CH_B_CONTROL), A   ; Select WR2
        ld      A, SIO_INT_VECT
        out     (SIO_CH_B_CONTROL), A   ; Interrupt Vector Table

        ld      A, SIO_WR3
        out     (SIO_CH_B_CONTROL), A   ; Select WR3
        ld      A, SIO_ENRX
        out     (SIO_CH_B_CONTROL), A   ; 8 bits per Rx character, 
                                        ; disable Auto Enables (RTS/CTS flow control),
                                        ; enable RX
        ld      A, SIO_WR5
        out     (SIO_CH_B_CONTROL), A   ; Select WR5
        ld      A, SIO_ENTX
        out     (SIO_CH_B_CONTROL), A   ; 8 bits per Tx character, 
                                        ; enable TX, disable DTR & RTS

        ; Set CPU to Interrupt mode 2
        ld      A, $00
        ld      I, A
        im      2
        ; And enable interrupts
        ei
        jp      F_BIOS_WBOOT

;------------------------------------------------------------------------------
BIOS_SERIAL_CKINCHAR_A:
        ld      A, (SIO_CH_A_BUFFER_USED)
        cp      $0
        ret
_ckinchara_print:
        ld      A, (HL)                 ; Get character
        or      A                       ; Is it $00?
        ret     z                       ; Then RETurn on terminator
        rst     08h                     ; Print it
        inc     HL                      ; Next character
        jr      _ckinchara_print        ; COntinue until $00
        ret

;==============================================================================
; END of CODE
;==============================================================================
        .ORG    INITSIO2_END
        .END	