;******************************************************************************
; equates.inc
;
; General Equates (.EQU)
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 24 Dec 2022
;******************************************************************************
; CHANGELOG
;   -
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

.NOLIST

#IFNDEF _equates_
#DEFINE _equates_

;==============================================================================
; Port mapping
;==============================================================================
VDP_VRAM                    .EQU    $10 ; TMS9918A VDP => A0 = 0 (Mode VRAM)
VDP_REG                     .EQU    $11 ; ^            => A0 = 1 (Mode Register)
PSG_REG                     .EQU    $20 ; AY-3-8912 PSG
PSG_DATA                    .EQU    $21 ; ^
ROMRAM_PAGING               .EQU    $38 ; ROM/RAM paging
JOY1_STAT                   .EQU    $40 ; Dual Digital Joystick Port
JOY2_STAT                   .EQU    $41 ; ^
SIO_CH_A_CONTROL            .EQU    $80 ; Zilog SIO/2
SIO_CH_A_DATA               .EQU    $81 ; ^
SIO_CH_B_CONTROL            .EQU    $82 ; ^
SIO_CH_B_DATA               .EQU    $83 ; ^

;==============================================================================
; ROM positions
;==============================================================================
INITSIO2_END                .EQU    $0215
KRN_START                   .EQU    $1340
KRN_DZOS_VERSION            .EQU    $26B7
CLI_START                   .EQU    $26C8
BOOTSTRAP_START             .EQU    $3A89
VDP_LOGO_NAME_START         .EQU    $3AB7
VDP_LOGO_PATT_START         .EQU    VDP_LOGO_NAME_START + 768
BIOS_JBLK_START             .EQU    $3E4A
BIOS_JBLK_END               .EQU    $3EFD
KRN_JBLK_START              .EQU    $3EFE
KRN_JBLK_END                .EQU    $3FFF
JBLKS_START_HRAM            .EQU    BIOS_JBLK_START + $8000
JBLKS_SIZE_HRAM             .EQU    KRN_JBLK_END - BIOS_JBLK_START

;==============================================================================
; RAM positions
;==============================================================================
STACK_START                 .EQU    $4000               ; Top of the dastaZ80's Stack location
STACK_END                   .EQU    STACK_START + 31    ; Bottom of the dastaZ80's Stack location

SYSVARS_START               .EQU    STACK_END + 1
SYSVARS_END                 .EQU    SYSVARS_START + 348

RESERVED_START              .EQU    SYSVARS_END + 1
RESERVED_END                .EQU    RESERVED_START + 157

DISK_BUFFER_START           .EQU    RESERVED_END + 1
DISK_BUFFER_END             .EQU    DISK_BUFFER_START + 511

FREERAM_START               .EQU    DISK_BUFFER_END + 1
FREERAM_END                 .EQU    $FFFF
FREERAM_TOTAL               .EQU    FREERAM_END - FREERAM_START + 1

START_HIGHRAM               .EQU    $8000

;==============================================================================
; Key codes over Serial
;==============================================================================
BSPACE                      .EQU    $08     ; Backspace
TAB                         .EQU    $09
LF                          .EQU    $0A     ; Line Feed
CR                          .EQU    $0D     ; Carriage Return
ESC                         .EQU    $1B     ; Escape
SPACE                       .EQU    $20     ; Space
DELETE                      .EQU    $7F     ; Delete
CLRSCR                      .EQU    $80     ; Break/Pause key (Clear Screen)

;==============================================================================
; SIO/2
;==============================================================================
SIO_BUFFER_SIZE             .EQU    $40
SIO_FULL_SIZE               .EQU    $30
SIO_EMPTY_SIZE              .EQU    5

SIO_RTS_HIGH                .EQU    $0E8
SIO_RTS_LOW	                .EQU    $0EA

; Write Registers
SIO_WR0                     .EQU    $00
SIO_WR1                     .EQU    $01
SIO_WR2                     .EQU    $02
SIO_WR3                     .EQU    $03
SIO_WR4                     .EQU    $04
SIO_WR5                     .EQU    $05

SIO_N81                     .EQU    $C4     ; 8 bits, no parity, 1 stop bit, 115,200 bps
SIO_ENRX                    .EQU    $C1     ; 8 bits per Rx character, disable Auto Enables (RTS/CTS flow control), enable RX
SIO_ENTX                    .EQU    $68     ; 8 bits per Tx character, enable TX, disable DTR & RTS
SIO_INT_ALLRX               .EQU    $1C     ; Interrupt on all Rx characters (parity irrelevant), enable Status Affects Vector
SIO_INT_VECT                .EQU    $90     ; SIO INTerrupt Vector
                                            ; The interrupt table is 16-bit,
                                            ;   therefore the start of the vector
                                            ;   table MUST be in a 16-bit boundary
                                            ;   (e.g. $10, $20, $30, $40, $50, $60, $70, $80, $90, $A0, ...)
