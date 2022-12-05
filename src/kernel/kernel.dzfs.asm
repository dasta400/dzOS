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
        ; read 512 bytes from Sector 0 into DISK buffer in RAM
        ld      DE, 0
        call    F_BIOS_DISK_READ_SEC

        ; Check that the sector is a Superblock
        ; $20-$21 must be AB BA
        ld      A, $00                          ; Reset SYSVARS.DISK_is_formatted
        ld      (DISK_is_formatted), A          ;   to $00 (not formatted)
        ld      A, (DZFS_SBLOCK_SIGNATURE)      ; If the 
        cp      $AB                             ;   signature
        jp      nz, end_check_signature         ;   in the Superblock
        ld      A, (DZFS_SBLOCK_SIGNATURE + 1)  ;   is correct,
        cp      $BA                             ;   then
        jp      nz, end_check_signature         ;   set
        ld      A, $FF                          ;   SYSVARS.DISK_is_formatted
        ld      (DISK_is_formatted), A          ;   to $FF
end_check_signature:
        ret

;------------------------------------------------------------------------------
KRN_DZFS_READ_BAT_SECTOR:
; Read a BAT Sector into RAM buffer
; IN <= value stored in SYSVAR's DISK_cur_sector
load_sector:
        ld      HL, (DISK_cur_sector)
        call    F_KRN_DZFS_SEC_TO_BUFFER    ; load sector into RAM buffer
        ret
;------------------------------------------------------------------------------
KRN_DZFS_BATENTRY_TO_BUFFER:
; Extracts the data of a BAT entry from the RAM buffer,
; and puts the values in RAM SYSVARS
; IN <= A = Entry number
; OUT => SYSVARS variables are filled with data from DISK_BUFFER_START
        
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
        ld      IX, DISK_BUFFER_START
        add     IX, DE                      ; IX  = DISK_BUFFER_START + (A * 32)
        ld      (tmp_addr1), IX

        ; Filename (14 bytes)
        ld      BC, 14
        ld      HL, (tmp_addr1)             ; source address
        ld      DE, DISK_cur_file_name      ; destination address
        ldir                                ; copy BC bytes from HL to DE
        ; Attributes (1 byte) starting at offset $0E
        ld      A, (IX + $0E)
        ld      (DISK_cur_file_attribs), A
        ; Time created (2 bytes) starting at offset $0F
        ld      A, (IX + $0F)
        ld      (DISK_cur_file_time_created), A
        ld      A, (IX + $10)
        ld      (DISK_cur_file_time_created + 1), A
        ; Date created (2 bytes) starting at offset $11
        ld      A, (IX + $11)
        ld      (DISK_cur_file_date_created), A
        ld      A, (IX + $12)
        ld      (DISK_cur_file_date_created + 1), A
        ; Time last modified (2 bytes) starting at offset $13
        ld      A, (IX + $13)
        ld      (DISK_cur_file_time_modified), A
        ld      A, (IX + $14)
        ld      (DISK_cur_file_time_modified + 1), A
        ; Date last modified (2 bytes) starting at offset $15
        ld      A, (IX + $15)
        ld      (DISK_cur_file_date_modified), A
        ld      A, (IX + $16)
        ld      (DISK_cur_file_date_modified + 1), A
        ; File size in bytes (2 bytes) starting at offset $17
        ld      A, (IX + $17)
        ld      (DISK_cur_file_size_bytes), A
        ld      A, (IX + $18)
        ld      (DISK_cur_file_size_bytes + 1), A
    ; File size in sectors (1 byte) starting at offset $19
        ld      A, (IX + $19)
        ld      (DISK_cur_file_size_sectors), A
        ; Entry number (2 bytes) starting at offset $1A
        ld      A, (IX + $1A)
        ld      (DISK_cur_file_entry_number), A
        ld      A, (IX + $1B)
        ld      (DISK_cur_file_entry_number + 1), A
    ; First sector (2 bytes) starting at offset $1C
        ld      A, (IX + $1C)
        ld      (DISK_cur_file_1st_sector), A
        ld      A, (IX + $1D)
        ld      (DISK_cur_file_1st_sector + 1), A
        ; Load address (2 bytes) starting at offset $1E
        ld      A, (IX + $1E)
        ld      (DISK_cur_file_load_addr), A
        ld      A, (IX + $1F)
        ld      (DISK_cur_file_load_addr + 1), A
        ret
