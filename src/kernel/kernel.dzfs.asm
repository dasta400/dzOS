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
KRN_DZFS_READ_SUPERBLOCK:
; reads the Superblock (512 bytes) at Sector 0
        ; read 512 bytes from Sector 0 into CF buffer in RAM
        ld      DE, 0
        ld      BC, 0
        call    F_BIOS_CF_READ_SEC

        ; Check that the sector is a Superblock
        ; $20-$21 must be AB BA
        ld      A, (CF_SBLOCK_SIGNATURE)
        cp      $AB
        jp      nz, sb_error_signature
        ld      A, (CF_SBLOCK_SIGNATURE + 1)
        cp      $BA
        jp      nz, sb_error_signature

        ; change flag in SYSVARS
        ld      A, $FF
        ld      (CF_is_formatted), A

        ; Set partition 0 as default
        ld      A, 0
        ld      (CF_cur_partition), A
        ret

sb_error_signature:
        ; Superblock hasn't the correct signature
        ; change flag in SYSVARS
        ld      A, $00
        ld      (CF_is_formatted), A
        ret
;------------------------------------------------------------------------------
KRN_DZFS_READ_BAT_SECTOR:
; Read a BAT Sector into RAM buffer
; IN <= value stored in SYSVAR's CF_cur_sector
        ; ld      A, 1
        ; ld      (CF_cur_sector), A
        ; ld      A, 0
        ; ld      (CF_cur_sector + 1), A
load_sector:
        ld      HL, (CF_cur_sector)
        ld      BC, 0
        call    F_KRN_DZFS_SEC_TO_BUFFER    ; load sector into RAM buffer

        ; call    F_BIOS_CF_READ_SEC
        ret
;------------------------------------------------------------------------------
KRN_DZFS_BATENTRY2BUFFER:
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

        ; Filename (14 bytes)
        ld      BC, 14
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
KRN_DZFS_SEC_TO_BUFFER:
; Loads a Sector (512 bytes) and puts the bytes into RAM buffer
; IN <=  HL = Sector number
; OUT => CF_BUFFER_START is filled with the read 512 bytes
        ex    DE, HL            ; D sector address LBA 1 (bits 8-15)
                    ; E sector address LBA 0 (bits 0-7)
        ; ld    BC, 0            ; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
        call    F_BIOS_CF_READ_SEC    ; read 1 sector (512 bytes)
        ret
;------------------------------------------------------------------------------
KRN_DZFS_GET_FILE_BATENTRY:
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
        ld      A, 0                ; entry counter
bat_entry:
        push    AF                              ; backup entry counter
        call    F_KRN_DZFS_BATENTRY2BUFFER
        ; Get length of specified filename
        ld      A, $00                          ; filename to check ends with zero
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
        pop     AF                              ; restore entry counter
        inc     A                               ; next entry
        cp      16                              ; did we process the 16 entries?
        jp      nz, bat_entry                   ; No, process next entry
        ; More entries in other sectors?
        ld      A, (CF_cur_sector)
        inc     A                               ; increment sector counter
        ld      (CF_cur_sector), A              ; Did we process
        cp      64                              ;    64 sectors already?
        jp      nz, bat_nextsector              ; No, then process next sector
        ret                                     ; Yes, then nothing else to do
;------------------------------------------------------------------------------
KRN_DZFS_LOAD_FILE_TO_RAM:
; Load a file from CF into RAM, at the specified address
; IN <= DE 1st sector
;       IX length in sectors
;
        ld      (CF_cur_sector), IX     ; sector counter
        ld      IX, CF_cur_sector       ; pointer to sector counter
        ld      HL, (CF_cur_file_load_addr) ; By loading groups of 512 bytes
        ld      (tmp_addr1), HL             ; the address will be modified
                                            ; so I use a temporary variable to store it
