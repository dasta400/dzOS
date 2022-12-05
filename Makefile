# Detect OS
UNAME = $(shell uname)
ifeq ($(UNAME), Linux)
    ASM = wine TASM.EXE
else
    ASM = ./TASM.EXE
endif
ASMFLAGS = -80 -b -a -f00		# For generating .bin files
TARGET = dzOS
BINARIES = bin/BIOS.bin bin/kernel.bin bin/CLI.bin bin/BIOS.bootstrap.bin bin/romtrail.bin
MERGE = bin/BIOS.bin bin/kernel.bin bin/CLI.bin bin/BIOS.bootstrap.bin bin/romtrail.bin
MKDIR = mkdir -p
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
MAGENTA = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[0;37m

BIOS_MAXSIZE = 5056
KERNEL_MAXSIZE = 5056
CLI_MAXSIZE = 5600
VERSION_ADDR = 9840     # $2670

YEAR = $(shell date +"%Y")
MONTH = $(shell date +"%m")
DAY = $(shell date +"%d")
HOUR = $(shell date +"%H")
MINS = $(shell date +"%M")

.PHONY: directories 

all: clean $(TARGET)
# Check file size don't exceed configuration
	$(eval bios_fs = $(shell stat --printf="%s" bin/BIOS.bin))
	@if [ $(bios_fs) -gt $(BIOS_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> BIOS.bin is too big! <---$(WHITE)"; fi
	$(eval kernel_fs = $(shell stat --printf="%s" bin/kernel.bin))
	@if [ $(kernel_fs) -gt $(KERNEL_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> kernel.bin is too big! <---$(WHITE)"; fi
	$(eval cli_fs = $(shell stat --printf="%s" bin/CLI.bin))
	@if [ $(cli_fs) -gt $(CLI_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> CLI.bin is too big! <---$(WHITE)"; fi

	@echo "$(YELLOW)#### Merging Binaries ####$(WHITE)"
	@cat $(MERGE) > bin/dzOS.$(YEAR).$(MONTH).$(DAY).$(HOUR).$(MINS).bin
# the value for seek MUST be the same as KRN_DZOS_VERSION + 1 in equates.inc, and converted into DEC
	@printf '$(YEAR).$(MONTH).$(DAY).$(HOUR).$(MINS)' | dd of=bin/dzOS.$(YEAR).$(MONTH).$(DAY).$(HOUR).$(MINS).bin bs=1 seek=$(VERSION_ADDR) conv=notrunc status=none
	@echo "$(MAGENTA)#### dzOS binary (version $(YEAR).$(MONTH).$(DAY).$(HOUR).$(MINS)) succesfully created in bin/ ####$(WHITE)"
	@grep -nir --exclude-dir=build ToDo src/ > ToDo.txt

directories:
	@$(MKDIR) bin
	@$(MKDIR) exp
	@$(MKDIR) lst

bin/sysvars.bin: src/sysvars.asm
	@echo "$(GREEN)#### Compiling $(CYAN)sysvars $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/sysvars.asm bin/sysvars.bin lst/sysvars.lst > /tmp/dastaZ80_compile.txt
	@mv src/sysvars.exp exp/
	@rm -f bin/sysvars.bin
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/BIOS.bin: src/BIOS/BIOS.asm
	@echo "$(GREEN)#### Compiling $(CYAN)BIOS $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/BIOS/BIOS.asm bin/BIOS.bin lst/BIOS.lst > /tmp/dastaZ80_compile.txt
	@mv src/BIOS/BIOS.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/kernel.bin: src/kernel/kernel.asm
	@echo "$(GREEN)#### Compiling $(CYAN)Kernel $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/kernel/kernel.asm bin/kernel.bin lst/kernel.lst > /tmp/dastaZ80_compile.txt
	@mv src/kernel/kernel.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/CLI.bin: src/CLI/CLI.asm
	@echo "$(GREEN)#### Compiling $(CYAN)CLI $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/CLI/CLI.asm bin/CLI.bin lst/CLI.lst > /tmp/dastaZ80_compile.txt
	@mv src/CLI/CLI.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/romtrail.bin: src/romtrail.asm
	@$(ASM) $(ASMFLAGS) src/romtrail.asm bin/romtrail.bin lst/romtrail.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/BIOS.bootstrap.bin: src/BIOS/BIOS.bootstrap.asm
	@echo "$(GREEN)#### Compiling $(CYAN)BIOS Bootstrap $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/BIOS/BIOS.bootstrap.asm bin/BIOS.bootstrap.bin lst/BIOS.bootstrap.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt


$(TARGET): bin/sysvars.bin $(BINARIES)
	

clean:
	@echo "$(RED)In case of error, check $(CYAN)/tmp/dastaZ80_compile.txt$(WHITE)"
	@echo "$(YELLOW)#### Cleaning project ####$(WHITE)"
	@rm -f bin/*
	@rm -f exp/*
	@rm -f lst/*