;------------------------------------------------------------------------------
KRN_DZFS_SEC_TO_BUFFER:
; Loads a Sector (512 bytes) and puts the bytes into RAM buffer
; IN <=  HL = Sector number
; OUT => DISK_BUFFER_START is filled with the read 512 bytes
        ex    DE, HL                    ; D sector address LBA 1 (bits 8-15)
                                        ; E sector address LBA 0 (bits 0-7)
        call    F_BIOS_DISK_READ_SEC    ; read 1 sector (512 bytes)
        ret
;------------------------------------------------------------------------------
KRN_DZFS_GET_FILE_BATENTRY:
; Gets the BAT's entry number of a specified filename
; IN <= HL = Address where the filename to check is stored
; OUT => BAT Entry values are stored in the SYSVARS
;        DE = $0000 if filename found. Otherwise, whatever value had at start
        ld      (tmp_addr2), HL                 ; Store address of filename to check
        ld      A, 1                            ; BAT starts at sector 1
        ld      (DISK_cur_sector), A
        ld      A, 0
        ld      (DISK_cur_sector + 1), A
bat_nextsector:
        ld      HL, (DISK_cur_sector)
        call    F_KRN_DZFS_SEC_TO_BUFFER    ; load sector into RAM buffer
        ; As we read in groups of 512 bytes (Sector),
        ; each read will put 16 entries in the buffer.
        ; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
        ; therefore 64 sectors.
        ld      A, 0                            ; entry counter (max. 16)
bat_entry:
        push    AF                              ; backup entry counter
        call    F_KRN_DZFS_BATENTRY_TO_BUFFER
        ; If filename starts with $00, we have reached the last BAT entry. Exit
        ld      A, (DISK_cur_file_name)
        cp      0
        jp      z, bat_exit
        ; Get length of specified filename
        ld      A, $00                          ; filename to check ends with zero
        ld      HL, (tmp_addr2)                 ; HL = address of specified filename
        ld      B, 14                           ; B = max. characters to check
        call    F_KRN_STRLENMAX                 ; B = length of specified filename
        ld      A, B                            ; backup length of specified filename
        ld	(tmp_byte), A                       ;   in temporary variable in SYSVARS

        ; Get length of filename in BAT entry
        ld      A, SPACE                        ; filename to check ends with a space character
        ld      HL, DISK_cur_file_name          ; HL = address of filename in BAT entry
        ld      B, 14                           ; B = max. characters to check
        call    F_KRN_STRLENMAX                 ; B = length of filename

        ; Are both filenames equal in length?
        ld      A, (tmp_byte)                   ; restore length of specified filename
        cp      B                               ; Is the same length as filename in BAT entry?
        jp      nz, bat_nextentry               ; No, skip entry

        ; Check if filename in buffer (str2) is equal to the specified filename (str1)
        ld      HL, (tmp_addr2)                 ; DE = address of filename to check (str1)
        ld      DE, DISK_cur_file_name          ; HL = address of filename in BAT entry (str2)
        call    F_KRN_STRCMP                    ; Are the same?
        jp      nz, bat_nextentry               ; No, skip entry
bat_equals:
        ld      DE, $0000                       ; Yes, reset tmp_addr3
        ld      (tmp_addr3), DE                 ; if equal $0000, filename was found
                                                ; if equal $ABBA, not found
bat_exit:
        pop     AF                              ; needed because previous push AF
        ret                                     ; exit
bat_nextentry:
        pop     AF                              ; restore entry counter
        inc     A                               ; next entry
        cp      16                              ; did we process the 16 entries?
        jp      nz, bat_entry                   ; No, process next entry
        ; More entries in other sectors?
        ld      A, (DISK_cur_sector)
        inc     A                               ; increment sector counter
        ld      (DISK_cur_sector), A            ; Did we process
        cp      DZFS_SECTORS_PER_BLOCK          ;    64 sectors already?
        jp      nz, bat_nextsector              ; No, then process next sector
        ret                                     ; Yes, then nothing else to do