loadfile:
        ; set up LBA addressing
        ld      B, 0
        ld      A, (CF_cur_partition)
        ld      C, A
        push    DE                      ; backup sector to load
        call    F_BIOS_CF_READ_SEC      ; read 1 sector (512 bytes)
        ; Copy file data
        ld      BC, 512                 ; Copy 512 bytes
        ld      HL, CF_BUFFER_START     ;   from the CF buffer
        ld      DE, (tmp_addr1)         ;   to RAM
        ldir
        ld      (tmp_addr1), DE         ; store the new RAM address,
                                        ;   after ldir incremented DE by 512 bytes
        dec     (IX)                    ; decrement sector counter
        jp      z, loadfile_end
        pop     DE                      ; restore sector to load
        inc     DE                      ; no, increment sector number
        jp    loadfile                  ;     and read more sectors
loadfile_end:
        pop     DE                      ; restore to avoid crash
        ret                             ; and exit routine
;------------------------------------------------------------------------------
KRN_DZFS_DELETE_FILE:
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
KRN_DZFS_CHGATTR_FILE:
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
KRN_DZFS_RENAME_FILE:
; Changes the name of a file
; IN <= IY = Address where the new filename is stored
;       DE = BAT Entry number
        ld      A, 32                   ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW  ; HL = A * DE
        ld      DE, CF_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in CF buffer (old filename)
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
KRN_DZFS_FORMAT_CF:
; Formats a CompactFlash disk
; IN <= HL = Address where the disk label is stored
;       DE = Address where the number of partitions is stored
        push    DE                      ; backup DE
        ; push    HL                      ; backup HL
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
        ld      IX, CF_BUFFER_START + $0B
        call    KRN_DZFS_CALC_SN
        call    format_progress
        
        ; Not used
        ld      A, $00
        ld      (CF_BUFFER_START + $0F), A
        call    format_progress
        
        ; Volume label
        ld      IY, CLI_buffer_parm1_val    ; IY = address where the volname is stored (user input)
        ld      HL, CF_BUFFER_START + $10   ; Hl = address where the volname will be stored (CF buffer)
        ld      B, 1                    ; character counter
_volname_loop:
        ld      A, (IY)                 ; volname character
        cp      0                       ; end of volname?
        jp      z, _volname_padding     ; yes, do the padding to 16 characters
        ld      (HL), A                 ; no, store it in CF buffer
        inc     HL                      ; next char in CF buffer
        inc     IY                      ;next char in old name
        inc     B
        jp      _volname_loop
_volname_padding:
        ld      A, B                    ; did we renamed
        cp      16                      ;   16 characters?
        jp      z, _volname_finish      ; yes, finish padding
        ; no, do padding (with spaces) for the remaining characters
        ld      A, $20
        ld      (HL), A
        inc     HL
        inc     B
        jp      _volname_padding
_volname_finish:
        ld      A, $20                  ; one last space
        ld      (HL), A                 ;   needed on the padding
        call    format_progress
        
        ; Volume Date creation
        call    F_BIOS_RTC_GET_DATE     ; SYSVARS = day, month, year in hex
        call    F_BIOS_RTC_GET_TIME     ; Get time at the same time as date to avoid differences
        ld      A, (RTC_day)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (CF_BUFFER_START + $20), A
        ld      A, (tmp_addr1 + 5)
        ld      (CF_BUFFER_START + $21), A
        ld      A, (RTC_month)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (CF_BUFFER_START + $22), A
        ld      A, (tmp_addr1 + 5)
        ld      (CF_BUFFER_START + $23), A
        ld      HL, (RTC_year4)
        call    F_KRN_BIN_TO_BCD6
        ld      C, 0
        ex      DE, HL
        ld      DE, tmp_addr1
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 2)
        ld      (CF_BUFFER_START + $24), A
        ld      A, (tmp_addr1 + 3)
        ld      (CF_BUFFER_START + $25), A
        ld      A, (tmp_addr1 + 4)
        ld      (CF_BUFFER_START + $26), A
        ld      A, (tmp_addr1 + 5)
        ld      (CF_BUFFER_START + $27), A
        call    format_progress
        
        ; Volume Time creation
        ld      A, (RTC_hour)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (CF_BUFFER_START + $28), A
        ld      A, (tmp_addr1 + 5)
        ld      (CF_BUFFER_START + $29), A
        ld      A, (RTC_minutes)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (CF_BUFFER_START + $2A), A
        ld      A, (tmp_addr1 + 5)
        ld      (CF_BUFFER_START + $2B), A
        ld      A, (RTC_seconds)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (CF_BUFFER_START + $2C), A
        ld      A, (tmp_addr1 + 5)
        ld      (CF_BUFFER_START + $2D), A

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
        ; Change SYSVARS.CF_is_formatted to $FF
        ld      A, $FF
        ld      (CF_is_formatted), A
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
KRN_DZFS_CALC_SN:
; Calculates the Serial Number (4 bytes) for a disk
; Formula is:
;               1st byte: day + seconds (in Hexadecimal)
;               2nd byte: month + seconds (in Hexadecimal)
;               3rd & 4th bytes: hours (24h) * 256 + minutes + year 4 digits (in Hexadecimal)
; IN <= IX = Address where the Serial Number will be stored
        call    F_BIOS_RTC_GET_DATE
        call    F_BIOS_RTC_GET_TIME
        ; 1st byte: day + seconds
        ld      A, (RTC_seconds)
        ld      HL, RTC_day
        add     A, (HL)
        ld      (IX), A
        inc     IX
        ; 2nd byte: month + seconds
        ld      A, (RTC_seconds)
        ld      HL, RTC_month
        add     A, (HL)
        ld      (IX), A
        inc     IX
        ; 3rd & 4th bytes: hours (24h) * 256 + minutes + year 4 digits
        ld      A, (RTC_hour)
        ld      DE, 256
        call    F_KRN_MULTIPLY816_SLOW  ; HL = hour * 256
        ld      A, (RTC_minutes)
        ld      B, 0
        ld      C, A
        add     HL, BC                  ; HL = (hour * 256) + minutes
        ld      BC, (RTC_year4)
        add     HL, BC                  ; HL = (hour * 256) + minutes + year 4 digits
        ld      (IX), H
        ld      (IX + 1), L
        ret
