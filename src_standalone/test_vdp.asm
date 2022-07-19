STACK_START     .EQU	$2000               ; Top of the dastaZ80's Stack location
STACK_END       .EQU    STACK_START + 31    ; Bottom of the dastaZ80's Stack location

VDP_DATA_PORT   .EQU	$98             ; VDP Data Port
VFP_CMND_PORT   .EQU    $99             ; VDP Command Port


        ld      SP, STACK_END           ; Set Stack address in RAM
        call    F_BIOS_VDP_RESET
        ld      HL, msg_krn_version
        call    F_KRN_VDP_WRSTR
loop:   jp      loop                    ; infinite loop

;------------------------------------------------------------------------------
F_BIOS_VDP_RESET
; Reset registers and clear VRAM
        call    F_BIOS_VDP_CLEAR_VRAM
        call    F_BIOS_VDP_SET_TEXT_MODE
        ret
;------------------------------------------------------------------------------
F_BIOS_VDP_CLEAR_VRAM:
; Set all 16 KB VRAM to 0
; To access VRAM, we send two 8-bit bytes (A0-A15)
;   bytes A0-A13 make up the address
;   byte A14 is 0 for reading, and 1 for writing
;   byte A15 must be 0

        ; Address $0000, with A14 for writing (i.e. $4000)
        ld      HL, $0000
        call    F_BIOS_VDP_SET_VRAM_ADDR_WR
        
        ld      A, $00                  ; Set zeros 64 * 256 = 16384
        ld      B, $40                  ; counter (64)
        ld      D, A                    ; sub-counter (256)
clear_vram:
        out     (VDP_DATA_PORT), A      ; set zero at VRAM address
        inc     D                       ; increment sub-counter
        jr      nz, clear_vram          ; did D flip back to $00? No, loop
        djnz    clear_vram              ; Yes, decrement B. Exit if B = 0, otherwise loop
;------------------------------------------------------------------------------
F_BIOS_VDP_SET_TEXT_MODE:
; Set a display mode to Text Mode

        ; Set Register 0 to $00 (Text Mode, External VDP Plane Disabled)
        ld      A, $00
        ld      B, $80                  ; Register 0
        call    F_BIOS_VDP_SET_NEXT_REG
        ; Set Register 1 to $D0 (16KB, Enable Display Blank, Disable Interrupts)
        ld      A, $D0
        call    F_BIOS_VDP_SET_NEXT_REG
        ; Set Register 2 to $02 (Address of Name Table in VRAM = 0x0800)
        ld      A, $02
        call    F_BIOS_VDP_SET_NEXT_REG
        ; Register 3 is ignored as text Mode doesn't use colour table
        inc     B
        ; Set Register 4 to $00 (Address of Pattern Table in VRAM = 0x0000)
        ld      A, $00
        add     A, $1F                  ; Offset for ASCII 32
        call    F_BIOS_VDP_SET_NEXT_REG
        ; Copy character set from ROM to VRAM
        call    F_BIOS_VDP_CHARSET_TO_VRAM
        ; Register 5 (Sprite Attribute Table) is ignored
        inc     B
        ; Register 6 (Sprite Pattern Table) is ignored
        inc     B
        ; Set Register 7 to $F5 (White text on Light Blue background)
        ld      A, $F5
        call    F_BIOS_VDP_SET_NEXT_REG
        ret
;------------------------------------------------------------------------------
F_BIOS_VDP_SET_VRAM_ADDR_WR:
; Set VRAM address
; To access VRAM, we send two 8-bit bytes (A0-A15)
;   bytes A0-A13 make up the address
;   byte A14 is 0 for reading, and 1 for writing
;   byte A15 must be 0
; IN <= HL = address
        ld      C, VFP_CMND_PORT
        set     6, H                    ; 1 for writing
        out     (C), L     ; send 1st byte (low)
        out     (C), H     ; send 2nd byte (high)
        ret
;------------------------------------------------------------------------------
F_BIOS_VDP_SET_NEXT_REG:
; Send t2o bytes to set a specific VDP register
; IN <= A = data for register
;       B = register number
; OUNT => B is incremented
        ld      C, VFP_CMND_PORT
        out     (C), A
        out     (C), B
        inc     B
        ret
;------------------------------------------------------------------------------
F_KRN_VDP_WRSTR:
; Output string to VDP screen
; Display a string of ASCII characters terminated with CR.
; HL = pointer to first character of the string
        ld      A, (HL)                 ; Get character of the string
        or      A                       ; is it 00h? (i.e. end of string)
        ret     z                       ; yes, then return
        out     (VDP_DATA_PORT), A      ; no, print it
        inc     HL                      ; pointer to next character of the string
        jr      F_KRN_VDP_WRSTR         ; repeat (until character = 00h)
        ret