SIO_CH_RESET                .EQU    $18     ; Channel Reset

;==============================================================================
; ANSI Terminal colours
;==============================================================================
ANSI_COLR_BLK               .EQU    0
ANSI_COLR_RED               .EQU    1
ANSI_COLR_GRN               .EQU    2
ANSI_COLR_YLW               .EQU    3
ANSI_COLR_BLU               .EQU    4
ANSI_COLR_MGT               .EQU    5
ANSI_COLR_CYA               .EQU    6
ANSI_COLR_WHT               .EQU    7
ANSI_COLR_GRY               .EQU    8

;==============================================================================
; dastaZ80 File System (DZFS )
;==============================================================================
DZFS_SIGNATURE              .EQU    $BAAB   ; in little-endian will become ABBA ;-)
DZFS_BYTES_PER_SECTOR       .EQU    $0200
DZFS_SECTORS_PER_BLOCK      .EQU    $40
; Superblock offsets
DZFS_SBLOCK_SIGNATURE       .EQU    DISK_BUFFER_START
DZFS_SBLOCK_NOTUSED         .EQU    DISK_BUFFER_START + $02
DZFS_SBLOCK_FSID            .EQU    DISK_BUFFER_START + $03
DZFS_SBLOCK_SERNUM          .EQU    DISK_BUFFER_START + $0B
DZFS_SBLOCK_NOTUSED2        .EQU    DISK_BUFFER_START + $0F
DZFS_SBLOCK_LABEL           .EQU    DISK_BUFFER_START + $10
DZFS_SBLOCK_DATECREA        .EQU    DISK_BUFFER_START + $20
DZFS_SBLOCK_DATECREA_DD     .EQU    DZFS_SBLOCK_DATECREA
DZFS_SBLOCK_DATECREA_MM     .EQU    DZFS_SBLOCK_DATECREA + 2
DZFS_SBLOCK_DATECREA_YYYY   .EQU    DZFS_SBLOCK_DATECREA + 4
DZFS_SBLOCK_TIMECREA        .EQU    DISK_BUFFER_START + $28
DZFS_SBLOCK_TIMECREA_HH     .EQU    DZFS_SBLOCK_TIMECREA
DZFS_SBLOCK_TIMECREA_MM     .EQU    DZFS_SBLOCK_TIMECREA + 2
DZFS_SBLOCK_TIMECREA_SS     .EQU    DZFS_SBLOCK_TIMECREA + 4
DZFS_SBLOCK_BYTESSEC        .EQU    DISK_BUFFER_START + $2E
DZFS_SBLOCK_SECBLOCK        .EQU    DISK_BUFFER_START + $30
DZFS_SBLOCK_NOTUSED3        .EQU    DISK_BUFFER_START + $31
DZFS_SBLOCK_COPYRIGHT       .EQU    DISK_BUFFER_START + $32
DZFS_SBLOCK_FILLER          .EQU    DISK_BUFFER_START + $65

;==============================================================================
; Arduino Serial Multi-Device Controller (ASMDC)
;==============================================================================
FDD_CMD_GET_STATUS          .EQU    $A0
FDD_CMD_GET_BUSY            .EQU    $A1
FDD_CMD_READ_SECTOR         .EQU    $A2
FDD_CMD_WRITE_SECTOR        .EQU    $A3
FDD_CMD_CHKDISKIN           .EQU    $A4     ; Checks if a disk is in th drive
FDD_CMD_CHKWPROTECT         .EQU    $A5     ; Checks if disk is Write Protected
FDD_CMD_SETYPE_DD           .EQU    $A6     ; Set drive as Double-density           ToDo
FDD_CMD_SETYPE_HD           .EQU    $A7     ; Set drive as High-density (default)   ToDo
FDD_CMD_FORMAT              .EQU    $A8     ; Low-level format (no file system)
FDD_CMD_MOTOR_ON            .EQU    $AA     ; Turns the FDD motor ON
FDD_CMD_MOTOR_OFF           .EQU    $AB     ; Turns the FDD motor OFF

SD_CMD_GET_STATUS           .EQU    $B0
SD_CMD_GET_BUSY             .EQU    $B1
SD_CMD_READ_SECTOR          .EQU    $B2
SD_CMD_WRITE_SECTOR         .EQU    $B3
SD_CMD_PARK_DISKS           .EQU    $B4
SD_CMD_MOUNT_DISK           .EQU    $B5
SD_CMD_GET_IMG_INFO         .EQU    $B6