;------------------------------------------------------------------------------
KRN_DZFS_SECTOR_TO_CF:
; Calls the BIOS subroutine that will store the data (512 bytes) currently in
; CF Card Buffer to the CompactFlash card
; IN <= SYSVARS.CF_cur_sector = the sector in the CF card that will be written
        ld      DE, (CF_cur_sector)
        ld      BC, $0000
        call    F_BIOS_CF_WRITE_SEC 
        ret
;------------------------------------------------------------------------------
KRN_DZFS_GET_BAT_FREE_ENTRY:
; OUT => SYSVARS.CF_cur_file_entry_number = available entry number
; Reads the BAT to find the first available free entry (entry starts with $00)
; If no there are no free entries, then it returns the first entry found 
;   of a deleted file (entry starts with $7E)

; ToDo - F_KRN_DZFS_GET_BAT_FREE_ENTRY
;       ✔ Read entire BAT
;       Store first entry (if any) with $7E as first byte
;       ✔ If found entry with $00 as first byte, return this entry's number
;       Else, return entry's number of the entry with $7E as first byte
;       If no $00 nor $7E, return $FFFF as entry number to indicate error

        ld      IY, 0                           ; temporary storage for file entry
        ld      A, 1                            ; BAT starts at sector 1
        ld      (CF_cur_sector), A
        ld      A, 0
        ld      (CF_cur_sector + 1), A
getbat_nextsector:
        call    F_KRN_DZFS_READ_BAT_SECTOR
        ; As we read in groups of 512 bytes (Sector), 
        ; each read will put 16 entries in the buffer.
        ; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
        ; therefore 64 sectors.
        ld      A, 0                            ; entry counter
getbat_entry:
        push    AF                              ; backup entry counter
        call    F_KRN_DZFS_BATENTRY2BUFFER
        ; is the entry free (i.e. $00 as first byte of filename)?
        ld      A, (CF_cur_file_name)
        cp      $00                             ; is it a free entry?
        jp      nz, getbat_nextentry            ; no, check next entry
        ; cp      $7E                             ; is it a deleted file entry?
        ld      (CF_cur_file_entry_number), IY  ; yes, store the entry number in SYSVARS
        pop     AF                              ; needed because previous push AF

        ret                                     ; exit subroutine
