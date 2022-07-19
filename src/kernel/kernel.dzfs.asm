;******************************************************************************
; kernel.dzfs.asm
;
; DZFS (DastaZ File System)'s routines
; for dastaZ80's dzOS
; by David Asta (Jun 2022)
;
; Version 1.0.0
; Created on 08 Jun 2022
; Last Modification 08 Jun 2022
;******************************************************************************
; CHANGELOG
;     -
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
F_KRN_DZFS_READ_SUPERBLOCK:     .EXPORT     F_KRN_DZFS_READ_SUPERBLOCK
; reads the Superblock (512 bytes) at Sector 0
        ; read 512 bytes from Sector 0 into CF buffer in RAM
        ld      DE, 0
        ld      BC, 0
        call    F_BIOS_CF_READ_SEC

        ; Check that the sector is a Superblock
        ; $20-$21 must be AB BA
        ld      A, (CF_SBLOCK_SIGNATURE)
        cp      $AB
        jp      nz, error_signature
        ld      A, (CF_SBLOCK_SIGNATURE + 1)
        cp      $BA
        jp      nz, error_signature

        ; change flag in SYSVARS
        ld      A, $FF
        ld      (CF_is_formatted), A

        ; Set partition 0 as default
        ld      A, 0
        ld      (CF_cur_partition), A
        ret

error_signature:
        ; Superblock didn't have the correct signature
        ; change flag in SYSVARS
        ld      A, $00
        ld      (CF_is_formatted), A
        ; Show a message telling that the disk is unformatted
        ld      HL, msg_unformatted
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_READ_BAT_SECTOR:     .EXPORT     F_KRN_DZFS_READ_BAT_SECTOR
; Read a BAT Sector into RAM buffer
; IN <= value stored in SYSVAR's CF_cur_sector
        ; ld      A, 1
        ; ld      (CF_cur_sector), A
        ; ld      A, 0
        ; ld      (CF_cur_sector + 1), A
load_sector:
        ld      HL, (CF_cur_sector)
        ld      BC, 0
        call    F_KRN_DZFS_SEC2BUFFER    ; load sector into RAM buffer

        ; call    F_BIOS_CF_READ_SEC
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_BATENTRY2BUFFER:     .EXPORT     F_KRN_DZFS_BATENTRY2BUFFER
; Extracts the data of a BAT entry from the RAM buffer,
; and puts the values in RAM SYSVARS
; IN <= A = Entry number
; OUT => SYSVARS variables are filled with data from CF_BUFFER_START
        
        ; Position at the start of the specified Entry number
        ; Each BAT entry is 32 bytes, and there are 16 entries per Sector
        ; hence, maximum will be 32 * 15 = 480
        ld      DE, 0
        cp      0                           ; Are we referring to Entry 0?
        jp      z, batentry_no_mult         ; Yes, then no multiplication needed
        ld      DE, 32
        call    F_KRN_MULTIPLY816_SLOW      ; HL = A * 32
        ex      DE, HL                      ; DE = A * 32
