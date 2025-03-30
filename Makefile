PRERELEASE_VERSION ?= "49"

ifdef RELEASE_VERSION
	VERSION_DEFINE="-DRELEASE_VERSION=$(RELEASE_VERSION)"
else
	ifdef PRERELEASE_VERSION
		VERSION_DEFINE="-DPRERELEASE_VERSION=$(PRERELEASE_VERSION)"
	endif
endif

CC           = cc65
AS           = ca65
LD           = ld65

# global includes
ASFLAGS     += -I inc
# KERNAL version number
ASFLAGS     +=  $(VERSION_DEFINE)
# put all symbols into .sym files
ASFLAGS     += -g
# all files are allowed to use 65SC02 features
ASFLAGS     += --cpu 65SC02
ASFLAGS     += --relax-checks
BUILD_DIR=build/x16
EMU_DIR1=../x16-emulator
EMU_DIR2=/mnt/c/x16emu_win64-r48/sdcard/sdcard_root/

CFG_DIR=$(BUILD_DIR)/cfg

KERNAL_SOURCES = \
	kernal/main.s \
	kernal/vectors.s \
	kernal/declare.s \
	kernal/interrupt.s \
	kernal/pipes.s \
	kernal/drivers/x16/x16.s \
	kernal/drivers/x16/screen.s \
	kernal/drivers/x16/i2c.s \
	charset/petscii.s
	
MULTITASK_SOURCES = \
	multitask/main.s \
	multitask/init.s \
	multitask/scheduler.s \
	multitask/process.s

MULTITEST_SOURCES = \
	multitest/main.s

GENERIC_DEPS = \
	inc/kernal.inc \
	inc/mac.inc \
	inc/io.inc \
	inc/multitask.inc \
	inc/regs.inc
	
KERNAL_DEPS = \
	$(GENERIC_DEPS)

MULTITASK_DEPS = \
	$(GENERIC_DEPS)

MULTITEST_DEPS = \
	$(GENERIC_DEPS)

MULTITASK_OBJS  = $(addprefix $(BUILD_DIR)/, $(MULTITASK_SOURCES:.s=.o))
MULTITEST_OBJS  = $(addprefix $(BUILD_DIR)/, $(MULTITEST_SOURCES:.s=.o))
KERNAL_OBJS  	= $(addprefix $(BUILD_DIR)/, $(KERNAL_SOURCES:.s=.o))

BANK_BINS = \
	$(BUILD_DIR)/kernal.bin \
	$(BUILD_DIR)/multitask.bin \
	$(BUILD_DIR)/multitest.bin

ROM_LABELS=$(BUILD_DIR)/rom_labels.h
ROM_LST=$(BUILD_DIR)/rom_lst.h
GIT_SIGNATURE=$(BUILD_DIR)/../signature.bin

all: $(BANK_BINS) $(ROM_LABELS) $(ROM_LST)

install: all
	cp $(BUILD_DIR)/multitask.bin $(EMU_DIR1)/multitask.bin
	cp $(BUILD_DIR)/multitest.bin $(EMU_DIR1)/multitest.bin
	cp $(BUILD_DIR)/kernal.bin $(EMU_DIR1)/kernal.bin
	cp $(BUILD_DIR)/multitask.bin $(EMU_DIR2)/multitask.bin
	cp $(BUILD_DIR)/multitest.bin $(EMU_DIR2)/multitest.bin
	cp $(BUILD_DIR)/kernal.bin $(EMU_DIR2)/kernal.bin

clean:
	rm -f $(GIT_SIGNATURE)
	rm -rf $(BUILD_DIR)

$(GIT_SIGNATURE): FORCE
	@mkdir -p $(BUILD_DIR)
	git diff --quiet && /bin/echo -n $$( (git rev-parse --short=8 HEAD || /bin/echo "00000000") | tr '[:lower:]' '[:upper:]') > $(GIT_SIGNATURE) \
	|| /bin/echo -n $$( /bin/echo -n $$(git rev-parse --short=7 HEAD || echo "0000000") | tr '[:lower:]' '[:upper:]'; /bin/echo -n '+') > $(GIT_SIGNATURE)

FORCE:

$(BUILD_DIR)/%.cfg: %.cfgtpl
	@mkdir -p $$(dirname $@)
	$(CC) -E $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@

# Bank 0 : KERNAL
$(BUILD_DIR)/kernal.bin: $(GIT_SIGNATURE) $(KERNAL_OBJS) $(KERNAL_DEPS) $(CFG_DIR)/kernal-x16.cfg	
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG_DIR)/kernal-x16.cfg $(KERNAL_OBJS) -o $@ -m $(BUILD_DIR)/kernal.map -Ln $(BUILD_DIR)/kernal.sym 		
	./scripts/relist.py $(BUILD_DIR)/kernal.map $(BUILD_DIR)/kernal

# Golden RAM : MULTITASK
$(BUILD_DIR)/multitask.bin: $(GIT_SIGNATURE) $(MULTITASK_OBJS) $(MULTITASK_DEPS) $(CFG_DIR)/multitask-x16.cfg	
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG_DIR)/multitask-x16.cfg $(MULTITASK_OBJS) -o $@ -m $(BUILD_DIR)/multitask.map -Ln $(BUILD_DIR)/multitask.sym 		
	./scripts/relist.py $(BUILD_DIR)/multitask.map $(BUILD_DIR)/multitask

# $0800 : MULTITASK
$(BUILD_DIR)/multitest.bin: $(GIT_SIGNATURE) $(MULTITEST_OBJS) $(MULTITEST_DEPS) $(CFG_DIR)/multitest-x16.cfg	
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG_DIR)/multitest-x16.cfg $(MULTITEST_OBJS) -o $@ -m $(BUILD_DIR)/multitest.map -Ln $(BUILD_DIR)/multitest.sym 		
	./scripts/relist.py $(BUILD_DIR)/multitest.map $(BUILD_DIR)/multitest	

$(BUILD_DIR)/rom_labels.h: $(BANK_BINS)
	./scripts/symbolize.sh 0 build/x16/kernal.sym   	> $@		
	./scripts/symbolize.sh 1 build/x16/multitask.sym   >> $@		
	./scripts/symbolize.sh 2 build/x16/multitest.sym   >> $@		

$(BUILD_DIR)/rom_lst.h: $(BANK_BINS)
	./scripts/trace_lst.py 0 `find build/x16/kernal/ -name \*.rlst`     	> $@
	./scripts/trace_lst.py 1 `find build/x16/multitask/ -name \*.rlst`     >> $@
	./scripts/trace_lst.py 2 `find build/x16/multitest/ -name \*.rlst`     >> $@
	