getbat_nextentry:
        inc     IY
        pop     AF                              ; restore entry counter
        inc     A                               ; next entry
        cp      16                              ; did we process the 16 entries?
        jp      nz, getbat_entry                ; No, process next entry
        ; More entries in other sectors?
        ld      A, (CF_cur_sector)
        inc     A                               ; increment sector counter
        ld      (CF_cur_sector), A              ; Did we process
        cp      64                              ;    64 sectors already?
        jp      nz, getbat_nextsector           ; No, then process next sector
; ToDo - F_KRN_DZFS_GET_BAT_FREE_ENTRY: test for no free entries but delete files
; ToDo - F_KRN_DZFS_GET_BAT_FREE_ENTRY: test for no free entries and no deleted files
        ret                                     ; Yes, then nothing else to do
;------------------------------------------------------------------------------
KRN_DZFS_ADD_BAT_ENTRY:
; Adds a BAT entry to the disc
; IN <= DE = BAT entry number
;       SYSVARS.CF_cur_sector = Sector number where the BAT Entry is
;       SYSVARS.CF_BUFFER = Sector where the BAT Entry is, loaded from disc
;       SYSVARS.CF BAT section = filled wit new BAT Entry information
        ld      A, 32                   ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW  ; HL = A * DE
        ld      DE, CF_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in CF buffer
        ; Copy BAT Entry from SYSVARS to CF Buffer
        ex      DE, HL                  ; DE points to 1st Entry byte in CF buffer
        ld      HL, CF_cur_file_name    ; HL points to 1st Entry byte in SYSVARS
        ld      BC, 32                  ; 32 bytes per entry
        ldir                            ; Copy BAT Entry from SYSVARS to CF Buffer
        ret
;------------------------------------------------------------------------------
KRN_DZFS_CREATE_NEW_FILE:
; Creates a new file in the disc, from bytes stored in RAM
; Also creates a BAT entry for the created file
; IN <= HL = address in memory of first byte to be stored
;       BC = number of bytes to be stored
;       IX = address where the filename is stored
        push    HL                      ; backup first byte to be stored
        push    BC                      ; backup number of bytes
        push    IX                      ; backup filename address

        call    F_KRN_DZFS_GET_BAT_FREE_ENTRY   ; returns available entry number
                                                ; $FFFF means no space for more files
        ld      HL, (CF_cur_file_entry_number)  ; backup
        ld      (tmp_addr1), HL                  ;   entry number
; ToDo - F_KRN_DZFS_CREATE_NEW_FILE - Return error if $FFFF (watch for the PUSH done before)
        
        ; Create BAT entry
        ;   Clear (set to zeros) the BAT entry variables in SYSVARS
        ld      B, 32                   ; BAT entry in SYSVARS is 32 bytes
        ld      IX, CF_cur_file_name    ; IX points to first byte of BAT entry
        call    F_KRN_CLEAR_MEMAREA
        ;   Filename
        ld      B, 14                   ; filenames are max. 14 characters
        pop     IX                      ; restore filename address
        ld      HL, CF_cur_file_name    ; HL points to where the filename in SYSVARS
loop_copy_fname:
        ld      A, (IX)                 ; A = filename character
        cp      0                       ; is it zero (no character)?
        jp      nz, loop_copy_fname_nopadded ; no, then copy character
        ld      A, SPACE                     ; yes, add padding spaces
        jp      loop_copy_fname_padded       ;      and skip the next 'inc IX'
loop_copy_fname_nopadded:
        inc     IX
loop_copy_fname_padded:
        ld      (HL), A                 ;   copy to SYSVARS
        inc     HL
        djnz    loop_copy_fname         ; copy until 14 characters done
        ;   Attributes ($08 = executable)
        ld      A, $08
        ld      (CF_cur_file_attribs), A
        ;   Time created (and set modified as the same)
        call    F_KRN_DZFS_CALC_FILETIME
        ld      (CF_cur_file_time_created), HL
        ld      (CF_cur_file_time_modified), HL
        ;   Date created (and set modified as the same)
        call    F_KRN_DZFS_CALC_FILEDATE
        ld      (CF_cur_file_date_created), HL
        ld      (CF_cur_file_date_modified), HL
        ;   File size in bytes
        pop     BC                              ; restore number of bytes
        ld      (CF_cur_file_size_bytes), BC    ; and store them in BAT
        ;   File size in sectors
        ld      DE, 512
        call    F_KRN_DIV1616           ; BC = BC / DE, HL = remainder
        ld      A, C
        ld      (CF_cur_file_size_sectors), A
        ld      (tmp_addr2), HL         ; store remainder in temporary location for later use will saving
        ;   If remainder > 0, size_sectors + 1
        ; ld      A, H
        ; cp      0
        ; jp      nz, savef_remainder
        ; ld      A, L
        ; cp      0
        ld      A, H
        or      L
        jp      z, savef_noremainder
