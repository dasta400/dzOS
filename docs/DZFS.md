# DZFSV1 (DastaZ File System Version 1)

This is my first time designing a file system, so I'll keep it very simple:

The free RAM of dastaZ80 is about 55,952 bytes, therefore it makes no sense to have files bigger than that, as it will not fit.

* **Bytes per Sector**: 512
* **Sectors per Block**: 64
* **Bytes per Block**: 32,768 (64 * 512). This also defines the max. size of a file and the BAT size
* **Bytes per BAT entry**: 32
* **BAT entries**: 1024 (32,768 / 32). This also defines the max. number of files per Partition.
* **Blocks per Partition**: 1,024 (1 reserved for BAT)
* **Sectors per Partition**: 65,536 (1,024 * 64)
* **Bytes per Partition**: 33,587,200 (1,024 * 32,768 + 1 BAT Block)
* **Partitions per Disk**: 3 (125 MB((I'm assuming that 128 MB CF cards are not really 128)) / 33,587,200)

## Disk anatomy

A disk is divided into areas:

* **Superblock** = 512 bytes
* **Block Allocation Table (BAT)** = 1 Block
* **Data Area** = 1023 Blocks
  
## Superblock

The first 512 bytes on the disk contain fundamental information about the disk geometry, and is used by the OS to know how to access every other information on the disk. On IBM PC-compatibles, this is known as the *Master Boot Record* or *MBR* for short. I decided to call it *Superblock*, as it is an orphan sector that doesn't belong to any block.

| Offset | Length (bytes) | Description | Example |
| ------ | -------------- | ----------- | ------- |
| $00    | 2              | Signature. Used to check that this is a Superblock. Set to ABBA|AB BA|
| $02    | 1              | Not used.|00|
| $03    | 8              | File system identifier. ASCII values for human-readable. Padded with spaces. | DZFSV1 |
| $0B    | 4              | Volume serial number | 35 2A 15 F2 |
| $0F    | 1              | Not used.|00|
| $10    | 16             | Volume Label. ASCII values. Padded with spaces. | dastaZ80 Main |
| $20    | 8              | Volume Date creation. ASCII values (ddmmyyyy).|03102012|
| $28    | 6              | Volume Time creation. ASCII values (hhmmss).|142232|
| $2E    | 2              | Bytes per Sector (in Hexadecimal little-endian)|00 02|
| $30    | 1              | Sectors per Block (in Hexadecimal little-endian)|40|
| $31    | 1              | Not used.|00|
| $32 - $64 | 51 | Copyright notice (ASCII value) | Copyright 2022  David Asta    The MIT License (MIT)|
| $65-$1FF | 477          | Not used (filled with $00)|00 00 00 00 00 00 00 .........|

### Example

Non-printable characters are shown as dots.

```text
Offset  00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F   0123456789ABCDEF
---------------------------------------------------------------------------
0000    AB BA FF 44 5A 46 53 56 31 20 20 35 2A 15 F2 00   ½..DZFSV1  5*§≥
0010    64 61 73 74 61 5A 38 30 20 4D 61 69 6E 20 20 20   dastaZ80 Main
0020    32 30 30 36 32 30 32 32 32 30 35 39 33 32 00 02   20062022205932..
0030    40 00 43 6F 70 79 72 69 67 68 74 20 32 30 32 32   @.Copyright 2022
0040    44 61 76 69 64 20 41 73 74 61 20 20 20 20 20 20   David Asta
0050    54 68 65 20 4D 49 54 20 4C 69 63 65 6E 73 65 20   The MIT License
0060    28 4D 49 54 29 00 00 00 00 00 00 00 00 00 00 00   (MIT)
...
01F0    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

## Block Allocation Table (BAT)

The BAT is an area of 1 Block (64 Sectors, 32,7682) bytes) on the disk used to store the details about the files saved in the Data Area, and is comprised of file descriptors called *entry*. Each entry (32 bytes) holds information about a single file. The BAT can hold 1,024 entries (32,768 / 32).

For simplicity, each entry works also as index. The first entry describes the first file on the disk, the second entry describes the second file, and so on.

| Offset | Length (bytes) | Description | Example |
| ------ | -------------- | ----------- | ------- |
| $00    | 14  | **Filename** | 46 49 4C 45 30 30 30 30 31 20 20 20 20 20 |
|        |     | Padded with spaces at the end||
|        |     | (only allowed A to Z and 0 to 9. No spaces allowed. Cannot start with a number.)||
|        |     | First character also indicates 00=available, 7E=deleted (will appear as ~)||
| $0E    | 1   | **Attributes** (Bits 0=Inactive / 1=Active) | Read Only, System file, Executable = 1101 = 0D |
|        |     | Bit 0 = Read Only |  |
|        |     | Bit 1 = Hidden |  |
|        |     | Bit 2 = System |  |
|        |     | Bit 3 = Executable |  |
|        |     | Bit 4-7 = Not used|  |
| $0F    | 2   | **Time created** | F5 9A|
|        |     | 5 bits for hour (binary number of hours 0-23)||
|        |     | 6 bits for minutes (binary number of minutes 0-59)||
|        |     | 5 bits for seconds (binary number of seconds / 2)||
| $11    | 2   | **Date created** | 69 1B|
|        |     | 7 bits for year since 2000 (max. is year 2127)||
|        |     | 4 bits for month (binary number of month 0-12)||
|        |     | 5 bits for day (binary number of day 0-31)||
| $13    | 2   | **Time last modified** (same formula as Time created)|F5 9A|
| $15    | 2   | **Date last modified** (same formula as Date created)|69 1B|
| $17    | 2   | **File size in bytes** (little-endian)| 26 00|
| $19    | 1   | **File size in sectors** (little-endian)| 01|
| $1A    | 2   | **Entry number** (little-endian)| 00 00|
| $1C    | 2   | **1st Sector** where the file data starts| 41 00|
|        |     | It's calculated when the file is created. The formula is: 65 + 64 * entry_number ||
| $1E    | 2   | **Load address** (The start address little-endian where it will be loaded in RAM)|68 25|

### Example (one Entry)

```text
Offset  00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F   0123456789ABCDEF
--------------------------------------------------------------------------
0000    46 49 4C 45 30 30 30 30 31 20 20 20 20 20 0D 9A   FILE00001     .š
0010    F5 1B 69 9A F5 1B 69 26 00 01 00 00 41 00 70 25   õ.išõ.i&....A.p%
```

## Data Area

The Data Area is the area of the disk used to store file data (e.g. programs, documents). It's divided into blocks (called Clusters) of 128 sectors each.