;------------------------------------------------------------------------------
KRN_DZFS_LOAD_FILE_TO_RAM:
; Load a file from DISK into RAM, at the specified address
; IN <= DE 1st sector
;       IX length in sectors
;
        ld      (DISK_cur_sector), IX           ; sector counter
        ld      IX, DISK_cur_sector             ; pointer to sector counter
        ld      HL, (DISK_cur_file_load_addr)   ; By loading groups of 512 bytes
        ld      (tmp_addr1), HL                 ; the address will be modified
                                                ; so I use a temporary variable to store it
loadfile:
        ; set up LBA addressing
        push    DE                      ; backup sector to load
        call    F_BIOS_DISK_READ_SEC    ; read 1 sector (512 bytes)
        ; Copy file data
        ld      BC, 512                 ; Copy 512 bytes
        ld      HL, DISK_BUFFER_START   ;   from the DISK buffer
        ld      DE, (tmp_addr1)         ;   to RAM
        ldir
        ld      (tmp_addr1), DE         ; store the new RAM address,
                                        ;   after ldir incremented DE by 512 bytes
        dec     (IX)                    ; decrement sector counter
        jp      z, loadfile_end         ; all sectors loaded?
        pop     DE                      ; no, restore sector to load
        inc     DE                      ;     increment sector number
        jp    loadfile                  ;        and read more sectors
loadfile_end:                           ; yes, finish
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
        ld      DE, DISK_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in DISK buffer
        ld      (HL), $7E               ; Change the 1st character in the buffer
        ; save data to disk
        call    F_KRN_DZFS_SECTOR_TO_DISK
        ret
;------------------------------------------------------------------------------
KRN_DZFS_CHGATTR_FILE:
; Changes the attributes (RHSE) of a file
; IN <= DE = BAT Entry number
;       A = attributes mask byte
        push    AF                      ; backup mask byte
        ld      A, 32                   ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW  ; HL = A * DE
        ld      DE, DISK_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in DISK buffer
        ld      DE, $000E               ; file attributes offset is at $0E
        add     HL, DE                  ; HL points to file attributes
        pop     AF                      ; restore mask byte
        ld      (HL), A                 ; change file attributes
        ; save data to disk
        call    F_KRN_DZFS_SECTOR_TO_DISK
        ret
;------------------------------------------------------------------------------
KRN_DZFS_RENAME_FILE:
; Changes the name of a file
; IN <= IY = Address where the new filename is stored
;       DE = BAT Entry number
        ld      A, 32                   ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW  ; HL = A * DE
        ld      DE, DISK_BUFFER_START
        add     HL, DE                  ; HL points to 1st character in DISK buffer (old filename)
        ; copy characters from new filename to DISK buffer
        ld      B, 1                    ; character counter
rename_loop:
        ld      A, (IY)                 ; new filename character
        cp      0                       ; end of filename?
        jp      z, rename_padding       ; yes, do the padding to 14 characters
        ld      (HL), A                 ; no, store it in DISK buffer
        inc     HL                      ; next char in DISK buffer
        inc     IY                      ;next char in old name
        inc     B
        jp      rename_loop
rename_padding:
        ld      A, B                    ; did we renamed
        cp      14                      ;   14 characters?
        jp      z, rename_save          ; yes, save data to DISK
        ; no, do padding (with spaces) for the remaining characters
        ld      A, $20
        ld      (HL), A
        inc     HL
        inc     B
        jp      rename_padding
rename_save:
        ld      A, $20                  ; one last space
        ld      (HL), A                 ;   needed on the padding
        ; save data to DISK
        call    F_KRN_DZFS_SECTOR_TO_DISK
        ret