RTC_CMD_GET_INFO            .EQU    $C0
RTC_CMD_GET_BATT            .EQU    $C1
RTC_CMD_GET_DATE            .EQU    $C2
RTC_CMD_GET_TIME            .EQU    $C3
RTC_CMD_SET_DATE            .EQU    $C4
RTC_CMD_SET_TIME            .EQU    $C5
RTC_CMD_GET_TEMP            .EQU    $C6

NVRAM_CMD_DETECT            .EQU    $D0

;==============================================================================
; TMS9918A VDP
;==============================================================================
VDP_MODE_TXT                .EQU    $0      ; Text Mode
VDP_MODE_G1                 .EQU    $1      ; Graphics I Mode
VDP_MODE_G2                 .EQU    $2      ; Graphics II Mode
VDP_MODE_MM                 .EQU    $3      ; Multicolour Mode
VDP_MODE_G2BM               .EQU    $4      ; Graphics II Mode Bitmapped

; Text Mode
VDP_TXT_REG_0               .EQU    $00     ; Text Mode, No External Video
VDP_TXT_REG_1               .EQU    $F0     ; 16K, Enable Disp., Enable Int., M1, 8x8 Sprites, Mag. Off
VDP_TXT_REG_2               .EQU    $02     ; Name Table = $0800
VDP_TXT_REG_3               .EQU    $00     ; Colour Table not used
VDP_TXT_REG_4               .EQU    $00     ; Pattern Table = $0000
VDP_TXT_REG_5               .EQU    $00     ; Sprites not allowed in this mode
VDP_TXT_REG_6               .EQU    $00     ; Sprites not allowed in this mode
VDP_TXT_REG_7               .EQU    $F5     ; White text on Light Blue Background
VDP_TXT_PATT_TAB            .EQU    $0000   ; Pattern Table
; VDP_TXT_SPRP_TAB            .EQU    $0000   ; Sprites not allowed in this mode
; VDP_TXT_COLR_TAB            .EQU    $0000   ; Colour Table not used
VDP_TXT_NAME_TAB            .EQU    $0800   ; Name Table
; VDP_TXT_SPRA_TAB            .EQU    $1000   ; Sprites not allowed in this mode

; Graphics I Mode
VDP_G1_REG_0                .EQU    $00     ; Graphics I Mode, No External Video
VDP_G1_REG_1                .EQU    $E0     ; 16K, Enable Disp., Enable Int., 8x8 Sprites, Mag. Off
VDP_G1_REG_2                .EQU    $05     ; Name Table = $1400
VDP_G1_REG_3                .EQU    $80     ; Colour Table = $2000
VDP_G1_REG_4                .EQU    $01     ; Pattern Table = $0800
VDP_G1_REG_5                .EQU    $20     ; Sprite Attribute Table = $1000
VDP_G1_REG_6                .EQU    $00     ; Sprite Pattern Table = $0000
VDP_G1_REG_7                .EQU    $04     ; Backdrop colour = Black
VDP_G1_PATT_TAB             .EQU    $0800   ; Pattern Table
VDP_G1_SPRP_TAB             .EQU    $1000   ; Sprite Pattern Table
VDP_G1_COLR_TAB             .EQU    $2000   ; Colour Table
VDP_G1_NAME_TAB             .EQU    $1400   ; Name Table
VDP_G1_SPRA_TAB             .EQU    $1000   ; Sprite Attribute Table
VDP_G1_DEFT_TBC             .EQU    $F1     ; Default Text Background Colour

; Graphics II Mode and Graphics II Mode Bitmapped
VDP_G2_REG_0                .EQU    $02     ; Graphics II Mode, No External Video
VDP_G2_REG_1                .EQU    $E0     ; 16K, Enable Disp., Enable Int., 8x8 Sprites, Mag. Off
; VDP_G2_REG_1                .EQU    $C0     ; 16K, Enable Disp., Disable Int., 8x8 Sprites, Mag. Off
VDP_G2_REG_2                .EQU    $0E     ; Name Table = $3800
VDP_G2_REG_3                .EQU    $FF     ; Colour Table = $2000
VDP_G2_REG_4                .EQU    $03     ; Pattern Table = $0000
VDP_G2_REG_5                .EQU    $76     ; Sprite Attribute Table = $3B00
VDP_G2_REG_6                .EQU    $03     ; Sprite Pattern Table = $1800
VDP_G2_REG_7                .EQU    $0F     ; Backdrop colour = White
VDP_G2_PATT_TAB             .EQU    $0000   ; Pattern Table
VDP_G2_SPRP_TAB             .EQU    $1800   ; Sprite Pattern Table
VDP_G2_COLR_TAB             .EQU    $2000   ; Colour Table
VDP_G2_NAME_TAB             .EQU    $3800   ; Name Table
VDP_G2_SPRA_TAB             .EQU    $3B00   ; Sprite Attribute Table
VDP_G2_DEFT_TBC             .EQU    $F1     ; Default Text Background Colour

