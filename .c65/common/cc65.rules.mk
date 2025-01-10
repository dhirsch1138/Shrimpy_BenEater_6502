#Based on https://github.com/dbuchwald/cc65-tools
#include common/tools.mk
#because we hid the common directory for make in .c65
include $(COMMON_FOLDER)tools.mk

#TODO
BUILD_FOLDER=$(BUILDPATH)
TEMP_FOLDER=$(BUILD_FOLDER)/$(ROM_NAME)
ROM_FILE=$(BUILD_FOLDER)/$(ROM_NAME).bin
MAP_FILE=$(TEMP_FOLDER)/$(ROM_NAME).map

ASM_SOURCEFILENAMES=$(notdir $(ASM_SOURCES))

$(info        INFO: Source files to assemble $(ASM_SOURCEFILENAMES))
ASM_OBJECTS=$(ASM_SOURCEFILENAMES:%.s=$(TEMP_FOLDER)/%.o)
$(info        INFO: Objects to build $(ASM_OBJECTS))

# Compile assembler sources
$(TEMP_FOLDER)/%.o: $(ASM_SOURCEFOLDER)%.s
	@$(MKDIR_BINARY) $(MKDIR_FLAGS) $(TEMP_FOLDER)
	$(CA65_BINARY) $(CA65_FLAGS) -o $@ -l $(@:.o=.lst) $<

# Link ROM image
$(ROM_FILE): $(ASM_OBJECTS) $(FIRMWARE_CFG)
	@$(MKDIR_BINARY) $(MKDIR_FLAGS) $(BUILD_FOLDER)
	$(LD65_BINARY) $(LD65_FLAGS) -C $(LD65_CFG) -o $@ -m $(MAP_FILE) $(ASM_OBJECTS)

# Default target
all: $(ROM_FILE)

# Build and dump output
test: $(ROM_FILE)
	$(HEXDUMP_BINARY) $(HEXDUMP_FLAGS) $<
	$(MD5_BINARY) $<

# Clean build artifacts
clean:
	$(RM_BINARY) -f $(ROM_FILE) \
	$(MAP_FILE) \
	$(ASM_OBJECTS) \
	$(ASM_OBJECTS:%.o=%.lst)
