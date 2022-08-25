# dzos

dzOS is a single-user single-task ROM-based operating system (OS) for the 8-bit homebrew computer **dastaZ80**, which runs on a Zilog Z80 processor. It is heavily influenced by ideas and paradigms coming from Digital Research’s CP/M, so some concepts may sound familiar to those who had the privilege of using this operating system.

The OS consists of three parts:

* The **BIOS**, that provides functions for controlling the hardware.
* The **Kernel**, which provides general functions for everything that is not hardware dependent.
* The **Command-Line Interface (CLI)**, that provides commands for the user to talk to the Kernel and BIOS.

The Kernel and the CLI are hardware independent and will work on any Z80 based computer. Therefore, by adapting the BIOS code, **dzOS can easily be ported to other Z80 systems**.

![dzOS v2022.07.19.13](https://github.com/dasta400/dzOS/blob/master/docs/dzOS%20v2022.07.19.13.png "dzOS v2022.07.19.13")

---

## Project Status

I've decided to divide the project into progressive models (or **Mark**, as I call it).

* Current model: **Mark I**
  * **Hardware**:
    * **CPU**: Z80 @ 7.3728 Mhz
    * **ROM**: 16 KB with DZOS ([User Modifiable Operating System](#user-modifiable-operating-system-paged-rom-and-jumpblocks))
    * **RAM**: 64 KB (~48 KB free). Lower 16 KB used by DZOS. Then approx. 1 KB for Stack, variables and Buffers. Free RAM starts at address 0x4420
    * **Video output**: 80x25 Colour ANSI Terminal, via [LILYGO TTGO VGA32 V1.4 ](http://www.lilygo.cn/prod_view.aspx?TypeId=50033&Id=1083&FId=t3:50033:3) connected to the TX signal of the SIO/2 Channel A
    * **Keyboard**: Acorn Archimedes A3010 keyboard connected to the RX signal of the SIO/2 Channel A
      * Implemented:
        * Alphabetic: A to Z
        * Number: 1 to 0
        * Symbols: `~!@#$%^&*()-_=+[{]}\|;:'",<.>/?
        * Shift key modifier: for capital alphanumeric letters and symbols
        * Keypad: 1 to 0, /*#-+. and Enter
      * Not implemented:
        * Function keys: F1 to F12
        * Control keys: Esc, Tab, Ctrl, Alt, CapsLock, NumLock, Backspace, Cursor
        * Special keys: Print, Break, Insert, Home, Delete, etc.
        * Multiple modifier keys (e.g. Ctrl + Shift + key, Alt + Shift + key)
        * LEDs: CapsLock, Scroll Lock, Num Lock, Power, Disk activity
        * Pound key
    * **Power Supply**: 12V External Power Supply with 5V/3A Regulator
    * **Removable storage**: 128 MB CompactFlash formatted with DZFS (1 single partition)
    * **Case**: Acorn Archimedes A3010 all-in-one computer case
      * Connectors:
        * DE-15 female connecto (VGA)
        * CompactFlash card slot (CF)
        * 2.1mm Barrel Power Jack (Power Supply)
      * Others:
        * Switch ON/OF (Power)
        * Tactile switch (reset)
        * DIP switch 2 way, for selecting ROM address to boot from (e.g. DZOS, [DRI CP/M](https://en.wikipedia.org/wiki/CP/M) or [Small Computer Monitor (SCM)](https://smallcomputercentral.wordpress.com/small-computer-monitor/))

  * **Software**:
    * Keyboard Controller Arduino code for Teensy++ 2.0 ([folder src/A3010KBD](https://github.com/dasta400/dzOS/tree/master/src/A3010KBD))
    * [FabGL Library](http://www.fabglib.org/) Arduino code for VGA32 ([folder src/VGA32](https://github.com/dasta400/dzOS/tree/master/src/VGA32))
    * **OS**:
      * **BIOS** & **Kernel**:
        * Talks with the Keyboard Controller to communicate with the Keyboard.
        * Talks with the Video Interface to generate VGA output.
        * **DZFS** (dastaZ80 File System) read/write, 1 partition. **This file system is still in experimental phase. Lost of data may occur due to unknown bugs.**
      * **Command Line Interface (CLI)**:
        * Shows prompt, reads input from keyboard and calls subroutines corresponding to commands entered by the user.
        * Available commands (check [dastaZ80 User's Manual](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20(Mark%20I)%20Manual%20-%20User%E2%80%99s%20Manual.pdf) for more details):
          * **cat**: shows disk (CompactFlash) catalogue.
          * **halt**: halts the system.
          * **help**: shows list of available commands, with a short description and usage example.
          * **load *[filename]***: loads specified filename from disk to RAM, at location specified in the Block Allocation Table (BAT).
          * **run *[address]***: moves the Program Counter (PC) to the specified address, so that the instructions start execution.
          * **memdump *[address_start]*,*[address_end]***: shows all the contents of memory (ROM/RAM) from address_start to address_end.
          * **peek *[address]***: shows the value stored at address.
          * **poke *[address]*,*[value]***: stores value at the specified address.
          * **autopoke *[start_address]***: allows to enter hexadecimal values that will be stored at the start_address and consecutive positions. The address is incremented automatically after each hexadecimal value + press of ENTER key. Entering no value (i.e. just press ENTER) will stop the process. I made this so that I can enter assembled programs, as Mark I doesn't have any means of loading programs.
          * **reset**: clears RAM (sets all to $00) and resets the system.
          * **run *[filename]*,*[parameters]***: executes a load *[filename]* and run *[address]*.
          * **formatdsk *[label]*,*[num_partitions]***: formats a CompactFlash card with DZFS.
          * **rename *[old_filename]*,*[new_filename]***: changes the name of file old_filename to new_filename.
          * **delete *[filename]***: deletes filename. Data isn't deleted, just the first character of the filename in the BAT is set to 7E (~), so it can be undeleted. Be aware, that the save command will always search for an empty entry in the BAT, but if it finds none, then it will re-use the first entry of a deleted file. Therefore, undelete of a file is only guaranteed if no file was created since the delete command was issued.
          * **chgattr *[filename]*,*[new_attributes(RHSE)]***: changes the attributes of filename to the new specified attributes.
          * **save *[address_start]*,*[number_bytes]***: creates a new file on the CF card, that will contain *n* number of bytes, starting at the specified address. After entering the command, the user will be prompted to type the filename.
          * **date**: shows the current date (my RTC circuit is not yet ready, so date is hardcoded to 12/08/2022)
          * **time**: shows the current time (my RTC circuit is not yet ready, so date is hardcoded to 16:24:45)
          * **crc16 *[address_start]*,*[address_end]***: Generates and prints a 16-bit cyclic redundancy check (CRC) based on the IBM Binary Synchronous Communications protocol (BSC or Bisync), for the bytes between start and end address.
    * **TODOs**:
      * ✔ <del>Do not allow renaming System or Read Only files.</del>
      * ✔ <del>Do not allow deleting System or Read Only files.</del>
      * ✔ <del>Disable disk commands if at boot the CF card was detected as not formatted.</del>
    * **BUGS**:
      * *run*, *rename*, *delete* and *chgaatr*, are not taking in consideration the full filename (e.g. *disk* is acting on file *diskinfo*)

---

## User Modifiable Operating System (Paged ROM and Jumpblocks)

At boot, the contents of the ROM (containing DZOS) are copied to High RAM (starting at $8000), then the ROM chip is disabled and the contents of DZOS (now at $8000) are copied to Low RAM (starting at $0000). Then DZOS is started, running only from RAM. Thus, the entire operating system can be modified by the user.

But changing subroutines that fit exactly in the same number of bytes, so that others are not overwritten, would be very difficult. And that's where *Jumpblocks* come in handy.

All DZOS subroutines are called via *Jumpblocks*. These jumpblocks are simple *JP* (jump) instructions to where the subroutine code is located in memory. By changing the two bytes (address) of a jump instruction, a subroutine can be redirected to a different one.

All jumpblock addresses can be found in the *.exp* files in the *exp* folder. Or in the documentation.

For example, imagine we're testing a new (hopefully better) subroutine for division of two 16-bit numbers. Looking at the file *kernel.exp*, we find that *F_KRN_DIV1616* is located at $26DD. If we look at the contents of the three bytes starting at that address (e.g. with command *peek*), we will find *C3 60 17*. This means that whenever a program calls *F_KRN_DIV1616*, it does a jump (opcode C3) to address $1760 (stored as little-endian), which is where the subroutine code starts. But what we want is to jump to our code instead.

First we put the assembled code of our new subroutine somewhere in RAM (e.g. $5000). Next we change the jump by changing the address bytes with *poke 26de,00* and *poke 26df,50*. The opcode *C3* (jump) MUST not be changed.

Now, whenever a program, and even DZOS, calls *F_KRN_DIV1616*, will be jumping to our new subroutine at $5000

Jumpblocks also allow me to change the subroutines in DZOS without altering the address that is seen by the calling subroutines, thus keeping retrocompatibility with previous versions of the operating system.

---

## DZOS Compatibility

It works with [RC2014](https://rc2014.co.uk/). You just need to assemble using the included *portmap_RC2014.inc*, by creating a symbolic link: ```ln -s portmap_RC2014.inc portmappings.inc```