; Multicolour Mode
VDP_MM_REG_0                .EQU    $00     ; Multicolour Mode, No External Video
VDP_MM_REG_1                .EQU    $E8     ; 16K, Enable Disp., Enable Int., M2, 8x8 Sprites, Mag. Off
VDP_MM_REG_2                .EQU    $05     ; Name Table = $1400
VDP_MM_REG_3                .EQU    $00     ; Colour Table not used
VDP_MM_REG_4                .EQU    $01     ; Pattern Table = $0800
VDP_MM_REG_5                .EQU    $20     ; Sprite Attribute Table = $1000
VDP_MM_REG_6                .EQU    $00     ; Sprite Pattern Table = $0000
VDP_MM_REG_7                .EQU    $04     ; Backdrop colour = Dark Blue
VDP_MM_PATT_TAB             .EQU    $0800   ; Pattern Table
VDP_MM_SPRP_TAB             .EQU    $0000   ; Sprite Pattern Table
; VDP_MM_COLR_TAB             .EQU    $0000   ; Colour Table not used
VDP_MM_NAME_TAB             .EQU    $1400   ; Name Table
VDP_MM_SPRA_TAB             .EQU    $1000   ; Sprite Attribute Table

; Colours
VDP_COLR_TRNSP              .EQU    $0      ; Transparent
VDP_COLR_BLACK              .EQU    $1      ; Black
VDP_COLR_M_GRN              .EQU    $2      ; Medium Green
VDP_COLR_L_GRN              .EQU    $3      ; Light Green
VDP_COLR_D_BLU              .EQU    $4      ; Dark Blue
VDP_COLR_L_BLU              .EQU    $5      ; Light Blue
VDP_COLR_D_RED              .EQU    $6      ; Dark Red
VDP_COLR_CYAN               .EQU    $7      ; Cyan
VDP_COLR_M_RED              .EQU    $8      ; Medium Red
VDP_COLR_L_RED              .EQU    $9      ; Light Red
VDP_COLR_D_YLW              .EQU    $A      ; Dark Yellow
VDP_COLR_L_YLW              .EQU    $B      ; Light Yellow
VDP_COLR_D_GRN              .EQU    $C      ; Dark Green
VDP_COLR_MGNTA              .EQU    $D      ; Magenta
VDP_COLR_GREY               .EQU    $E      ; Grey
VDP_COLR_WHITE              .EQU    $F      ; White

;==============================================================================
; AY-3-8912 PSG
;==============================================================================
PSG_R0_CH_A_FTUNE           .EQU    $0      ; Channel A Tone Period (8-bit Fine Tune A)
PSG_R1_CH_A_CTUNE           .EQU    $1      ; Channel A Tone Period (4-bit Coarse Tune A)
PSG_R2_CH_B_FTUNE           .EQU    $2      ; Channel A Tone Period (8-bit Fine Tune B)
PSG_R3_CH_B_CTUNE           .EQU    $3      ; Channel A Tone Period (4-bit Coarse Tune B)
PSG_R4_CH_C_FTUNE           .EQU    $4      ; Channel A Tone Period (8-bit Fine Tune C)
PSG_R5_CH_C_CTUNE           .EQU    $5      ; Channel A Tone Period (4-bit Coarse Tune C)
PSG_R6_NOISE_PERIOD         .EQU    $6      ; Noise Period (5-bit Period Control)
PSG_R7_MIXER                .EQU    $7      ; Enable ABC Noise / ABC Tone
PSG_R10_CH_A_AMPL           .EQU    $8      ; Channel A Amplitude
PSG_R11_CH_B_AMPL           .EQU    $9      ; Channel B Amplitude
PSG_R12_CH_C_AMPL           .EQU    $A      ; Channel C Amplitude
PSG_R13_ENV_FTUNE           .EQU    $B      ; Envelope Period (8-bit Fine Tune E)
PSG_R14_ENV_CTUNE           .EQU    $C      ; Envelope Period (8-bit Coarse Tune E)
PSG_R15_ENV_SHAPCYC         .EQU    $D      ; Envelope Shape/Cycle
PSG_R16_IO_A_DATA           .EQU    $E      ; I/O Port A Data Store (8-bit parallel)
; PSG_R17_IO_B_DATA           .EQU    $F      ; AY-3-8912 does not have I/O Port B

;==============================================================================
; Dual Digital Joystick Port
;==============================================================================
JOY_NONE                    .EQU    $00
JOY_UP                      .EQU    $01
JOY_DOWN                    .EQU    $02
JOY_LEFT                    .EQU    $04
JOY_RIGHT                   .EQU    $08
JOY_FIRE                    .EQU    $10


#ENDIF

.LIST