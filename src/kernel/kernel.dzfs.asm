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
		ld		A, $FF
		ld		(cf_is_formatted), A

        ; Show Volume Serial Number
        ld      HL, msg_volsn
        call    F_KRN_SERIAL_WRSTR
        ld      A, (CF_SBLOCK_SERNUM)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $01)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $02)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, (CF_SBLOCK_SERNUM + $03)
        call    F_KRN_SERIAL_PRN_BYTE
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES

		; Show Volume Label
        ld      HL, msg_vol_label
        call    F_KRN_SERIAL_WRSTR
		ld      B, 16                        ; counter = 4 bytes
        ld      HL, CF_SBLOCK_LABEL          ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES

        ; Show File System id
        ld      HL, msg_filesys
        call    F_KRN_SERIAL_WRSTR
        ld      B, 8                        ; counter = 4 bytes
        ld      HL, CF_SBLOCK_FSID          ; point HL to offset in the buffer
        call    F_KRN_SERIAL_PRN_BYTES
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES

		; Show Date/Time Creation
        ld      HL, msg_vol_creation
        call    F_KRN_SERIAL_WRSTR
		ld      B, 2                        	; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA			; day
        call    F_KRN_SERIAL_PRN_BYTES
		ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
		ld      B, 2                        	; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 2		; month
        call    F_KRN_SERIAL_PRN_BYTES
		ld      A, '/'
        call    F_BIOS_SERIAL_CONOUT_A
		ld      B, 4                        	; counter = 4 bytes
        ld      HL, CF_SBLOCK_DATECREA + 4	    ; year
        call    F_KRN_SERIAL_PRN_BYTES
		ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
		ld      B, 2                        	; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 8		; hour
        call    F_KRN_SERIAL_PRN_BYTES
		ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
		ld      B, 2                        	; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 10		; minutes
        call    F_KRN_SERIAL_PRN_BYTES
		ld      A, ':'
        call    F_BIOS_SERIAL_CONOUT_A
		ld      B, 2                        	; counter = 2 bytes
        ld      HL, CF_SBLOCK_DATECREA + 12		; seconds
        call    F_KRN_SERIAL_PRN_BYTES
		ld		B, 1
		call	F_KRN_SERIAL_EMPTYLINES

		; Show number of partitions
		ld		HL, msg_num_partitions
		call    F_KRN_SERIAL_WRSTR
		ld      A, (CF_SBLOCK_NUMPARTITIONS)
        call    F_KRN_SERIAL_PRN_BYTE
		; Set partition 0 as default
		ld		A, 0
		ld		(cur_partition), A
        ret

error_signature:
        ; Superblock didn't have the correct signature
		; change flag in SYSVARS
		ld		A, $00
		ld		(cf_is_formatted), A
        ; Show a message telling that the disk is unformatted
        ld      HL, msg_unformatted
        call    F_KRN_SERIAL_WRSTR
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_READ_BAT_SECTOR:     .EXPORT     F_KRN_DZFS_READ_BAT_SECTOR
; Read a BAT Sector into RAM buffer
; IN <= value stored in SYSVAR's cur_sector
        ; ld      A, 1
        ; ld      (cur_sector), A
        ; ld      A, 0
        ; ld      (cur_sector + 1), A
load_sector:
        ld      HL, (cur_sector)
        ld      BC, 0
        call	F_KRN_DZFS_SEC2BUFFER	; load sector into RAM buffer

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
        ld      DE, cur_file_name           ; destination address
        ldir                                ; copy BC bytes from HL to DE
        ; Attributes (1 byte) starting at offset $0E
        ld      A, (IX + $0E)
        ld      (cur_file_attribs), A
        ; Time created (2 bytes) starting at offset $0F
        ld      A, (IX + $0F)
        ld      (cur_file_time_created), A
        ld      A, (IX + $10)
        ld      (cur_file_time_created + 1), A
        ; Date created (2 bytes) starting at offset $11
        ld      A, (IX + $11)
        ld      (cur_file_date_created), A
        ld      A, (IX + $12)
        ld      (cur_file_date_created + 1), A
        ; Time last modified (2 bytes) starting at offset $13
        ld      A, (IX + $13)
        ld      (cur_file_time_modified), A
        ld      A, (IX + $14)
        ld      (cur_file_time_modified + 1), A
        ; Date last modified (2 bytes) starting at offset $15
        ld      A, (IX + $15)
        ld      (cur_file_date_modified), A
        ld      A, (IX + $16)
        ld      (cur_file_date_modified + 1), A
        ; File size in bytes (2 bytes) starting at offset $17
        ld      A, (IX + $17)
        ld      (cur_file_size_bytes), A
        ld      A, (IX + $18)
        ld      (cur_file_size_bytes + 1), A
		; File size in sectors (1 byte) starting at offset $19
        ld      A, (IX + $19)
        ld      (cur_file_size_sectors), A
        ; Entry number (2 bytes) starting at offset $1A
        ld      A, (IX + $1A)
        ld      (cur_file_entry_number), A
        ld      A, (IX + $1B)
        ld      (cur_file_entry_number + 1), A
		; First sector (2 bytes) starting at offset $1C
		ld      A, (IX + $1C)
        ld      (cur_file_1st_sector), A
        ld      A, (IX + $1D)
        ld      (cur_file_1st_sector + 1), A
        ; Load address (2 bytes) starting at offset $1E
        ld      A, (IX + $1E)
        ld      (cur_file_load_addr), A
        ld      A, (IX + $1F)
        ld      (cur_file_load_addr + 1), A
        ret
