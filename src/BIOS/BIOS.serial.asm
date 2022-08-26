;******************************************************************************
; BIOS.serial.asm
;
; BIOS' Serial (SIO/2) routines
; for dastaZ80's dzOS
; by David Asta (June 2022)
; Adapted from original routines by Grant Searle 
;                                   at http://searle.hostei.com/grant/index.html
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
        jp      F_BIOS_SERIAL_CONOUT_B
;------------------------------------------------------------------------------
; Receive a character over Channel B
        .ORG    $0020
        jp      F_BIOS_SERIAL_CONIN_B
;------------------------------------------------------------------------------
; SIO INTerrupt Vector
        .ORG    $0060
        .DW	    serial_interrupt
serial_interrupt:
        push    AF
        push    HL
        ld      A, (SIO_PRIMARY_IO)
        cp      0
        jr      nz, serial_int_ch_b
serial_int_ch_a:
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

serial_int_ch_b:
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
BIOS_SERIAL_CONIN_A:
; OUT => A = character read from serial Channel A
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
BIOS_SERIAL_CONIN_B:
; OUT => A = character read from serial Channel B
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
        ; Seems to work fine without this check
        ; call  CKSIOA                    ; See if SIO channel A is finished transmitting
        sub     A
        out     (SIO_CH_A_CONTROL), A
        in      A, (SIO_CH_A_CONTROL)   ; Status byte D2=TX Buff Empty, D0=RX char ready	
        rrca                            ; Rotates RX status into Carry Flag,	
        bit     1, A                    ; Set Zero flag if still transmitting character
        jr      z, conoutA1             ; Loop until SIO flag signals ready
        pop     AF
        out     (SIO_CH_A_DATA), A      ; OUTput the character
        ret

;------------------------------------------------------------------------------
; Serial output Channel B
; IN <= A = character to be sent to the serial Channel B
BIOS_SERIAL_CONOUT_B:
        push    AF
conoutB1:
        ; Seems to work fine without this check
        ; call  CKSIOB                    ; See if SIO channel B is finished transmitting
        sub     A
        out     (SIO_CH_B_CONTROL), A
        in      A, (SIO_CH_B_CONTROL)   ; Status byte D2=TX Buff Empty, D0=RX char ready	
        rrca                            ; Rotates RX status into Carry Flag,	
        bit     1, A                    ; Set Zero flag if still transmitting character
        jr      z, conoutB1             ; Loop until SIO flag signals ready
        pop     AF
        out     (SIO_CH_B_DATA), A      ; OUTput the character
        ret

;------------------------------------------------------------------------------
; Filtered Character I/O
;------------------------------------------------------------------------------

; RDCHR:
;         rst     10h
;         cp      LF
;         jr      z, RDCHR                ; Ignore LF
;         cp      ESC
;         jr      nz, RDCHR1
;         ld      A, CTRLC                ; Change ESC to CTRL-C
; RDCHR1: ret

; WRCHR:
;         cp      CR
;         jr      z, WRCRLF               ; When CR, write CRLF
;         cp      CLS
;         jr      z,WR                    ; Allow write of "CLS"
;         cp      ' '                     ; Don't write out any other control codes
;         jr      c,NOWR                  ; ie. < space
; WR:     rst     08h
; NOWR:	ret

; WRCRLF:
;         ld      A, CR
;         rst     08h
;         ld      A, LF
;         rst     08h
;         ld      A, CR
;         ret

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
        ld      A, $00
        out     (SIO_CH_A_CONTROL), A   ; Write into WR0: Select WR0
        ld      A, $18
        out     (SIO_CH_A_CONTROL), A   ; Write into WR0: Channel Reset
        
        ld      A, $04
        out     (SIO_CH_A_CONTROL), A   ; Write into WR0: Select WR4
        ld      A, $C4
        out     (SIO_CH_A_CONTROL), A   ; Write into WR4: Select WR0X64 Clock Mode,
                                        ;                 8-Bit SYNC Character,
                                        ;                 1 Stop Bit/Character,
                                        ;                 Parity Odd,
                                        ;                 Parity Enable off
        
        ld      A, $01
        out     (SIO_CH_A_CONTROL), A   ; Write into WR0: Select WR1
        ld      A, $18
        out     (SIO_CH_A_CONTROL), A   ; Write into WR1: INT on All Rx Characters

        ld      A, $03
        out     (SIO_CH_A_CONTROL), A   ; Write into WR0: Select WR3
        ld      A, $E1
        out     (SIO_CH_A_CONTROL), A   ; Write into WR3: Rx 8 Bits/Character,
                                        ;                 Auto Enables,
                                        ;                 Rx Enable

        ld      A, $05
        out     (SIO_CH_A_CONTROL), A   ; Write into WR0: Select WR5
        ld      A, SIO_RTS_LOW
        out     (SIO_CH_A_CONTROL), A   ; Write into WR5: DTR,
                                        ;                 External SYNC Mode,
                                        ;                 Tx Enable,
                                        ;                 RTS
        ; Initialise SIO/2 Channel B
        ld      A, $00
        out     (SIO_CH_B_CONTROL), A   ; Write into WR0: Select WR0
        ld      A, $18
        out     (SIO_CH_B_CONTROL), A   ; Write into WR0: Channel Reset
        
        ld      A, $04
        out     (SIO_CH_B_CONTROL), A   ; Write into WR0: Select WR4
        ld      A, $C4
        out     (SIO_CH_B_CONTROL), A   ; Write into WR4: Select WR0X64 Clock Mode,
                                        ;                 8-Bit SYNC Character,
                                        ;                 1 Stop Bit/Character,
                                        ;                 Parity Odd,
                                        ;                 Parity Enable off
        ld      A, $01
        out     (SIO_CH_B_CONTROL), A   ; Write into WR0: Select WR1
        ld      A, $18
        out     (SIO_CH_B_CONTROL), A   ; Write into WR1: INT on All Rx Characters
        ; ld        A, 00000100b
        ; out     (SIO_CH_B_CONTROL), A   ; Write into WR1: no interrupt

        ld      A, $02
        out     (SIO_CH_B_CONTROL), A   ; Write into WR0: Select WR2
        ld      A, $60
        out     (SIO_CH_B_CONTROL), A   ; Write into WR2: Interrupt Vector Address = 60h

        ld      A, $03
        out     (SIO_CH_B_CONTROL), A   ; Write into WR0: Select WR3
        ld      A, $E1
        out     (SIO_CH_B_CONTROL), A   ; Write into WR3: Rx 8 Bits/Character,
                                        ;                 Auto Enables,
                                        ;                 Rx Enable
        ld      A, $05
        out     (SIO_CH_B_CONTROL), A   ; Write into WR0: Select WR5
        ld      A, SIO_RTS_LOW
        out     (SIO_CH_B_CONTROL), A   ; Write into WR5: DTR,
                                        ;                 External SYNC Mode,
                                        ;                 Tx Enable,
                                        ;                 RTS

        ; Set CPU to Interrupt mode 2
        ld      A, $00
        ld      I, A
        im      2
        ; And enable interrupts
        ei
        jp      F_BIOS_WBOOT

;==============================================================================
; END of CODE
;==============================================================================
        .ORG    INITSIO2_END
        .END	