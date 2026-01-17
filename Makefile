CC  := arm-none-eabi-gcc

# Name of the resulting executable. Will be placed in the BUILD type dependent TARGET_DIR
EXE := out.elf

# Source files
SRC := src/main.c \
       src/syscalls.c \
       dependencies/cmsis-device-h7rs/Source/Templates/system_stm32h7rsxx.c \
       dependencies/cmsis-device-h7rs/Source/Templates/gcc/startup_stm32h7s3xx.s \

include make-includes/stm32-cube-hal.mk
SRC += $(addprefix dependencies/stm32h7rsxx_hal_driver/Src/,$(HAL_SRC))

# Include directories
INC := src \
       dependencies/cmsis-device-h7rs/Include \
       dependencies/CMSIS_6/CMSIS/Core/Include \
       dependencies/stm32h7rsxx_hal_driver/Inc \

LINKER_SCRIPT := dependencies/cmsis-device-h7rs/Source/Templates/gcc/linker/stm32h7s3xx_flash.ld

##### Common compiler flags ########################################################################
CFLAGS := -std=gnu11 \
	  -ffunction-sections -fdata-sections \
	  -Wall -Wextra -Wpedantic \
	  -fstack-usage \

# Target specific options
CFLAGS += \
	  -mcpu=cortex-m7 -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb \
	  --specs=nosys.specs -static --specs=nano.specs -lc -lm -flto \
	  -DUSE_HAL_DRIVER -DSTM32H7S3xx \

LINKER_FLAGS := --gc-sections --print-memory-usage \

# TODO(MaHa): Extract host/target dependent compiler flags

# Default build type
BUILD := debug

# Build type specific flags
CFLAGS.debug         := -g3 -O0
CFLAGS.release.small := -Oz
CFLAGS.release.fast  := -O3

# Append build type specific flags
CFLAGS += $(CFLAGS.$(BUILD))

CFLAGS += $(addprefix -I,$(INC))
CFLAGS += $(addprefix --for-linker=,$(LINKER_FLAGS))

##### Build up directories and files used in compile steps #########################################

# Transforming specified build settings into their directories, so that the rules below can make
# good use of them
BUILD_DIR  := build
# Seperate build directory for each build type
TARGET_DIR := $(BUILD_DIR)/$(BUILD)
TARGET     := $(TARGET_DIR)/$(EXE)
OBJ_DIR    := $(TARGET_DIR)/objects

# Object files from c SRC files
C_SRC   := $(filter %.c,$(SRC))
ASM_SRC := $(filter %.s,$(SRC))
OBJECTS := $(C_SRC:%.c=%.o) $(ASM_SRC:%.s=%.o)
# Dependency files created by the compiler (for rebuilds if included header files change)
DEPS    := $(patsubst %.c,%.d,$(SRC))
# Put object and dependency files into the targets OBJ_DIR to not clutter the workspace
OBJECTS := $(addprefix $(OBJ_DIR)/,$(OBJECTS))
DEPS    := $(addprefix $(OBJ_DIR)/,$(DEPS))

##### Usefull targets ##############################################################################

.PHONY: all
all: size

.PHONY: size
size: $(TARGET)
	arm-none-eabi-size $(TARGET)

.PHONY: help
help:
	@echo "Options:"
	@echo "      BUILD=<option>        Set build type to one of the following options"
	@echo " (default)  debug           With debug symbols and no optimizations"
	@echo "            release.small   With -Oz optimizations and no debug symbols"
	@echo "            release.fast    With -O3 optimizations and no debug symbols"
	@echo ""
	@echo " Example: make BUILD=release.small"
	@echo ""
	@echo "Commands:"
	@echo "  make flash-stlink         Build and flash using the stlink"

.PHONY: clean
clean:
	/bin/rm -r $(BUILD_DIR)

.PHONY: flash-stlink flash-jlink flash-pyocd
flash-stlink: $(TARGET)
	STM32_Programmer_CLI --connect port=swd --write $< --go


##### Plumbing targets, required for the actual build ##############################################

$(TARGET): $(OBJECTS) $(LINKER_SCRIPT) | $(TARGET_DIR)
	@echo "Builing target $@"
	@$(CC) $(CFLAGS)  $(OBJECTS) -T$(LINKER_SCRIPT) -o $@

# Create dependencie files, which include make rules that depend on the header files included in the
# source .c files
$(OBJ_DIR)/%.o: %.c Makefile | $(OBJ_DIR) $(dir $(OBJECTS))
	@echo "CC $<"
	@$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(OBJ_DIR)/%.o: %.s Makefile | $(OBJ_DIR) $(dir $(OBJECTS))
	@echo "CC $<"
	@$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

# Create required directories
# sort is used here to remove duplicate directories
OBJ_DIRS := $(sort $(dir $(OBJECTS)))
$(OBJ_DIRS):
	/bin/mkdir -p $@
$(OBJ_DIR):
	/bin/mkdir -p $@
$(TARGET_DIR):
	/bin/mkdir -p $@

# Include the compiler generated dependency files, which enable rebuilds on header file changes
-include $(DEPS)