batentry_no_mult:
        ld      IX, CF_BUFFER_START
        add     IX, DE                      ; IX  = CF_BUFFER_START + (A * 32)
        ld      (tmp_addr1), IX

        ; Filename (16 bytes)
        ld      BC, 16
        ld      HL, (tmp_addr1)             ; source address
        ld      DE, CF_cur_file_name           ; destination address
        ldir                                ; copy BC bytes from HL to DE
        ; Attributes (1 byte) starting at offset $0E
        ld      A, (IX + $0E)
        ld      (CF_cur_file_attribs), A
        ; Time created (2 bytes) starting at offset $0F
        ld      A, (IX + $0F)
        ld      (CF_cur_file_time_created), A
        ld      A, (IX + $10)
        ld      (CF_cur_file_time_created + 1), A
        ; Date created (2 bytes) starting at offset $11
        ld      A, (IX + $11)
        ld      (CF_cur_file_date_created), A
        ld      A, (IX + $12)
        ld      (CF_cur_file_date_created + 1), A
        ; Time last modified (2 bytes) starting at offset $13
        ld      A, (IX + $13)
        ld      (CF_cur_file_time_modified), A
        ld      A, (IX + $14)
        ld      (CF_cur_file_time_modified + 1), A
        ; Date last modified (2 bytes) starting at offset $15
        ld      A, (IX + $15)
        ld      (CF_cur_file_date_modified), A
        ld      A, (IX + $16)
        ld      (CF_cur_file_date_modified + 1), A
        ; File size in bytes (2 bytes) starting at offset $17
        ld      A, (IX + $17)
        ld      (CF_cur_file_size_bytes), A
        ld      A, (IX + $18)
        ld      (CF_cur_file_size_bytes + 1), A
    ; File size in sectors (1 byte) starting at offset $19
        ld      A, (IX + $19)
        ld      (CF_cur_file_size_sectors), A
        ; Entry number (2 bytes) starting at offset $1A
        ld      A, (IX + $1A)
        ld      (CF_cur_file_entry_number), A
        ld      A, (IX + $1B)
        ld      (CF_cur_file_entry_number + 1), A
    ; First sector (2 bytes) starting at offset $1C
    ld      A, (IX + $1C)
        ld      (CF_cur_file_1st_sector), A
        ld      A, (IX + $1D)
        ld      (CF_cur_file_1st_sector + 1), A
        ; Load address (2 bytes) starting at offset $1E
        ld      A, (IX + $1E)
        ld      (CF_cur_file_load_addr), A
        ld      A, (IX + $1F)
        ld      (CF_cur_file_load_addr + 1), A
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_SEC2BUFFER:
; Loads a Sector (512 bytes) and puts the bytes into RAM buffer
; IN <=  HL = Sector number
; OUT => CF_BUFFER_START is filled with the read 512 bytes
        ex    DE, HL            ; D sector address LBA 1 (bits 8-15)
                    ; E sector address LBA 0 (bits 0-7)
        ; ld    BC, 0            ; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
        call    F_BIOS_CF_READ_SEC    ; read 1 sector (512 bytes)
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_GET_FILE_BATENTRY:           .EXPORT         F_KRN_DZFS_GET_FILE_BATENTRY
; Gets the BAT's entry number of a specified filename
; IN <= HL = Address where the filename to check is stored
; OUT => HL = BAT Entry is stored in the SYSVARS
        ld      DE, $BAAB                       ; Store a default value
        ld      (tmp_addr3), DE                 ;   so that we can use it to check
                                                ;   if filename was found

        ld      (tmp_addr2), HL                 ; Store address of filename to check
        ld      A, 1                            ; BAT starts at sector 1
        ld      (CF_cur_sector), A
        ld      A, 0
        ld      (CF_cur_sector + 1), A
bat_nextsector:
        call    F_KRN_DZFS_READ_BAT_SECTOR
    ; As we read in groups of 512 bytes (Sector), 
    ; each read will put 16 entries in the buffer.
    ; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
    ; therefore 64 sectors.
    ld    A, 0                ; entry counter
bat_entry:
    push     AF                              ; backup entry counter
    call    F_KRN_DZFS_BATENTRY2BUFFER
        ; Get length of specified filename
        ld      A, $00                          ; filename to check ends with space  TODO - Space or zero?!
        ld      HL, (tmp_addr2)                 ; HL = address of filename to check
        call    F_KRN_STRLEN                    ; B = length of filename to check
        ; Check if filename in buffer is equal to the specified filename
        ld      DE, (tmp_addr2)                 ; DE = address of filename to check
        ld      HL, CF_cur_file_name            ; HL = address of filename in BAT entry
        ld      A, 14                           ; filename in BAT entry is 14 characters
        call    F_KRN_STRCMP                    ; Are the same?
        jp      nz, bat_nextentry               ; No, skip entry
        ld      DE, $0000                       ; Yes, reset tmp_addr3
        ld      (tmp_addr3), DE                 ; if equal $0000, filename was found
                                                ; if equal $ABBA, not found
        pop     AF                              ; needed because previous push AF
        ret                                     ; exit subroutine
