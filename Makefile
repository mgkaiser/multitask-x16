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

BUILD_DIR=build/x16
EMU_DIR=../x16-emulator

CFG_DIR=$(BUILD_DIR)/cfg

MULTITASK_SOURCES = \
	multitask/scheduler.s
	
MULTITASK_DEPS = ""

MULTITASK_OBJS  = $(addprefix $(BUILD_DIR)/, $(MULTITASK_SOURCES:.s=.o))

BANK_BINS = \
	$(BUILD_DIR)/multitask.bin

ROM_LABELS=$(BUILD_DIR)/rom_labels.h
ROM_LST=$(BUILD_DIR)/rom_lst.h
GIT_SIGNATURE=$(BUILD_DIR)/../signature.bin

all: $(BUILD_DIR)/rom.bin $(ROM_LABELS) $(ROM_LST)

#install: all
#	cp $(BUILD_DIR)/rom.bin $(EMU_DIR)/rom.bin

$(BUILD_DIR)/rom.bin: $(BANK_BINS)
	cat $(BANK_BINS) > $@

#test: FORCE $(BUILD_DIR)/rom.bin
#	for f in test/unit/*/*.py; do PYTHONPATH="test/unit" python3 -B $${f}; done

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

# TODO: Need a way to control lst file generation through a configuration variable.
$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@

# Golden RAM : MULTITASK
$(BUILD_DIR)/multitask.bin: $(GIT_SIGNATURE) $(MULTITASK_OBJS) $(MULTITASK_DEPS) $(CFG_DIR)/multitask-x16.cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG_DIR)/multitask-x16.cfg $(MULTITASK_OBJS) -o $@ -m $(BUILD_DIR)/multitask.map -Ln $(BUILD_DIR)/multitask.sym \
	`${BUILD_DIR}/../../findsymbols ${BUILD_DIR}/charset.sym __CHARPET_LOAD__ __CHARPET2_LOAD__ __CHARLAE_LOAD__ __CHARLAE2_LOAD__` \
	`${BUILD_DIR}/../../findsymbols ${BUILD_DIR}/charset.sym __CHARKAT_LOAD__ __CHARISO_LOAD__ __CHARISO2_LOAD__ __CHARCYR_LOAD__` \
	`${BUILD_DIR}/../../findsymbols ${BUILD_DIR}/charset.sym __CHARCYR2_LOAD__ __CHARANSI_LOAD__`
	./scripts/relist.py $(BUILD_DIR)/multitask.map $(BUILD_DIR)/multitask

$(BUILD_DIR)/rom_labels.h: $(BANK_BINS)
	./scripts/symbolize.sh 0 build/x16/multitask.sym   > $@	
	mv $(BUILD_DIR)/rom_labels.tmp $@

$(BUILD_DIR)/rom_lst.h: $(BANK_BINS)
	./scripts/trace_lst.py 0 `find build/x16/multitask/ -name \*.rlst`     > $@
	