# dzos

dzOS is a single-user single-task ROM-based operating system (OS) for the 8-bit homebrew computer **dastaZ80**, which runs on a Zilog Z80 processor. It is heavily influenced by ideas and paradigms coming from Digital Research’s CP/M, so some concepts may sound familiar to those who had the privilege of using this operating system.

The OS consists of three parts:

* The **BIOS**, that provides functions for controlling the hardware.
* The **Kernel**, which provides general functions for everything that is not hardware dependent.
* The **Command-Line Interface (CLI)**, that provides commands for the user to talk to the Kernel and BIOS.

The Kernel and the CLI are hardware independendent and will work on any Z80 based computer. Therefore, by adapting the BIOS code, **dzOS can easily be ported to other Z80 systems**.

![dzOS v2022.06.22.3](https://github.com/dasta400/dzOS/blob/MarkI/docs/dzOS.2022.06.22.3.png "dzOS v2022.06.22.3")

---

## Project Status

I've decided to divide the project into progressive models (or **Mark**, as I call it).

* Current model: Mark II
  * Hardware:
    * No case
    * CPU Z80 @ 7.3728 Mhz
    * CompactFlash slot (DZFS read only, 1 single partition)
    * In progress:
      * Acorn A3010 Keyboard interface
      * Video output (TMS9918A VDP)
  * Software:
    * OS:
      * BIOS & Kernel:
        * talks to Serial Interface to communicate with the Keyboard.
        * talks with the Video Interface to generate VGA output.
        * DZFS read/write, 1 partition
      * CLI:
        * Shows prompt, reads input from keyboard and calls command's subroutines.
        * Available commands:
          * **cat**: shows disk (CompactFlash) catalogue.
          * **halt**: halts the system.
          * **help**: shows list of available commands, with a short description and usage example.
          * **load [filename]**: loads specified filename from disk to RAM, at location specified in the Block Allocation Table (BAT).
          * **run [address]**: moves the Program Counter (PC) to the specified address, so that the instructions start execution.
          * **memdump [address_start],[address_end]**: shows all the contents of memory (ROM/RAM) from address_start to address_end.
          * **peek [address]**: shows the value stored at address.
          * **poke [address],[value]**: stores value at the specified address.
          * **autopoke [start_address]**: allows to enter hexadecimal values that will be stored at the start_address and consecutive positions. The address is incremented automatically after each hexadecimal value + press of ENTER key. Entering no value (i.e. just press ENTER) will stop the process. I made this so that I can enter assembled programs, as Mark I doesn't have any means of loading programs.
          * **reset**: clears RAM (sets all to $00) and resets the system.
          * **run** [filename],[parameters]: executes a load [filename] and run [address]
          * **formatdsk** [label],[num_partitions]: formats a CompactFlash card with DZFS.
          * **rename** [old_filename],[new_filename]: changes the name of file old_filename to new_filename.
          * **delete** [filename]: deletes filename. Data isn't deleted, just the first character of the filename in the BAT is set to 7E (~), so it can be undeleted. Be aware, that the save command will always search for an empty entry in the BAT, but if it finds none, then it will re-use the first entry of a deleted file. Therefore, undelete of a file is only guaranteed if no file was created since the delete command was issued.
          * **chgattr** [filename],[new_attributes(RHSE)]: changes the attributes of filename to the new specified attributes.
    * TODOs:
      * Do not allow renaming System or Read Only files.
      * Do not allow deleting System or Read Only files.
    * BUGS:
      * *run*, *rename*, *delete* and *chgaatr*, are not taking in consideration the full filename (e.g. *disk* is acting on file *diskinfo*)