;------------------------------------------------------------------------------
KRN_DZFS_FORMAT_DISK:
; Formats a DISK
; IN <= HL = Address where the disk label is stored
        ld      HL, msg_sd_format_start
        call    F_KRN_SERIAL_WRSTR

    ; Superblock - Step 1: prepare data in DISK_BUFFER_START
        ; Signature
        ld      HL, DZFS_SIGNATURE
        ld      (DZFS_SBLOCK_SIGNATURE), HL
        call    format_progress
        
        ; Not used
        ld      A, $00
        ld      (DZFS_SBLOCK_NOTUSED), A
        call    format_progress
        
        ; File System Identifier ('DZFSV1' in ASCII)
        ld      BC, 8
        ld      DE, DZFS_SBLOCK_FSID
        ld      HL, const_sd_fsid
        ldir
        call    format_progress
        
        ; Volume Serial Number
        ld      IX, DZFS_SBLOCK_SERNUM
        call    KRN_DZFS_CALC_SN
        call    format_progress
        
        ; Not used
        ld      A, $00
        ld      (DZFS_SBLOCK_NOTUSED2), A
        call    format_progress
        
        ; Volume label
        ld      IY, CLI_buffer_parm1_val    ; IY = address where the volname is stored (user input)
        ld      HL, DZFS_SBLOCK_LABEL       ; HL = address where the volname will be stored (DISK buffer)
        ld      B, 1                    ; character counter
_volname_loop:
        ld      A, (IY)                 ; volname character
        cp      0                       ; end of volname?
        jp      z, _volname_padding     ; yes, do the padding to 16 characters
        ld      (HL), A                 ; no, store it in DISK buffer
        inc     HL                      ; next char in DISK buffer
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
        
        ; Volume Date Creation
        call    F_KRN_RTC_GET_DATE

        ld      A, (RTC_day)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (DZFS_SBLOCK_DATECREA_DD), A
        ld      A, (tmp_addr1 + 5)
        ld      (DZFS_SBLOCK_DATECREA_DD + 1), A

        ld      A, (RTC_month)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (DZFS_SBLOCK_DATECREA_MM), A
        ld      A, (tmp_addr1 + 5)
        ld      (DZFS_SBLOCK_DATECREA_MM + 1), A

        ld      HL, (RTC_year4)
        call    F_KRN_BIN_TO_BCD6
        ex      DE, HL
        ld      DE, tmp_addr1
        call    F_KRN_BCD_TO_ASCII
        ; ex      DE, HL                  ; Move
        ; ld      DE, 4                   ;   pointer
        ; xor     A                       ;   4 bytes (1 per each digit)
        ; sbc     HL, DE                  ;   back
        ld      A, (tmp_addr1 + 2)
        ld      (DZFS_SBLOCK_DATECREA_YYYY), A
        ld      A, (tmp_addr1 + 3)
        ld      (DZFS_SBLOCK_DATECREA_YYYY + 1), A
        ld      A, (tmp_addr1 + 4)
        ld      (DZFS_SBLOCK_DATECREA_YYYY + 2), A
        ld      A, (tmp_addr1 + 5)
        ld      (DZFS_SBLOCK_DATECREA_YYYY + 3), A

        call    format_progress

        ; Volume Time creation
        call    F_BIOS_RTC_GET_TIME     ; Get time at the same time as date to avoid differences

        ld      A, (RTC_hour)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (DZFS_SBLOCK_TIMECREA_HH), A
        ld      A, (tmp_addr1 + 5)
        ld      (DZFS_SBLOCK_TIMECREA_HH + 1), A
        
        ld      A, (RTC_minutes)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (DZFS_SBLOCK_TIMECREA_MM), A
        ld      A, (tmp_addr1 + 5)
        ld      (DZFS_SBLOCK_TIMECREA_MM + 1), A
        
        ld      A, (RTC_seconds)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1
        ld      C, 0
        call    F_KRN_BCD_TO_ASCII
        ld      A, (tmp_addr1 + 4)
        ld      (DZFS_SBLOCK_TIMECREA_SS), A
        ld      A, (tmp_addr1 + 5)
        ld      (DZFS_SBLOCK_TIMECREA_SS + 1), A

        ; Bytes per Sector
        ld      HL, DZFS_BYTES_PER_SECTOR
        ld      (DZFS_SBLOCK_BYTESSEC), HL
        call    format_progress
        
        ; Sectors per Block
        ld      A, DZFS_SECTORS_PER_BLOCK
        ld      (DZFS_SBLOCK_SECBLOCK), A
        call    format_progress
        
        ; Not used
        ld      A, $00
        ld      (DZFS_SBLOCK_NOTUSED3), A
        call    format_progress
        
        ; Copyright notice
        ld      BC, 51
        ld      DE, DZFS_SBLOCK_COPYRIGHT
        ld      HL, const_sd_copyright
        ldir
        
        ; Rest 411 bytes are not used, lets set them as zeros.
        ld      HL, DZFS_SBLOCK_FILLER
        ld      BC, 411
        ld      A, $00
        call    F_KRN_SETMEMRNG

    ; If it's a FDD, turn the motor on
        ld      A, (DISK_current)
        cp      0
        jp      nz, _noFDD
        call    F_BIOS_FDD_MOTOR_ON