;------------------------------------------------------------------------------
F_BIOS_VDP_CHARSET_TO_VRAM:
; Copy charset to VRAM
        ld      B, 95                   ; 95 characters (From ASCII 32 to 126)
        ld      HL, charset_8x8         ; HL points to charset in ROM
copychar:
        ld      C, 7                    ; 7 bytes per character
;TODO                                        ; 8th byte it's always $00
copycharbytes:
        ld      A, (HL)                 ; A points to byte within a character
        out     (VDP_DATA_PORT), A      ; send byte
        inc     HL                      ; point to next byte
        dec     C                       ; decrement byte counter
        jp      nz, copycharbytes       ; if didn't copy the 7 bytes, copy more
        ld      A, $00                  ; 8th byte it's always $00
        out     (VDP_DATA_PORT), A      ; send byte
        djnz    copychar                ; if didn't copy all chars, copy more
        ret
;==============================================================================
msg_krn_version:
        .BYTE   "Kernel v1.0.0", 0
;==============================================================================
charset_8x8:
        .BYTE $00,$00,$00,$00,$00,$00,$00 ; char 32: space
        .BYTE $20,$20,$20,$20,$20,$00,$20 ; char 33: !
        .BYTE $50,$50,$00,$00,$00,$00,$00 ; char 34: "
        .BYTE $50,$50,$f8,$50,$f8,$50,$50 ; char 35: #
        .BYTE $20,$78,$a0,$70,$28,$f0,$20 ; char 36: $
        .BYTE $c0,$c8,$10,$20,$40,$98,$18 ; char 37: %
        .BYTE $60,$90,$a0,$40,$a8,$90,$68 ; char 38: &
        .BYTE $60,$20,$40,$00,$00,$00,$00 ; char 39: '
        .BYTE $10,$20,$40,$40,$40,$20,$10 ; char 40: (
        .BYTE $40,$20,$10,$10,$10,$20,$40 ; char 41: )
        .BYTE $00,$20,$a8,$70,$a8,$20,$00 ; char 42: *
        .BYTE $00,$20,$20,$f8,$20,$20,$00 ; char 43: +
        .BYTE $00,$00,$00,$00,$60,$20,$40 ; char 44: ,
        .BYTE $00,$00,$00,$f8,$00,$00,$00 ; char 45: -
        .BYTE $00,$00,$00,$00,$00,$60,$60 ; char 46: .
        .BYTE $00,$08,$10,$20,$40,$80,$00 ; char 47: /
        .BYTE $70,$88,$98,$a8,$c8,$88,$70 ; char 48: 0
        .BYTE $20,$60,$20,$20,$20,$20,$70 ; char 49: 1
        .BYTE $70,$88,$08,$10,$20,$40,$f8 ; char 50: 2
        .BYTE $f8,$10,$20,$10,$08,$88,$70 ; char 51: 3
        .BYTE $10,$30,$50,$90,$f8,$10,$10 ; char 52: 4
        .BYTE $f8,$80,$f0,$08,$08,$88,$70 ; char 53: 5
        .BYTE $30,$40,$80,$f0,$88,$88,$70 ; char 54: 6
        .BYTE $f8,$08,$10,$20,$40,$40,$40 ; char 55: 7
        .BYTE $70,$88,$88,$70,$88,$88,$70 ; char 56: 8
        .BYTE $70,$88,$88,$78,$08,$10,$60 ; char 57: 9
        .BYTE $00,$30,$30,$00,$30,$30,$00 ; char 58: :
        .BYTE $00,$30,$30,$00,$30,$10,$20 ; char 59: ;
        .BYTE $10,$20,$40,$80,$40,$20,$10 ; char 60: <
        .BYTE $00,$00,$f8,$00,$f8,$00,$00 ; char 61: =
        .BYTE $40,$20,$10,$08,$10,$20,$40 ; char 62: >
        .BYTE $70,$88,$08,$10,$20,$00,$20 ; char 63: ?
        .BYTE $70,$88,$08,$68,$a8,$a8,$70 ; char 64: @
        .BYTE $70,$88,$88,$88,$f8,$88,$88 ; char 65: A
        .BYTE $f0,$88,$88,$f0,$88,$88,$f0 ; char 66: B
        .BYTE $70,$88,$80,$80,$80,$88,$70 ; char 67: C
        .BYTE $e0,$90,$88,$88,$88,$90,$e0 ; char 68: D
        .BYTE $f8,$80,$80,$f0,$80,$80,$f8 ; char 69: E
        .BYTE $f8,$80,$80,$f0,$80,$80,$80 ; char 70: F
        .BYTE $70,$88,$80,$b8,$88,$88,$78 ; char 71: G
        .BYTE $88,$88,$88,$f8,$88,$88,$88 ; char 72: H
        .BYTE $70,$20,$20,$20,$20,$20,$70 ; char 73: I
        .BYTE $38,$10,$10,$10,$10,$90,$60 ; char 74: J
        .BYTE $88,$90,$a0,$c0,$a0,$90,$88 ; char 75: K
        .BYTE $80,$80,$80,$80,$80,$80,$f8 ; char 76: L
        .BYTE $88,$d8,$a8,$a8,$88,$88,$88 ; char 77: M
        .BYTE $88,$c8,$a8,$98,$88,$88,$88 ; char 78: N
        .BYTE $70,$88,$88,$88,$88,$88,$70 ; char 79: O
        .BYTE $f0,$88,$88,$f0,$80,$80,$80 ; char 80: P
        .BYTE $70,$88,$88,$88,$a8,$90,$68 ; char 81: Q
        .BYTE $f0,$88,$88,$f0,$a0,$90,$88 ; char 82: R
        .BYTE $78,$80,$80,$70,$08,$08,$f0 ; char 83: S
        .BYTE $f8,$20,$20,$20,$20,$20,$20 ; char 84: T
        .BYTE $88,$88,$88,$88,$88,$88,$70 ; char 85: U
        .BYTE $88,$88,$88,$88,$88,$50,$20 ; char 86: V
        .BYTE $88,$88,$88,$88,$a8,$a8,$50 ; char 87: W
        .BYTE $88,$88,$50,$20,$50,$88,$88 ; char 88: X
        .BYTE $88,$88,$88,$50,$20,$20,$20 ; char 89: Y
        .BYTE $f8,$08,$10,$20,$40,$80,$f8 ; char 90: Z
        .BYTE $70,$40,$40,$40,$40,$40,$70 ; char 91: [
        .BYTE $00,$80,$40,$20,$10,$08,$00 ; char 92: \
        .BYTE $70,$10,$10,$10,$10,$10,$70 ; char 93: ]
        .BYTE $20,$50,$88,$00,$00,$00,$00 ; char 94: ^
        ; .BYTE $00,$00,$00,$00,$00,$00,$00,$FC ; char 95: _ (underscore)
        .BYTE $00,$00,$00,$00,$00,$00,$FC ; char 95: _ (underscore)
        .BYTE $40,$20,$10,$00,$00,$00,$00 ; char 96: `
        .BYTE $00,$00,$70,$08,$78,$88,$78 ; char 97: a
        .BYTE $80,$80,$80,$b0,$c8,$88,$f0 ; char 98: b
        .BYTE $00,$00,$70,$80,$80,$88,$70 ; char 99: c
        .BYTE $08,$08,$08,$68,$98,$88,$78 ; char 100: d
        .BYTE $00,$00,$70,$88,$f8,$80,$70 ; char 101: e
        .BYTE $30,$48,$40,$e0,$40,$40,$40 ; char 102: f
        .BYTE $00,$00,$78,$88,$78,$08,$70 ; char 103: g
        .BYTE $80,$80,$b0,$c8,$88,$88,$88 ; char 104: h
        .BYTE $20,$00,$20,$20,$20,$20,$20 ; char 105: i
        .BYTE $08,$00,$18,$08,$08,$88,$70 ; char 106: j
        .BYTE $80,$80,$90,$a0,$c0,$a0,$90 ; char 107: k
        .BYTE $60,$20,$20,$20,$20,$20,$70 ; char 108: l
        .BYTE $00,$00,$d0,$a8,$a8,$88,$88 ; char 109: m
        .BYTE $00,$00,$b0,$c8,$88,$88,$88 ; char 110: n
        .BYTE $00,$00,$70,$88,$88,$88,$70 ; char 111: o
        .BYTE $00,$00,$f0,$88,$f0,$80,$80 ; char 112: p
        .BYTE $00,$00,$78,$88,$78,$08,$08 ; char 113: q
        .BYTE $00,$00,$b0,$c8,$80,$80,$80 ; char 114: r
        .BYTE $00,$00,$70,$80,$70,$08,$f0 ; char 115: s
        .BYTE $40,$40,$e0,$40,$40,$48,$30 ; char 116: t
        .BYTE $00,$00,$88,$88,$88,$98,$68 ; char 117: u
        .BYTE $00,$00,$88,$88,$88,$50,$20 ; char 118: v
        .BYTE $00,$00,$88,$88,$a8,$a8,$50 ; char 119: w
        .BYTE $00,$00,$88,$50,$20,$50,$88 ; char 120: x
        .BYTE $00,$00,$88,$98,$68,$08,$70 ; char 121: y
        .BYTE $00,$00,$f8,$10,$20,$40,$f8 ; char 122: z
        .BYTE $10,$20,$20,$40,$20,$20,$10 ; char 123: {
        .BYTE $20,$20,$20,$20,$20,$20,$20 ; char 124: |
        .BYTE $20,$10,$10,$08,$10,$10,$20 ; char 125: }
        .BYTE $00,$28,$50,$00,$00,$00,$00 ; char 126: ~

;==============================================================================
; END of CODE
;==============================================================================
        .END