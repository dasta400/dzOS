# ToDO - Detect OS Linux or Win
ASM = ./TASM.EXE
ASMFLAGS = -80 -b -a -fFF		# For generating .bin files
#ASMFLAGS = -80 -o10 -g0 -c -a -y	# For generating Intel HEX files
TARGET = dzOS
BINARIES = bin/sysconsts.bin bin/BIOS.bin bin/BIOS_jblks.bin bin/kernel.bin bin/kernel_jblks.bin bin/CLI.bin
MERGE = bin/BIOS.bin bin/BIOS_jblks.bin bin/kernel.bin bin/kernel_jblks.bin bin/CLI.bin bin/sysconsts.bin
MKDIR = mkdir -p
WHITE = \033[0;37m
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
MAGENTA = \033[0;35m

BIOS_BUILD = $(shell cat src/BIOS.version)
BIOS_BUILD_ADDR = 4224
KERNEL_BUILD = $(shell cat src/Kernel.version)
KERNEL_BUILD_ADDR = 4228
CLI_BUILD = $(shell cat src/CLI.version)
CLI_BUILD_ADDR = 4232

BIOS_MAXSIZE = 832
KERNEL_MAXSIZE = 1280
CLI_MAXSIZE = 2112

.PHONY: directories 

all: $(TARGET)
# Check file size don't exceed configuration
	$(eval bios_fs = $(shell stat --printf="%s" bin/BIOS.bin))
	@if [ $(bios_fs) -gt $(BIOS_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> BIOS.bin is too big! <---$(WHITE)"; fi
	$(eval kernel_fs = $(shell stat --printf="%s" bin/kernel.bin))
	@if [ $(kernel_fs) -gt $(KERNEL_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> kernel.bin is too big! <---$(WHITE)"; fi
	$(eval cli_fs = $(shell stat --printf="%s" bin/CLI.bin))
	@if [ $(cli_fs) -gt $(CLI_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> CLI.bin is too big! <---$(WHITE)"; fi

	@echo "$(YELLOW)#### Merging Binaries ####$(WHITE)"
	@cat $(MERGE) > bin/dzOS.bin
	@echo "$(YELLOW)#### Stamping Build numbers ####$(WHITE)"
	$(eval BIOS_BUILD = $(shell echo $$(($(BIOS_BUILD) - 1))))
	$(eval KERNEL_BUILD = $(shell echo $$(($(KERNEL_BUILD) - 1))))
	$(eval CLI_BUILD = $(shell echo $$(($(CLI_BUILD) - 1))))
	@printf '$(BIOS_BUILD)' | dd of=bin/dzOS.bin bs=1 seek=$(BIOS_BUILD_ADDR) conv=notrunc status=none
	@printf '$(KERNEL_BUILD)' | dd of=bin/dzOS.bin bs=1 seek=$(KERNEL_BUILD_ADDR) conv=notrunc status=none
	@printf '$(CLI_BUILD)' | dd of=bin/dzOS.bin bs=1 seek=$(CLI_BUILD_ADDR) conv=notrunc status=none
	@echo "$(RED)#### bin/dzOS.bin succesfully created ####$(WHITE)"

directories:
	@$(MKDIR) bin
	@$(MKDIR) exp
	@$(MKDIR) lst

bin/sysconsts.bin: src/sysconsts.asm
	@echo "$(GREEN)#### Compiling $(RED)sysconsts $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/sysconsts.asm bin/sysconsts.bin lst/sysconsts.lst > /tmp/dastaZ80_compile.txt
	@mv src/sysconsts.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/sysvars.bin: src/sysvars.asm
	@echo "$(GREEN)#### Compiling $(RED)sysvars $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/sysvars.asm bin/sysvars.bin lst/sysvars.lst > /tmp/dastaZ80_compile.txt
	@mv src/sysvars.exp exp/
	@rm -f bin/sysvars.bin
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/BIOS.bin: src/BIOS.asm
	@echo "$(GREEN)#### Compiling $(RED)BIOS $(MAGENTA)build $(BIOS_BUILD) $(GREEN)####$(WHITE)"
	$(eval BIOS_BUILD = $(shell echo $$(($(BIOS_BUILD) + 1))))
	@echo "$(BIOS_BUILD)" > src/BIOS.version
	@$(ASM) $(ASMFLAGS) src/BIOS.asm bin/BIOS.bin lst/BIOS.lst > /tmp/dastaZ80_compile.txt
	@mv src/BIOS.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/BIOS_jblks.bin: src/BIOS_jblks.asm
	@echo "$(GREEN)#### Compiling $(RED)BIOS Jumpblocks $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/BIOS_jblks.asm bin/BIOS_jblks.bin lst/BIOS_jblks.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/kernel.bin: src/kernel.asm
	@echo "$(GREEN)#### Compiling $(RED)Kernel $(MAGENTA)build $(KERNEL_BUILD) $(GREEN)####$(WHITE)"
	$(eval KERNEL_BUILD = $(shell echo $$(($(KERNEL_BUILD) + 1))))
	@echo "$(KERNEL_BUILD)" > src/Kernel.version
	@$(ASM) $(ASMFLAGS) src/kernel.asm bin/kernel.bin lst/kernel.lst > /tmp/dastaZ80_compile.txt
	@mv src/kernel.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/kernel_jblks.bin: src/kernel_jblks.asm
	@echo "$(GREEN)#### Compiling $(RED)Kernel Jumpblocks $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/kernel_jblks.asm bin/kernel_jblks.bin lst/kernel_jblks.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/CLI.bin: src/CLI.asm
	@echo "$(GREEN)#### Compiling $(RED)CLI $(MAGENTA)build $(CLI_BUILD) $(GREEN)####$(WHITE)"
	$(eval CLI_BUILD = $(shell echo $$(($(CLI_BUILD) + 1))))
	@echo "$(CLI_BUILD)" > src/CLI.version
	@$(ASM) $(ASMFLAGS) src/CLI.asm bin/CLI.bin lst/CLI.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt


$(TARGET): bin/sysvars.bin $(BINARIES)
	

clean:
	@echo "$(YELLOW)#### Cleaning project ####$(WHITE)"
	@rm -f bin/*
	@rm -f exp/*
	@rm -f lst/*

resetbuilds:
	@echo 0 > src/BIOS.version
	@echo 0 > src/Kernel.version
	@echo 0 > src/CLI.version
