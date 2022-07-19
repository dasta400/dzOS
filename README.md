# dzos

dzOS is a single-user single-task ROM-based operating system (OS) for the 8-bit homebrew computer **dastaZ80**, which runs on a Zilog Z80 processor. It is heavily influenced by ideas and paradigms coming from Digital Research’s CP/M, so some concepts may sound familiar to those who had the privilege of using this operating system.

The OS consists of three parts:

* The **BIOS**, that provides functions for controlling the hardware.
* The **Kernel**, which provides general functions for everything that is not hardware dependent.
* The **Command-Line Interface (CLI)**, that provides commands for the user to talk to the Kernel and BIOS.

The Kernel and the CLI are hardware independendent and will work on any Z80 based computer. Therefore, by adapting the BIOS code, **dzOS can easily be ported to other Z80 systems**.

![dzOS v2022.07.19.13](https://github.com/dasta400/dzOS/blob/MarkII/docs/dzOS.2022.07.19.13.png "dzOS v2022.07.19.13")

---

## Project Status

I've decided to divide the project into progressive models (or **Mark**, as I call it).

* Current model: **Mark I**
  * **Hardware**:
    * **CPU**: Z80 @ 7.3728 Mhz
    * **ROM**: 16 KB with DZOS
    * **RAM**: 64 KB (~48 KB free). Lower 16 KB used by ROM addresses. Then approx. 1 KB for Stack, Jumpblocks and Buffers. Free RAM starts at address $4570
    * **Video output**: 80x25 Colour ANSI Terminal, via VGA32 connected to the TX signal of the SIO/2 Channel A
    * **Keyboard**: Acorn A3010 connected to the RX signal of the SIO/2 Channel A
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
    * **Expansion Port**: 2x20 pin header
    * **Power Supply**: 12V External Power Supply with 5V/3A Regulator
    * **Removable storage**: CompactFlash formatted with DZFS (1 single partition)
    * **Case**: A3010 all-in-one computer case
      * Connectors:
        * DE-15 female connecto (VGA)
        * CompactFlash card slot (CF)
        * 2.1mm Barrel Power Jack (Power Supply)
        * 2/54mm 40-pin male double row (2×20) pin header (Expansion port)
      * Others:
        * Switch ON/OF (Power)
        * Tactile switch (reset)

  * **Software**:
    * Keyboard Controller Arduino code for Teensy++ 2.0
    * FabGL Arduino code for VGA32
    * **OS**:
      * **BIOS** & **Kernel**:
        * Talks with the Keyboard Controller to communicate with the Keyboard.
        * Talks with the Video Interface to generate VGA output.
        * DZFS read/write, 1 partition
      * **Command Line Interface (CLI)**:
        * Shows prompt, reads input from keyboard and calls subroutines corresponding to commands entered by the user.
        * Available commands:
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
          * **chgattr** [filename],[new_attributes(RHSE)]: changes the attributes of filename to the new specified attributes.
    * **TODOs**:
      * Do not allow renaming System or Read Only files.
      * Do not allow deleting System or Read Only files.
    * **BUGS**:
      * *run*, *rename*, *delete* and *chgaatr*, are not taking in consideration the full filename (e.g. *disk* is acting on file *diskinfo*)
