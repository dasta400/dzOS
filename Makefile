# Detect OS
UNAME = $(shell uname)
ifeq ($(UNAME), Linux)
    ASM = wine TASM.EXE
else
    ASM = ./TASM.EXE
endif
ASMFLAGS = -80 -b -a -f00		# For generating .bin files
TARGET = dzOS
BINARIES = bin/dzOS.bin
MKDIR = mkdir -p
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
MAGENTA = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[0;37m

OS_MAXSIZE = 16384
VERSION_ADDR = 9911     # $26B7

YEAR = $(shell date +"%Y")
MONTH = $(shell date +"%m")
DAY = $(shell date +"%d")
HOUR = $(shell date +"%H")
MINS = $(shell date +"%M")

.PHONY: directories 

all: clean $(TARGET)
# Check file size don't exceed configuration
	$(eval dzos_size = $(shell stat --printf="%s" bin/dzOS.bin))
	@if [ $(dzos_size) -ne $(OS_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> dzOS.bin is not 16KB <---$(WHITE)"; fi
# Add version number to binary
	@echo "$(BLUE)#### Versioning binary ####$(WHITE)"
# the value for seek MUST be the same as KRN_DZOS_VERSION + 1 in equates.inc, and converted into DEC
	@mv bin/dzOS.bin bin/dzOS.$(YEAR).$(MONTH).$(DAY).$(HOUR).$(MINS).bin
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

bin/dzOS.bin: src/dzOS.asm
	@echo "$(GREEN)#### Compiling $(CYAN)dzOS $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/dzOS.asm bin/dzOS.bin lst/dzOS.lst > /tmp/dastaZ80_compile.txt
	@mv src/dzOS.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

$(TARGET): bin/sysvars.bin $(BINARIES)
	

clean:
	@echo "$(RED)In case of error, check $(CYAN)/tmp/dastaZ80_compile.txt$(WHITE)"
	@echo "$(YELLOW)#### Cleaning project ####$(WHITE)"
	@rm -f bin/*
	@rm -f exp/*
	@rm -f lst/*
