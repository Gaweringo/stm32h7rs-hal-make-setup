# Default target
.PHONY: all
all: size

# Parallel build by default
MAKEFLAGS += -j$(nproc)

####### Settings ###################################################################################

CC  := arm-none-eabi-gcc

# Name of the resulting executable. Will be placed in the BUILD type dependent TARGET_DIR
EXE := out.elf

# Source files
SRC := src/main.c \
       src/board.c \
       src/system/stm32h7rsxx_it.c \
       src/system/syscalls.c \
       src/system/system_stm32h7rsxx.c \
       src/system/startup_stm32h7s3xx.s \
       src/system/hal/stm32h7rsxx_hal_timebase_tim.c \


# This provides all source files of the STM32CubeHAL in the HAL_SRC variable
include make-includes/stm32-cube-hal.mk
SRC += $(addprefix dependencies/stm32h7rsxx_hal_driver/Src/,$(HAL_SRC))

# Include directories
INC := src \
       src/system \
       dependencies/cmsis-device-h7rs/Include \
       dependencies/CMSIS_6/CMSIS/Core/Include \
       dependencies/stm32h7rsxx_hal_driver/Inc \

LINKER_SCRIPT := src/system/stm32h7s3xx_flash.ld

# ThradX setup
include make-includes/threadx.mk

##### Common compiler flags ########################################################################
CFLAGS += -std=gnu11 \
	  -ffunction-sections -fdata-sections \
	  -Wall -Wextra -Wpedantic \
	  -fstack-usage \

# Target specific options
CFLAGS += \
	  -mcpu=cortex-m7 -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb \
	  --specs=nosys.specs -static --specs=nano.specs -lc -lm -flto \
	  -DUSE_HAL_DRIVER -DSTM32H7S3xx \

# Flags which must be prefixed with --for-liner to be passed to the linker (done automatically)
LINKER_FLAGS := --gc-sections --print-memory-usage \

# TODO(MaHa): Extract host/target dependent compiler flags

# Default build type
BUILD := debug

# Build type specific flags
CFLAGS.debug         := -g3 -ggdb -O0
CFLAGS.debug.small   := -g3 -ggdb -Os
CFLAGS.debug.fast    := -g3 -ggdb -O2
CFLAGS.release.small := -Os
CFLAGS.release.fast  := -O2

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
ASMX_SRC := $(filter %.S,$(SRC))
OBJECTS := $(C_SRC:%.c=%.o) $(ASM_SRC:%.s=%.o) $(ASMX_SRC:%.S=%.o)
# Dependency files created by the compiler (for rebuilds if included header files change)
DEPS    := $(patsubst %.c,%.d,$(SRC))
# Put object and dependency files into the targets OBJ_DIR to not clutter the workspace
OBJECTS := $(addprefix $(OBJ_DIR)/,$(OBJECTS))
DEPS    := $(addprefix $(OBJ_DIR)/,$(DEPS))

##### Usefull targets ##############################################################################

.PHONY: size
size: $(TARGET)
	arm-none-eabi-size $(TARGET)

.PHONY: help
help:
	@echo "Options:"
	@echo "      BUILD=<option>        Set build type to one of the following options"
	@echo " (default)  debug           With debug symbols and no optimizations"
	@echo "            debug.small     With -Os optimizations and debug symbols"
	@echo "            debug.fast      With -O2 optimizations and debug symbols"
	@echo "            release.small   With -Os optimizations and no debug symbols"
	@echo "            release.fast    With -O2 optimizations and no debug symbols"
	@echo ""
	@echo " Example: make BUILD=release.small"
	@echo ""
	@echo "Commands:"
	@echo "  make flash-stlink         Build and flash using the stlink 'STM32_Programmer_CLI'"
	@echo "  make flash-pyocd          Build and flash using pyOCD"
	@echo "  make size                 Build and show size of resulting binary"
	@echo "  make build                Build target binary"
	@echo "  make clean                Delete all build artifacts"

.PHONY: clean
clean::
	/bin/rm -rf $(BUILD_DIR)

.PHONY: flash-stlink flash-jlink flash-pyocd
flash-stlink: $(TARGET)
	STM32_Programmer_CLI --connect port=swd --write $< --go

flash-pyocd: $(TARGET)
	pyocd load $^ --target stm32h7s3l8hxh

.PHONY: build
build: $(TARGET)

.PHONY: gdb pyocd
gdb:
	arm-none-eabi-gdb $(TARGET) -x commands.gdb

pyocd:
	pyocd cmd --target stm32h7s3l8hxh --elf $(TARGET)

##### Plumbing targets, required for the actual build ##############################################

$(TARGET): $(OBJECTS) $(THREADX_LIB) $(LINKER_SCRIPT) | $(TARGET_DIR)
	@echo "Builing target $@"
	@$(CC) $(CFLAGS) $(OBJECTS) $(THREADX_LIB) -T$(LINKER_SCRIPT) -o $@

# Create dependencie files, which include make rules that depend on the header files included in the
# source .c files
$(OBJ_DIR)/%.o: %.c | $(OBJ_DIR) $(dir $(OBJECTS))
	@echo "CC $<"
	@$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(OBJ_DIR)/%.o: %.s | $(OBJ_DIR) $(dir $(OBJECTS))
	@echo "CC $<"
	@$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(OBJ_DIR)/%.o: %.S | $(OBJ_DIR) $(dir $(OBJECTS))
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