savef_remainder:
        ld      HL, CF_cur_file_size_sectors
        inc     (HL)                    ; sectors + 1, for the remaining last bytes
savef_noremainder:
        ;   BAT entry number
        ld      HL, (tmp_addr1)
        ld      (CF_cur_file_entry_number), HL
        ;   First Sector (65 + 64 * entry_number)
        ld      HL, 64
        ld      DE, (CF_cur_file_entry_number)
        call    F_KRN_MULTIPLY1616
        ld      DE, 65
        add     HL, DE
        ld      (CF_cur_file_1st_sector), HL  ; 1st Sector address
        ;   Load address
        pop     HL                      ; restore start mem address to save
        ld      (CF_cur_file_load_addr), HL

        ; Copy all bytes, in blocks of 512 bytes, from RAM to CF Card Buffer
; Examples:
;   bytes   sectors remainder   extra
;   32768   64      0           0
;   32200   62      456         456
;   1024    2       0           0
;   824     1       312         312
;   512     1       0           0
;   320     0       320         320
;   100     0       100         100
;         ld      A, (CF_cur_file_size_sectors)   ; number of sectors to save
;         ld      (tmp_byte), A                   ; store it in temp, to count down
        
;   Decrement sector count by 1, so that we don't have a full sector at the end
;   Loop:
;       Decrement sector count
;       If remaining sectors to copy > 0
;           BC = 512
;           DE = CF_BUFFER_START
;           Call F_KRN_COPYMEM512
;           Call F_KRN_DZFS_SECTOR_TO_CF
;           Loop
;       Else
;           If remaining bytes > 0
;           BC = remaining bytes
;           DE = CF_BUFFER_START
;           Call F_KRN_COPYMEM512
;           Call F_KRN_DZFS_SECTOR_TO_CF

        ld      A, (CF_cur_file_size_sectors)   ; number of sectors to save
        ld      (tmp_byte), A                   ; store it in temp, to count down
        ld      HL, (CF_cur_sector)             ; It contains the BAT's sector. We need it for later
        ld      (tmp_addr3), HL                 ;   to save the BAT. Hence, backup it up because we'll
                                                ;   use it now for counting the data sectors
        ld      A, (CF_cur_file_1st_sector)     ; Set CF_cur_sector to
        ld      (CF_cur_sector), A              ;   the address of the
        ld      A, (CF_cur_file_1st_sector + 1) ;   1st sector of the
        ld      (CF_cur_sector + 1), A          ;   new file
        ld      HL, (CF_cur_file_load_addr)     ; Store load address in a temporary address, because we'll
        ld      (tmp_addr1), HL                 ;   use it for incrementing by 512 each time in the loop
savef_save_sectors:
        ; ld      HL, tmp_byte            ; start the loop by decrementing sector count down
        ; dec     (HL)                    ; so that we don't have a full sector at the end
        ;                                 ; but just the remaining bytes
        ld      A, (tmp_byte)           ; load A with count down, inside the loop
        ; Copy 512 bytes from memory address to CF Card Buffer
        cp      0                               ; sectors > 0?
        jp      z, savef_lastbytes              ; yes, copy remaining bytes
        ; call    F_KRN_CLEAR_CFBUFFER
        ld      BC, 512                         ; no, copy full sector (512 bytes)
        ld      HL, (tmp_addr1)                 ; Bytes from address at tmp_addr1
        ld      DE, CF_BUFFER_START             ;   will be copied to the CF buffer
        call    F_KRN_COPYMEM512
        ; Save from CF Card Buffer to disc
        call    F_KRN_DZFS_SECTOR_TO_CF
        ; Increment sector counter
        ld      HL, CF_cur_sector
        inc     (HL)
        ; Update (+512) CF_cur_sector with next sector address
        ; ld      HL, (CF_cur_sector)
        ; ld      DE, 512
        ; add     HL, DE
        ; ld      (CF_cur_sector), HL
        ; Update (+512) tmp_addr1 with the next address from where to get the next 512 bytes to save
        ld      HL, (tmp_addr1)
        ld      DE, 512
        add     HL, DE
        ld      (tmp_addr1), HL
        ; Decrement sector count
        ld      HL, tmp_byte
        dec     (HL)
        ; Continue with more bytes
        jp      savef_save_sectors