_noFDD:
    ; Superblock - Step 2: store bytes from DISK_BUFFER_START into the disk
        ld      DE, $0000               ; Superblock is located
        ld      (DISK_cur_sector), DE
        call    F_KRN_DZFS_SECTOR_TO_DISK

    ; BAT
        ; After format, the BAT should be empty (all zeros) 
        ld      HL, DISK_BUFFER_START     ; Empty the
        ld      BC, 512                 ;   DISK buffer (512 bytes)
        ld      A, $00                    ;   with
        call    F_KRN_SETMEMRNG         ;   zeros
        ; BAT is 1 Block (64 Sectors)
        ld      A, 64                   ; 64 times
        ld      (tmp_byte), A           ; counter
        ld      DE, $0001               ; BAT 1 starts at sector 1
        ld      (DISK_cur_sector), DE
        ld      IX, tmp_byte            ; Pointer to sector counter (64 times)
        ld      IY, DISK_cur_sector     ; Pointer to sector number
write_bat:
        call    F_KRN_DZFS_SECTOR_TO_DISK
        inc     (IY)                    ; Increment sector number
        dec     (IX)                    ; Decrement sector counter
        call    format_progress
        ld      A, (IX)
        cp      0                       ; Did write the 64 sectors?
        jp      nz, write_bat           ; No, then continue with more
        ; Change SYSVARS.DISK_is_formatted to $FF
        ld      A, $FF
        ld      (DISK_is_formatted), A
        call    F_BIOS_FDD_MOTOR_OFF
        ; If it was an SD Disk Image File, after formatting, ASMDC needs to
        ; close and re-open the image file
        ld      A, (DISK_current)
        cp      0
        ret     nz                      ; nothing to do with FDD
        call    F_BIOS_SD_PARK_DISKS    ; close
        call    F_BIOS_SD_MOUNT_DISKS   ; re-open
        call    F_BIOS_SD_GET_STATUS    ; any errors?
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
KRN_DZFS_SECTOR_TO_DISK:
; Calls the BIOS subroutine that will store the data (512 bytes) currently in
; Disk Buffer to the selected (DISK_current) disk
; IN <= SYSVARS.DISK_cur_sector = the sector in the disk that will be written
        ld      DE, (DISK_cur_sector)
        ld      BC, $0000
        call    F_BIOS_DISK_WRITE_SEC
        ret
;------------------------------------------------------------------------------
KRN_DZFS_GET_BAT_FREE_ENTRY:
; OUT => SYSVARS.DISK_cur_file_entry_number = available entry number
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
        ld      (DISK_cur_sector), A
        ld      A, 0
        ld      (DISK_cur_sector + 1), A
getbat_nextsector:
        call    F_KRN_DZFS_READ_BAT_SECTOR
        ; As we read in groups of 512 bytes (Sector), 
        ; each read will put 16 entries in the buffer.
        ; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
        ; therefore 64 sectors.
        ld      A, 0                            ; entry counter
getbat_entry:
        push    AF                              ; backup entry counter
        call    F_KRN_DZFS_BATENTRY_TO_BUFFER
        ; is the entry free (i.e. $00 as first byte of filename)?
        ld      A, (DISK_cur_file_name)
        cp      $00                                 ; is it a free entry?
        jp      nz, getbat_nextentry                ; no, check next entry
        ; cp      $7E                               ; is it a deleted file entry?
        ld      (DISK_cur_file_entry_number), IY    ; yes, store the entry number in SYSVARS
        pop     AF                                  ; needed because previous push AF

        ret                                     ; exit subroutine