bat_nextentry:
        pop    AF                              ; restore entry counter
        inc    A                               ; next entry
        cp    16                              ; did we process the 16 entries?
        jp    nz, bat_entry                   ; No, process next entry
        ; More entries in other sectors?
        ld    A, (CF_cur_sector)
        inc    A                               ; increment sector counter
        ld    (CF_cur_sector), A              ; Did we process
        cp    64                              ;    64 sectors already?
        jp    nz, bat_nextsector              ; No, then process next sector
        ret                                     ; Yes, then nothing else to do
;------------------------------------------------------------------------------
F_KRN_DZFS_LOAD_FILE_TO_RAM:            .EXPORT         F_KRN_DZFS_LOAD_FILE_TO_RAM
; Load a file from CF into RAM, at the specified address
; IN <= HL load address in RAM
;       DE 1st sector
;        IX length in sectors
;
    ld    (CF_cur_sector), IX     ; sector counter
    ld    IX, CF_cur_sector    ; pointer to sector counter
    ; set up LBA addressing
loadfile:
    ld    B, 0
    ld    A, (CF_cur_partition)
    ld    C, A
    call    F_BIOS_CF_READ_SEC    ; read 1 sector (512 bytes)
    ; Copy file data from buffer to load address
    ld      BC, 512
        ld      HL, CF_BUFFER_START
        ld      DE, (CF_cur_file_load_addr)
        ldir

    dec    (IX)            ; decrement sector counter
    or    (IX)            ; is it 0?
    ret    z             ; yes, exit subroutine
    inc    DE            ; no, increment sector number
    jp    loadfile        ;     and read more sectors
;------------------------------------------------------------------------------
F_KRN_DZFS_DELETE_FILE:                 .EXPORT         F_KRN_DZFS_DELETE_FILE
; To delete a file, change 1st character of the filename to 7E (~)
; IN <= DE = BAT Entry number
;
        ; The 1st character is at 
        ;    32 (bytes per entry) * Entry number
        ; There are maximum 16 entries in sector (512 / 32)
        ld      A, 32                   ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW  ; HL = A * DE
        ld      DE, CF_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in CF buffer
        ld      (HL), $7E               ; Change the 1st character in the buffer
        ; save data to CF
        call    F_KRN_DZFS_SECTOR_TO_CF
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_CHGATTR_FILE:                .EXPORT         F_KRN_DZFS_CHGATTR_FILE
; Changes the attributes (RHSE) of a file
; IN <= DE = BAT Entry number
;       A = attributes mask byte
        push    AF                      ; backup mask byte
        ld      A, 32                   ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW  ; HL = A * DE
        ld      DE, CF_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in CF buffer
        ld      DE, $000E               ; file attributes offset is at $0E
        add     HL, DE                  ; HL points to file attributes
        pop     AF                      ; restore mask byte
        ld      (HL), A                 ; change file attributes
        ; save data to CF
        call    F_KRN_DZFS_SECTOR_TO_CF ; save data to CF
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_RENAME_FILE:                 .EXPORT         F_KRN_DZFS_RENAME_FILE
; Changes the name of a file
; IN <= IY = Address where the new filename is stored
;       DE = BAT Entry number
        ; ld      DE, $0003             ; TODO - delete this after tests
        ld      ($3000), DE             ; TODO - delete this after tests
        ld      A, 32                   ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW  ; HL = A * DE
        ld      DE, CF_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in CF buffer (old filename)
        ld      ($3002), HL             ; TODO - delete this after tests
        ; copy characters from new filename to CF buffer
        ld      B, 1                    ; character counter
rename_loop:
        ld      A, (IY)                 ; new filename character
        cp      0                       ; end of filename?
        jp      z, rename_padding       ; yes, do the padding to 14 characters
        ld      (HL), A                 ; no, store it in CF buffer
        inc     HL                      ; next char in CF buffer
        inc     IY                      ;next char in old name
        inc     B
        jp      rename_loop
