# dzos

1. [Project Status](#project-status)
    * [Hardware](#hardware)
    * [Software](#software)
    * [TODOs](#todos)
    * [Known BUGS](#known-bugs)
1. [Manuals and Guides](#manuals-and-guides)
1. [User Modifiable Operating System (Paged ROM and Jumpblocks)](#user-modifiable-operating-system-paged-rom-and-jumpblocks)
1. [dzOS available commands](#dzos-available-commands)
    * [General commands](#general-commands)
    * [Disk commands](#disk-commands)
    * [Memory commands](#memmory-commands)
    * [Real-Time Clock (RTC) commands](#real-time-clock-rtc-commands)
1. [How to use the SD Card module](#how-to-use-the-sd-card-module)
1. [Versioning System](#versioning-system)

---

dzOS is a single-user single-task ROM-based operating system (OS) for the 8-bit homebrew computer **dastaZ80**, which runs on a Zilog Z80 processor. It is heavily influenced by ideas and paradigms coming from Digital Research’s CP/M, so some concepts may sound familiar to those who had the privilege of using this operating system.

The OS consists of three parts:

* The **BIOS**, that provides functions for controlling the hardware.
* The **Kernel**, which provides general functions for everything that is not hardware dependent.
* The **Command-Line Interface (CLI)**, that provides commands for the user to talk to the Kernel and BIOS.

The Kernel and the CLI are hardware independent and will work on any Z80 based computer. Therefore, by adapting the BIOS code, **dzOS can easily be ported to other Z80 systems**.

![dzOS v2022.11.22.18.19](https://github.com/dasta400/dzOS/blob/master/docs/dzOSv2022.11.22.18.19.png "dzOS v2022.11.22.18.19")

---

## Project Status

I've decided to divide the project into progressive models (or **Mark**, as I call it).

* Current model: **Mark I**

### Hardware

* **CPU**: Z80 @ 7.3728 Mhz
* **ROM**: 16 KB with DZOS ([User Modifiable Operating System](#user-modifiable-operating-system-paged-rom-and-jumpblocks))
* **RAM**: 64 KB (~48 KB free). Lower 16 KB used by DZOS. Then approx. 1 KB for Stack, variables and Buffers. Free RAM starts at address 0x4420
* **Video output**: 80x25 Colour ANSI Terminal, via [LILYGO TTGO VGA32 V1.4](http://www.lilygo.cn/prod_view.aspx?TypeId=50033&Id=1083&FId=t3:50033:3) connected to the TX signal of the SIO/2 Channel A
* **Keyboard**: Acorn Archimedes A3010 keyboard connected to the RX signal of the SIO/2 Channel A
  * Implemented:
    * Alphabetic: A to Z
    * Number: 1 to 0
    * Symbols: `~!@#$%^&*()-_=+[{]}\|;:'",<.>/?
    * Shift key modifier: for capital alphanumeric letters and symbols
    * CapsLock key modifier
    * LEDs: Power, CapsLock, ScrollLock, NumLock, Disk activity
    * Keypad: 1 to 0, /*#-+. and Enter
    * Special keys
      * ScrollLock key: allows keyboard to be used as USB keyboard when ScrollLock LED is ON
      * Break: clears the screen
  * Not implemented:
    * Function keys: F1 to F12
    * Pound key
    * Control keys: Esc, Tab, Ctrl, Alt, Backspace
    * Special keys: Print, Insert, Home, Delete, etc.
    * Multiple modifier keys (e.g. Ctrl + Shift + key, Alt + Shift + key)
* **Power Supply**: 12V External Power Supply with 5V/3A Regulator
* **Arduino Serial Multi-Device Controller ([ASMDC](https://github.com/dasta400/ASMDC))**: An Arduino board acting as a _man-in-the-middle_ to allow dastaZ80 to communicate with different devices:
  * **Micro SD Card**: FAT32 formatted, with disk image files that dastaZ80 can use.
  * **Real-Time Clock (RTC)**: Battery (CR2032) backed.
  * **NVRAM**: 56 bytes.
* **Case**: Acorn Archimedes A3010 all-in-one computer case
  * Connectors:
  * DE-15 female connecto (VGA)
  * Micro SD Card slot
  * 2.1mm Barrel Power Jack (Power Supply)
  * Others:
    * Switch ON/OF (Power)
    * Tactile switch (reset)

![dzOS v2022.07.19.13](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80BlockDiagram.png "dastaZ80 Block Diagram")

### Software

* Keyboard Controller Arduino code for Teensy++ 2.0 ([folder src/A3010KBD](https://github.com/dasta400/dzOS/tree/master/src/A3010KBD))
* [FabGL Library](http://www.fabglib.org/) Arduino code for VGA32 ([folder src/VGA32](https://github.com/dasta400/dzOS/tree/master/src/VGA32))
* **OS**:
  * **BIOS** & **Kernel**:
    * Communicates with the Keyboard Controller to communicate with the Keyboard.
    * Communicates with the Video Interface to generate VGA output.
    * Communicates with [ASMDC](https://github.com/dasta400/ASMDC) to control RTC, NVRAM and Micro SD card.
    * **DZFS** (dastaZ80 File System) **This file system is still in experimental phase. Lost of data may occur due to unknown bugs or changes in specifications.**
  * **Command Line Interface (CLI)**:
    * Shows prompt
    * Reads input from keyboard and calls subroutines to the corresponding commands entered by the user.
    * Displays inforamtion back to the user.

### TODOs

* ✔ ~~Do not allow renaming System or Read Only files.~~
* ✔ ~~Do not allow deleting System or Read Only files.~~
* ✔ ~~Disable disk commands if at boot the CF card was detected as not formatted.~~
* Make "_Attributes_" and "_Load Address_", of command _cat_, to print in the same column.
* When _load_ or _run_, if the file has the attribute _E_, ignore the load address stored in BAT and instead load at the address specified in the binary.

### Known BUGS

* ✔ ~~_run_, _rename_, _delete_ and _chgaatr_, are not taking in consideration the full filename (e.g. _disk_ is acting on file _diskinfo_)~~
* ✔ ~~Keyboard controller is sending character for each press of special keys (e.g. Shift)~~
* F_KRN_DZFS_GET_BAT_FREE_ENTRY not finished (doesn't check of deleted files if no available entries found).

---

## Manuals and Guides

* [User’s Manual](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20(Mark%20I)%20Manual%20-%20User%E2%80%99s%20Manual.pdf)
* [Programmer’s Reference Guide](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20(Mark%20I)%20Manual%20-%20Programmer%E2%80%99s%20Reference%20Guide.pdf)
* [Technical Reference Manual](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20(Mark%20I)%20Manual%20-%20Technical%20Reference%20Manual.pdf)
* [Memory Map](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20Memory%20Map.ods)

---

## User Modifiable Operating System (Paged ROM and Jumpblocks)

At boot, the contents of the ROM (containing DZOS) are copied to High RAM (starting at $8000), then the ROM chip is disabled and the contents of DZOS (now at $8000) are copied to Low RAM (starting at $0000). Then DZOS is started, running only from RAM. Thus, the entire operating system can be modified by the user.

But changing subroutines that fit exactly in the same number of bytes, so that others are not overwritten, would be very difficult. And that's where _Jumpblocks_ come in handy.

All DZOS subroutines are called via _Jumpblocks_. These jumpblocks are simple _JP_ (jump) instructions to where the subroutine code is located in memory. By changing the two bytes (address) of a jump instruction, a subroutine can be redirected to a different one.

All jumpblock addresses can be found in the _.exp_ files in the _exp_ folder. Or in the documentation.

For example, imagine we're testing a new (hopefully better) subroutine for division of two 16-bit numbers. Looking at the file _kernel.exp_, we find that _F_KRN_DIV1616_ is located at $26DD. If we look at the contents of the three bytes starting at that address (e.g. with command _peek_), we will find _C3 60 17_. This means that whenever a program calls _F_KRN_DIV1616_, it does a jump (opcode C3) to address $1760 (stored as little-endian), which is where the subroutine code starts. But what we want is to jump to our code instead.

First we put the assembled code of our new subroutine somewhere in RAM (e.g. $5000). Next we change the jump by changing the address bytes with _poke 26de,00_ and _poke 26df,50_. The opcode _C3_ (jump) MUST not be changed.

Now, whenever a program, and even DZOS, calls _F_KRN_DIV1616_, will be jumping to our new subroutine at $5000

Jumpblocks also allow me to change the subroutines in DZOS without altering the address that is seen by the calling subroutines, thus keeping retrocompatibility with previous versions of the operating system.

---

## dzOS available commands

For more detailed information, check the [dastaZ80 User's Manual](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20(Mark%20I)%20Manual%20-%20User%E2%80%99s%20Manual.pdf).

### General commands

* **help**: shows a list of some commands, with a short description and usage example.
* **run _[address]_**: moves the Program Counter (PC) to the specified RAM address, so that start execution.
* **crc16 _[address_start]_,_[address_end]_**: Generates and prints a 16-bit cyclic redundancy check (CRC) based on the IBM Binary Synchronous Communications protocol (BSC or Bisync), for the bytes between start and end address.
* **reset**: clears RAM (sets all to $00) and resets the system.
* **halt**: halts the system.

### Disk commands

* **cat**: shows disk (SD Card) catalogue.
* **load _[filename]_**: loads specified filename from disk to RAM.

* **run _[filename]_,_[parameters]_**: executes a load _[filename]_ and run _[address]_.
* **formatdsk _[label]_,_[num_partitions]_**: formats an Image File in the SD Card with DZFS.
* **rename _[old_filename]_,_[new_filename]_**: changes the name of file old_filename to new_filename.
* **delete _[filename]_**: deletes filename. Data isn't deleted, just the first character of the filename in the BAT is set to 7E (~), so it can be undeleted. Be aware, that the save command will always search for an empty entry in the BAT, but if it finds none, then it will re-use the first entry of a deleted file. Therefore, undelete of a file is only guaranteed if no file was created since the delete command was issued.
* **chgattr _[filename]_,_[new_attributes(RHSE)]_**: changes the attributes of filename to the new specified attributes.
* **save _[address_start]_,_[number_bytes]_**: creates a new file on the CF card, that will contain _n_ number of bytes, starting at the specified address. After entering the command, the user will be prompted to type the filename.

### Memmory commands

* **memdump _[address_start]_,_[address_end]_**: shows all the contents of memory (ROM/RAM) from address_start to address_end.
* **peek _[address]_**: shows the value stored at address.
* **poke _[address]_,_[value]_**: stores value at the specified address.
* **autopoke _[start_address]_**: allows to enter hexadecimal values that will be stored at the start_address and consecutive positions. The address is incremented automatically after each hexadecimal value + press of ENTER key. Entering no value (i.e. just press ENTER) will stop the process. I made this so that I can enter assembled programs, as Mark I doesn't have any means of loading programs.
* **clrram**: fills with zeros the entire Free RAM area (i.e. from 0x4420 to 0xFFFF).

### Real-Time Clock (RTC) commands

* **date**: shows the current date.
* **time**: shows the current time.
* **setdate**: changes the date stored in the RTC.
* **settime**: changes the time stored in the RTC.

---

## How to use the SD Card module

We will need:

* Linux Terminal.
* A Micro SD Card formatted with FAT32 file system.
* [Arduino Serial Multi-Device Controller (ASMDC)](https://github.com/dasta400/ASMDC) connected to SIO/2 Channel B at 115,200 8N1

Follow the steps:

1. Open a Linux Terminal
1. Create a 128 MB file: _fallocate -l $((128 * 1024 * 1024)) myimage.img_
1. Copy _myimage.img_ into the Micro SD Card
1. Insert the Micro SD Card in the MicroSD Card Adapter
1. Turn dastaZ80 on, and format the disk: _formatdsk mydisk_

Alternatively, the image file can be formatted with _imgmngr_ (tool provided with [ASMDC](https://github.com/dasta400/ASMDC)): _imgmngr -new myimage.img mydisk_

---

## Versioning System

### Releases

A release of DZOS contains all three parts (referred as _Components_), and is named as _dzOS.yyyy.mm.dd.hh.mm.bin_, where:

* **_yyyy_** is the **year** the released binary was created.
* **_mm_**  is the **month** the released binary was created.
* **_dd_** is the **day** the released binary was created.
* **_hh_** is the **hour** the released binary was created.
* **_mm_** is the **minutes** the released binary was created.

### Components

As components we understand the **BIOS**, the **Kernel** and the **Command-Line Interface (CLI)**. These components are versioned as _component_name v_ and then _maj.min.patch_ (e.g. Kernel v0.1.0), where:

* **_maj_** indicates a **major change** in functionality. Some features may be imcompatible with previous major version.
* **_min_** indicates adding of **new features**.
* **_patch_** indicates **bug solving** of current functionality/features.

During initial development, until I decide that DZOS is stable enough to be used, all components will have v0.1.0. After that, I will release v1.0.0 and then the _maj.min.patch_ will start applying.