getbat_nextentry:
        inc     IY
        pop     AF                              ; restore entry counter
        inc     A                               ; next entry
        cp      16                              ; did we process the 16 entries?
        jp      nz, getbat_entry                ; No, process next entry
        ; More entries in other sectors?
        ld      A, (DISK_cur_sector)
        inc     A                               ; increment sector counter
        ld      (DISK_cur_sector), A            ; Did we process
        cp      64                              ;    64 sectors already?
        jp      nz, getbat_nextsector           ; No, then process next sector
; ToDo - F_KRN_DZFS_GET_BAT_FREE_ENTRY: test for no free entries but delete files
; ToDo - F_KRN_DZFS_GET_BAT_FREE_ENTRY: test for no free entries and no deleted files
        ret                                     ; Yes, then nothing else to do
;------------------------------------------------------------------------------
KRN_DZFS_ADD_BAT_ENTRY:
; Adds a BAT entry to the disc
; IN <= DE = BAT entry number
;       SYSVARS.DISK_cur_sector = Sector number where the BAT Entry is
;       SYSVARS.DISK_BUFFER_START = Sector where the BAT Entry is, loaded from disc
;       SYSVARS.DISK BAT section = filled with new BAT Entry information
        ld      A, 32                       ; 32 bytes per entry
        call    F_KRN_MULTIPLY816_SLOW      ; HL = A * DE
        ld      DE, DISK_BUFFER_START
        add     HL, DE                      ; HL points to 1st character in DISK buffer
        ; Copy BAT Entry from SYSVARS to DISK Buffer
        ex      DE, HL                      ; DE points to 1st Entry byte in DISK buffer
        ld      HL, DISK_cur_file_name      ; HL points to 1st Entry byte in SYSVARS
        ld      BC, 32                      ; 32 bytes per entry
        ldir                                ; Copy BAT Entry from SYSVARS to DISK Buffer
        ret
;------------------------------------------------------------------------------
KRN_DZFS_CREATE_NEW_FILE:
; Creates a new file in the SD card, from bytes stored in RAM
; Also creates a BAT entry for the created file
; IN <= HL = address in memory of first byte to be stored
;       BC = number of bytes to be stored
;       IX = address where the filename is stored

        push    IX                                  ; backup filename address
        push    BC                                  ; backup number of bytes
        push    HL                                  ; backup address first byte to be stored

        call    F_KRN_DZFS_GET_BAT_FREE_ENTRY       ; DISK_cur_file_entry_number = available entry number
                                                    ; $FFFF means no space for more files
        ld      HL, (DISK_cur_sector)               ; backup
        ld      (tmp_addr1), HL                     ;   BAT sector
        ld      HL, (DISK_cur_file_entry_number)    ; backup BAT entry number
        ;   Clear (set to zeros) the BAT entry variables in SYSVARS
        ld      B, 32                               ; BAT entry in SYSVARS is 32 bytes
        ld      IX, DISK_cur_file_name              ; IX points to first byte of BAT entry
        call    F_KRN_CLEAR_MEMAREA

        ld      (DISK_cur_file_entry_number), HL    ; restore BAT entry number
        pop     HL                                  ; restore address first byte to be stored
        ld      (DISK_cur_file_load_addr), HL       ; and store it in SYSVARS
        ld      (tmp_addr3), HL                     ; use tmp_addr for adding to original address
        pop     BC                                  ; restore number of bytes
        ld      (DISK_cur_file_size_bytes), BC      ; and store it in SYSVARS

        ; How many sectors to write?
        ;   File size in sectors
        ld      DE, 512
        call    F_KRN_DIV1616           ; BC = BC (num bytes) / DE (512), HL = remainder
        ; A Block (64 Sectors) can store a single file. Hence, max. is 64
        ; Therefore, the result of the division will be stored in C
        ld      A, C
        ld      (DISK_cur_file_size_sectors), A     ; store it in SYSVARS
        ld      (tmp_byte), A                       ; backup sector counter, to use it to countdown saved sectors
        ld      (tmp_addr2), HL                     ; store remainder in temporary location for later use will saving

        ;   First Sector (65 + 64 * entry_number)
        ld      HL, 64
        ld      DE, (DISK_cur_file_entry_number)
        call    F_KRN_MULTIPLY1616
        ld      DE, 65
        add     HL, DE
        ld      (DISK_cur_file_1st_sector), HL      ; 1st Sector address
        ld      (DISK_cur_sector), HL
        jp      savef_multiple_sectors