rename_padding:
        ld      A, B                    ; did we renamed
        cp      14                      ;   14 characters?
        jp      z, rename_save          ; yes, save data to CF
        ; no, do padding (with spaces) for the remaining characters
        ld      A, $20
        ld      (HL), A
        inc     HL
        inc     B
        jp      rename_padding
rename_save:
        ld      A, $20                  ; one last space
        ld      (HL), A                 ;   needed on the padding
        ; save data to CF
        call    F_KRN_DZFS_SECTOR_TO_CF
        ret

;------------------------------------------------------------------------------
F_KRN_DZFS_FORMAT_CF:                   .EXPORT         F_KRN_DZFS_FORMAT_CF
; Formats a CompactFlash disk
; IN <= HL = Address where the disk label is stored
;       DE = Address where the number of partitions is stored
        push    DE                      ; backup DE
        push    HL                      ; backup HL
        ld      HL, msg_format_start
        call    F_KRN_SERIAL_WRSTR
    ; Superblock - Step 1: prepare data in CF_BUFFER_START
        ; Signature
        ld      HL, $BAAB               ; in little-endian will become ABBA ;-)
        ld      (CF_BUFFER_START), HL
        call    format_progress
        ; Disk State
        ld      A, $FF
        ld      (CF_BUFFER_START + $02), A
        call    format_progress
        ; File System identifier ('DZFSV1' in ASCII)
        ld      BC, 8
        ld      DE, CF_BUFFER_START + $03
        ld      HL, const_fd_id
        ldir
        call    format_progress
        ; Volume Serial Number
        call    F_KRN_DZFS_CALC_SN
        ld      DE, CF_BUFFER_START + $0B
        ld      B, 4
        ldir
        call    format_progress
        ; Not used
        ld      A, $00
        ld      (CF_BUFFER_START + $0F), A
        call    format_progress
; TODO        ; Volume label
        ld      B, 16
        ld      DE, CF_BUFFER_START + $10
        pop     HL                      ; restore HL
        ldir
        ; Needs to be padded to 16 characters
        call    format_progress
; TODO        ; Volume Date creation
        call    F_BIOS_RTC_GET_DATE

        ; ; ld      A, (RTC_day)            ; TODO - value is in Hex
        ; ld      A, $04
        ; ld      (CF_BUFFER_START + $20), A
        ; call    F_KRN_BIN_TO_BCD4
        ; ld      A, L
        ; ld      (CF_BUFFER_START + $21), A
        ; ; call    F_KRN_HEX_TO_ASCII
        ; ; ld      A, H
        ; ; ld      A, L

        ; ld      A, (RTC_month)
        ; call    F_KRN_BIN_TO_BCD4
        ; ld      A, L
        ; ; call    F_KRN_HEX_TO_ASCII
        ; ; ld      A, H
        ; ld      (CF_BUFFER_START + $22), A
        ; ; ld      A, L
        ; ; ld      (CF_BUFFER_START + $23), A

        ; ld      A, (RTC_century)
        ; call    F_KRN_BIN_TO_BCD4
        ; ld      A, L
        ; ; call    F_KRN_HEX_TO_ASCII
        ; ; ld      A, H
        ; ld      (CF_BUFFER_START + $24), A
        ; ; ld      A, L
        ; ; ld      (CF_BUFFER_START + $25), A

        ; ld      A, (RTC_year)
        ; call    F_KRN_BIN_TO_BCD4
        ; ld      A, L
        ; ; call    F_KRN_HEX_TO_ASCII
        ; ; ld      A, H
        ; ld      (CF_BUFFER_START + $26), A
        ; ; ld      A, L
        ; ; ld      (CF_BUFFER_START + $27), A

        call    format_progress