savef_lastbytes:
        ; tmp_addr2 contains the number of bytes remaining that were not filling an entire sector
        ; If it's zero, nothing to do (i.e. divison remainder was zero)
        ; Otherwise save remaining bytes to an entire sector of 512 bytes padded with zeros
        ld      BC, (tmp_addr2)         ; remaining bytes
        ; ld      A, B
        ; cp      0
        ; jp      nz, savef_savelastbytes
        ; ld      A, C
        ; cp      0
        ld      A, B
        or      C
        jp      z, savef_batentry
; savef_savelastbytes:
        ; We added 512 in the loop, but last remaining bytes were less
        ; call    F_KRN_CLEAR_CFBUFFER
        ld      HL, (tmp_addr1)         ; Bytes from address at tmp_addr1
        ld      DE, 512                 ; count 512 bytes backwards
        or      A
        sbc     HL, DE
        ld      DE, CF_BUFFER_START     ;   will be copied to the CF buffer
        call    F_KRN_COPYMEM512
        ; Save from CF Card Buffer to disc
        call    F_KRN_DZFS_SECTOR_TO_CF
savef_batentry:
        ; Save BAT entry to disc
        ;   Read BAT from disc again, to finally update it
        ld      HL, (tmp_addr3)             ; restore sector number
        ld      (CF_cur_sector), HL         ;   where the BAT entry was
        ld      DE, (CF_cur_file_entry_number)
        push    DE                          ; backup BAT entry number
        call    F_KRN_DZFS_SEC_TO_BUFFER    ; Load BAT
        pop     DE                          ; restore BAT entry number
        call    F_KRN_DZFS_ADD_BAT_ENTRY    ; Update BAT and copy it to CF Card Buffer
        call    F_KRN_DZFS_SECTOR_TO_CF     ; Save buffer to disc
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_CALC_FILETIME:
; Converts current RTC time into two bytes
;           Byte 1    Byte 2
;           7654 3210 7654 3210
;           hhhh hmmm mmms ssss
; Example:  1001 1010 1111 0101 = 19 (10011) 23 (010111) 42 (10101)
; Formula: 2048 * hours + 32 * minutes + seconds / 2
; OUT => HL = RTC time into two bytes
        call    F_BIOS_RTC_GET_TIME     ; update SYSVARS time from RTC
        ; Hour
        ld      A, (RTC_hour)           ; get current RTC hour
        add     A, A                    ; shift it left three times
        add     A, A
        add     A, A
        ld      H, A                    ; and store it
        ld      L, 0                    ; in H, and L = 0
        ex      DE, HL                  ; store it in DE
        ; Minutes
        ld      A, (RTC_minutes)        ; get current RTC minutes
        ld      H, 0                    ; clear HL
        ld      L, A                    ; store it in L
        add     HL, HL                  ; shift it 5 times
        add     HL, HL
        add     HL, HL
        add     HL, HL
        add     HL, HL
        ; Add minutes to hour, using OR
        ld      A, H                    ; OR the H portion
        or      D                       ;   with D
        ld      H, A                    ; and store result back in H
        ld      A, L                    ; OR the L portion
        or      E                       ;   with E
        ld      L, A                    ; and store result back in L
        ; Seconds
        ld      A, (RTC_seconds)        ; get current RTC seconds
        srl     A                       ; divide by 2 (shift once right)
        ld      D, 0                    ; store in E portion
        ld      E, A                    ;   of DE, and D = 0
        ; Add seconds to minutes and hours
        add     HL, DE
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_CALC_FILEDATE:
; Converts current RTC date into two bytes
;           Byte 1    Byte 2
;           7654 3210 7654 3210
;           yyyy yyym mmmd dddd
; Example:  0001 1011 0110 1001 = 2013 (0001101) 11 (1011) 9 (01001)
; Year is stored as: current year - 2000 (e.g. 2022 - 2000 = 22)
; Therefore, with 7 bits, max. year can be 2107 (1111 111)
; Formula: 512 * (year - 2000) + month * 32 + day
; OUT => HL = RTC date into two bytes
        call    F_BIOS_RTC_GET_DATE     ; update SYSVARS date from RTC
        ; Year
        ld      A, (RTC_year)           ; get current RTC year (it's already year - 2000)
        ld      H, 0                    ; clear HL
        ld      L, A                    ; store it in L
        sla     L                       ; shift left 9 bits
        ld      H, L                    ; and store it
        ld      L, 0                    ; in H, and L = 0
        ex      DE, HL                  ; store it in DE
        ; Month
        ld      A, (RTC_month)          ; get current RTC month
        ld      H, 0                    ; clear HL
        ld      L, A                    ; store it in L
        add     HL, HL                  ; shift it 5 times
        add     HL, HL
        add     HL, HL
        add     HL, HL
        add     HL, HL
        ; Add month to year, using OR
        ld      A, H                    ; OR the H portion
        or      D                       ;   with D
        ld      H, A                    ; and store result back in H
        ld      A, L                    ; OR the L portion
        or      E                       ;   with E
        ld      L, A                    ; and store result back in L
        ; Day
        ld      A, (RTC_day)            ; get current RTC day
        ld      D, 0                    ; store in E portion
        ld      E, A                    ;   of DE, and D = 0
        ; Add day to month and year
        add     HL, DE
        ret
;------------------------------------------------------------------------------
KRN_DZFS_SHOW_DISKINFO_SHORT:
        ; Volume Label
        ld      HL, msg_vol_label
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 16                   ; counter
        ld      HL, CF_SBLOCK_LABEL     ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
        ; Volume Serial Number
        ld      HL, msg_volsn
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, (CF_SBLOCK_SERNUM)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $01)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $02)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $03)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ')'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Volume Date/Time Creation
        ld      HL, msg_vol_creation
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA          ; day
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 2      ; month
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 4                            ; counter = 4 bytes
        ld      HL, CF_SBLOCK_DATECREA + 4      ; year
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 8      ; hour
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 10     ; minutes
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 12     ; seconds
        call    F_KRN_SERIAL_PRN_BYTES
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ret
KRN_DZFS_SHOW_DISKINFO:
        call    F_KRN_DZFS_SHOW_DISKINFO_SHORT

        ; File System id
        ld      HL, msg_filesys
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 8                            ; counter = 4 bytes
        ld      HL, CF_SBLOCK_FSID              ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
        ld        B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Number of partitions
        ld      HL, msg_num_partitions
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, (CF_SBLOCK_NUMPARTITIONS)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Bytes per Sector
        ld      HL, msg_bytes_sector
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, (CF_SBLOCK_BYTESSEC)
        call    F_KRN_BIN_TO_BCD6               ; convert from hex to decimal
        ex      DE, HL                          ; HL = last 4 digits
        ld      DE, tmp_addr1                   ; temp storage for converted digits
        call    F_KRN_BCD_TO_ASCII              ; convert decimal to hex ASCII string
        ld      A, (tmp_addr1 + 3)              ; only need
        call    F_BIOS_SERIAL_CONOUT_A          ;   to print
        ld      A, (tmp_addr1 + 4)              ;   the
        call    F_BIOS_SERIAL_CONOUT_A          ;   last
        ld      A, (tmp_addr1 + 5)              ;   three digits
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Sectors per Block
        ld      HL, msg_sectors_block
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, (CF_SBLOCK_SECBLOCK)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1                   ; temp storage for converted digits
        call    F_KRN_BCD_TO_ASCII              ; convert decimal to hex ASCII string
        ld      A, (tmp_addr1 + 4)              ; only need
        call    F_BIOS_SERIAL_CONOUT_A          ;   to print
        ld      A, (tmp_addr1 + 5)              ;   the last
        call    F_BIOS_SERIAL_CONOUT_A          ;   two digits
        ret