savef_one_sector:
        ; Copy 512 bytes from original address into into DISK Buffer
        ld      BC, 512
        call    F_KRN_COPYMEM512
        ; Save DISK buffer to disk at SYSVARS.DISK_cur_sector
        call    F_KRN_DZFS_SECTOR_TO_DISK
        ; Add 512 to the address, so that next time we copy the next bytes
        ld      HL, (tmp_addr3)                 ; HL = start address of bytes to save
        ld      DE, 512
        add     HL, DE
        ld      (tmp_addr3), HL
        ; Decrement remaining sector counter by 1
        ld      HL, tmp_byte
        dec     (HL)
        ; Increment current sector by 1
        ld      HL, DISK_cur_sector
        inc     (HL)
savef_multiple_sectors:
        call    F_KRN_CLEAR_DISKBUFFER
        ld      HL, (tmp_addr3)             ; HL = start address of bytes to save
        ld      DE, DISK_BUFFER_START
        ; If DISK_cur_file_size_sectors > 0, then need to save multiple sectors
        ;                                   and n bytes (if tmp_addr2 > 0)
        ; Else, only need to save n bytes (n=tmp_addr2)
        ld      A, (tmp_byte)               ; remaining sectors to save
        cp      0                           ; more sectors?
        jp      nz, savef_one_sector        ; yes, save sector
savef_savelastbytes:                        ; no, save last bytes
        ; Any last bytes to copy?
        ld      HL, (tmp_addr2)
        ld      A, H
        or      L
        jp      z, savef_batentry           ; no, create BAT entry
                                            ; yes,  save last bytes
        ld      HL, DISK_cur_file_size_sectors
        inc     (HL)                        ; +1 sector, for the n bytes
        call    F_KRN_CLEAR_DISKBUFFER
        ; Copy n bytes from original address into into DISK Buffer
        ld      HL, (tmp_addr3)
        ld      DE, DISK_BUFFER_START
        ld      BC, (tmp_addr2)
        call    F_KRN_COPYMEM512
        ; Save disk buffer to disk at SYSVARS.DISK_cur_sector
        call    F_KRN_DZFS_SECTOR_TO_DISK
        call    F_BIOS_SD_BUSY_WAIT

        ld      HL, msg_sd_data_saved
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR

savef_batentry:
        ; Create BAT entry
        ;   Filename
        ld      B, 14                           ; filenames are max. 14 characters
        pop     IX                              ; restore filename address
        ld      HL, DISK_cur_file_name
loop_copy_fname:
        ld      A, (IX)                         ; A = filename character
        cp      0                               ; is it zero (no character)?
        jp      nz, loop_copy_fname_nopadded    ; no, then copy character
        ld      A, SPACE                        ; yes, add padding spaces
        jp      loop_copy_fname_padded          ;      and skip the next 'inc IX'
loop_copy_fname_nopadded:
        inc     IX