; ; TODO        ; Volume Time creation
;         call    F_BIOS_RTC_GET_TIME
;         call    format_progress
        ; Bytes per Sector
        ld      HL, $0200
        ld      (CF_BUFFER_START + $2E), HL
        call    format_progress
        ; Sectors per Block
        ld      A, $40
        ld      (CF_BUFFER_START + $30), A
        call    format_progress
        ; Number of partitions
        pop     DE                      ; restore DE
        ld      A, (DE)
        sub     $30                     ; convert digit to Hex
        ld      (CF_BUFFER_START + $31), A
        call    format_progress
        ; Copyright notice
        ld      BC, 51
        ld      DE, CF_BUFFER_START + $32
        ld      HL, const_copyright
        ldir
        ; Rest 411 bytes are not used, lets set them as zeros.
        ld      IX, CF_BUFFER_START + $65
        ld      B, $FF                  ; We do 255 bytes first
        call    format_zeros_loop
        ld      B, $9C                  ; and 156 bytes after
        call    format_zeros_loop

    ; Superblock - Step 2: store bytes from CF_BUFFER_START into the disk
        ld      DE, $0000               ; Superblock is located
        ld      (CF_cur_sector), DE
        call    F_KRN_DZFS_SECTOR_TO_CF
        
    ; BAT Partition 1
; TODO - Multiple partitions
        ; After format, the BAT is empty (all zeros) 
        ld      HL, CF_BUFFER_START     ; Empty the
        ld      BC, 512                 ;   CF buffer (512 bytes)
        ld      A, $00                    ;   with
        call    F_KRN_SETMEMRNG         ;   zeros
        ; BAT is 1 Block (32,768 bytes)
        ; We need to write the CF buffer 64 times (64 * 512 = 32,768) to disk
; TODO - Convert all this into a subroutine for BAT formatting, in which we tell which partition number and calculates the corresponding sector number
        ld      A, 64                   ; 64 times
        ld      (tmp_byte), A           ;   counter
        ld      DE, $0001               ; BAT 1 starts at sector 1
        ld      (CF_cur_sector), DE
        ld      IX, tmp_byte
write_bat:
        ; ld      BC, $0000
        ; call    F_BIOS_CF_WRITE_SEC
        call    F_KRN_DZFS_SECTOR_TO_CF
        inc     DE
        dec     (IX)
        jp      nz, write_bat
        call    format_progress
        ret

; ------------------------------------
; Subroutines for F_KRN_DZFS_FORMAT_CF
; ------------------------------------
format_zeros_loop:
        ld      A, $00
        ld      (IX), A
        inc     IX
        call    format_progress
        djnz    format_zeros_loop
        ret

format_progress:
        ld      A, '.'
        call    F_BIOS_SERIAL_CONOUT_A
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_CALC_SN:     ; TODO
; Calculates the Serial Number for a disk
; IN <= none
; OUT => HL = Address where the Serial Number has been stored
        ld      A, $35
        ld      (tmp_addr1), A
        ld      A, $2A
        ld      (tmp_addr1 + 1), A
        ld      A, $15
        ld      (tmp_addr1 + 2), A
        ld      A, $F2
        ld      (tmp_addr1 + 3), A
        ld      HL, tmp_addr1
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_SECTOR_TO_CF:
; Calls the BIOS subroutine that will store the data (512 bytes) currently in
; CF Card Buffer to the CompactFlash card
; IN <= SYSVARS.CF_cur_sector = the sector in the CF card that will be written
        ld      DE, (CF_cur_sector)
        ld      BC, $0000
        call    F_BIOS_CF_WRITE_SEC 
        ret
;==============================================================================
; Constants
;==============================================================================
const_fd_id:
        .BYTE   "DZFSV1  "
const_copyright:
        .BYTE   "Copyright 2022David Asta      The MIT License (MIT)"
;==============================================================================
; Messages
;==============================================================================
msg_unformatted:
        .BYTE   "    The CF disk appears to be unformatted", 0
msg_format_start:
        .BYTE    CR, LF
        .BYTE    "Formatting", 0