;------------------------------------------------------------------------------
F_KRN_DZFS_SEC2BUFFER:
; Loads a Sector (512 bytes) and puts the bytes into RAM buffer
; IN <=  HL = Sector number
; OUT => CF_BUFFER_START is filled with the read 512 bytes
	ex		de, hl					; D sector address LBA 1 (bits 8-15)
									; E sector address LBA 0 (bits 0-7)
	; ld		bc, 0				; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
	call	F_BIOS_CF_READ_SEC		; read 1 sector (512 bytes)
	ret
;------------------------------------------------------------------------------
F_KRN_DZFS_GET_FILE_BATENTRY:           .EXPORT         F_KRN_DZFS_GET_FILE_BATENTRY
; Gets the BAT's entry number of a specified filename
; IN <= HL = Address where the filename to check is stored
; OUT => HL = Entry number corresponding to the filename
        ld      DE, $BAAB                       ; Store a default value
        ld      (tmp_addr3), DE                 ;   so that we can use it to check
                                                ;   if filename was found

        ld      (tmp_addr2), HL                 ; Store address of filename to check
        ld      A, 1							; BAT starts at sector 1
        ld      (cur_sector), A
        ld      A, 0
        ld      (cur_sector + 1), A
bat_nextsector:
	call	F_KRN_DZFS_READ_BAT_SECTOR
	; As we read in groups of 512 bytes (Sector), 
	; each read will put 16 entries in the buffer.
	; We need to read a maxmimum of 1024 entries (i.e BAT max entries),
	; therefore 64 sectors.
	ld	A, 0				; entry counter
        ; ld      (tmp_byte), A
bat_entry:
	push 	AF                              ; backup entry counter
	call	F_KRN_DZFS_BATENTRY2BUFFER
        ; Get length of specified filename
        ld      A, $00                          ; filename to check ends with space
        ld      HL, (tmp_addr2)                 ; HL = address of filename to check
        call    F_KRN_STRLEN                    ; B = length of filename to check
        ; Check if filename in buffer is equal to the specified filename
        ld      DE, (tmp_addr2)                 ; DE = address of filename to check
        ld      HL, cur_file_name               ; HL = address of filename in BAT entry
        ld      A, 16                           ; filename in BAT entry is 16 characters
        call    F_KRN_STRCMP                    ; Are the same?
        jp      nz, bat_nextentry               ; No, skip entry
        ld      DE, $0000                       ; Yes, reset tmp_addr3
        ld      (tmp_addr3), DE                 ; if equal $0000, filename was found
                                                ; if equal $ABBA, not found
        pop     AF                              ; needed because previous push AF
        ret                                     ; exit subroutine
bat_nextentry:
	pop	AF                              ; restore entry counter
	inc	A				; next entry
	cp	16				; did we process the 16 entries?
	jp	nz, bat_entry   		; No, process next entry
	; More entries in other sectors?
	ld	A, (cur_sector)
	inc	A				; increment sector counter
	ld	(cur_sector), A			; Did we process
	cp	64				;    64 sectors already?
; TODO - Change this 64, to be read from Superblock's Sectors per Block
	jp	nz, bat_nextsector              ; No, then process next sector
bat_end:	
	ret	        			; Yes, then nothing else to do
;------------------------------------------------------------------------------
F_KRN_DZFS_LOAD_FILE_TO_RAM:            .EXPORT         F_KRN_DZFS_LOAD_FILE_TO_RAM
; Load a file from CF into RAM, at the specified address
; IN <= HL load address in RAM
;       DE 1st sector
;		IX length in sectors
;
		ld		(cur_sector), IX			; sector counter
		ld		IX, cur_sector				; pointer to sector counter
		; set up LBA addressing
loadfile:
		ld		B,	0
		ld		A, (cur_partition)
		ld		C, A
		call	F_BIOS_CF_READ_SEC		; read 1 sector (512 bytes)
		; Copy file data from buffer to load address
		ld      BC, 512
        ld      HL, CF_BUFFER_START
        ld      DE, (cur_file_load_addr)
        ldir

		dec		(IX)					; decrement sector counter
		or		(IX)					; is it 0?
		ret		z	 					; yes, exit subroutine
		inc		DE						; no, increment sector number
		jp		loadfile				;     and read more sectors

;==============================================================================
; Messages
;==============================================================================
msg_volsn:
        .BYTE   "      Volume S/N : ",0
msg_vol_label:
        .BYTE   "      Label  . . : ",0
msg_vol_creation:
        .BYTE   "      Created on : ",0
msg_num_partitions:
        .BYTE   "      Partitions : ",0
msg_filesys:
		.BYTE 	"      File System: ", 0
msg_unformatted:
        .BYTE   "    The CF disk appears to be unformatted", 0