loop_copy_fname_padded:
        ld      (HL), A                         ;   copy to SYSVARS
        inc     HL
        djnz    loop_copy_fname                 ; copy until 14 characters done
        ;   Attributes ($08 = executable)
        ld      A, $08
        ld      (DISK_cur_file_attribs), A
        ;   Time created (and set Modified as the same)
        call    F_KRN_DZFS_CALC_FILETIME
        ; ld      HL, 0
        ld      (DISK_cur_file_time_created), HL
        ld      (DISK_cur_file_time_modified), HL
        ;   Date created (and set Modified as the same)
        call    F_KRN_DZFS_CALC_FILEDATE
        ld      (DISK_cur_file_date_created), HL
        ld      (DISK_cur_file_date_modified), HL

        ; Save BAT entry to disc
        ;   Read BAT from disc again, to finally update it
        ld      HL, (tmp_addr1)                 ; restore BAT sector number
        ld      (DISK_cur_sector), HL           ;   where the BAT entry was
        ld      DE, (DISK_cur_file_entry_number)
        push    DE                              ; backup BAT entry number
        call    F_KRN_DZFS_SEC_TO_BUFFER        ; Load BAT

        pop     DE                              ; restore BAT entry number
        call    F_KRN_DZFS_ADD_BAT_ENTRY        ; Update BAT and copy it to DISK Card Buffer
        call    F_KRN_DZFS_SECTOR_TO_DISK         ; Save buffer to disc

        ld      HL, msg_sd_bat_saved
        ld      A, ANSI_COLR_YLW
        call    F_KRN_SERIAL_WRSTRCLR
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
        ld      HL, msg_sd_vol_label
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 16                   ; counter
        ld      HL, DZFS_SBLOCK_LABEL   ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
        ; Volume Serial Number
        ld      HL, msg_sd_volsn
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, (DZFS_SBLOCK_SERNUM)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (DZFS_SBLOCK_SERNUM + $01)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (DZFS_SBLOCK_SERNUM + $02)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (DZFS_SBLOCK_SERNUM + $03)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ')'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Volume Date/Time Creation
        ld      HL, msg_sd_vol_creation
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, DZFS_SBLOCK_DATECREA        ; day
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, DZFS_SBLOCK_DATECREA + 2    ; month
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 4                            ; counter = 4 bytes
        ld      HL, DZFS_SBLOCK_DATECREA + 4    ; year
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, DZFS_SBLOCK_DATECREA + 8    ; hour
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, DZFS_SBLOCK_DATECREA + 10   ; minutes
        call    F_KRN_SERIAL_PRN_BYTES
        ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
        ld      B, 2                            ; counter = 2 bytes
        ld      HL, DZFS_SBLOCK_DATECREA + 12   ; seconds
        call    F_KRN_SERIAL_PRN_BYTES
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ret
;------------------------------------------------------------------------------
KRN_DZFS_SHOW_DISKINFO:
        call    F_KRN_DZFS_SHOW_DISKINFO_SHORT

        ; File System id
        ld      HL, msg_sd_filesys
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      B, 8                            ; counter = 4 bytes
        ld      HL, DZFS_SBLOCK_FSID            ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
        ld        B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        ; Bytes per Sector
        ld      HL, msg_sd_bytes_sector
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      HL, (DZFS_SBLOCK_BYTESSEC)
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
        ld      HL, msg_sd_sectors_block
        ld      A, ANSI_COLR_GRN
        call    F_KRN_SERIAL_WRSTRCLR
        ld      A, (DZFS_SBLOCK_SECBLOCK)
        call    F_KRN_BIN_TO_BCD4
        ld      DE, tmp_addr1                   ; temp storage for converted digits
        call    F_KRN_BCD_TO_ASCII              ; convert decimal to hex ASCII string
        ld      A, (tmp_addr1 + 4)              ; only need
        call    F_BIOS_SERIAL_CONOUT_A          ;   to print
        ld      A, (tmp_addr1 + 5)              ;   the last
        call    F_BIOS_SERIAL_CONOUT_A          ;   two digits
        ret
;------------------------------------------------------------------------------
KRN_DZFS_CHECK_FILE_EXISTS:
; Checks if a filename exists in the disk
; IN <= HL = Address where the filename to check is stored
; OUT => Zero Flag set if filename not found
        ld      DE, $BAAB                       ; Store a default value
        ld      (tmp_addr3), DE                 ;   so that we can use it to check
                                                ;   if filename was found
        call    F_KRN_DZFS_GET_FILE_BATENTRY    ; if a file is found, tmp_addr3 = $0000 

        ; Check that the bytes where replaced (i.e. are not $BAAB)
        ;   meaning the file exists
        ld      A, (tmp_addr3)
        cp      $AB
        ret     z                               ; Zero Flag set if default value not replaced
        ld      A, (tmp_addr3 + 1)
        cp      $BA
        ret                                     ; Zero Flag set if default value not replaced