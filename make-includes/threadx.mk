# ThreadX
SRC += src/system/threadx/tx_initialize_low_level.S \

INC += dependencies/threadx/common/inc \
       dependencies/threadx/ports/cortex_m7/gnu/inc \
       src/system/threadx \

# Required for headers to include / provide the correct symbols, when
# included in user code. This also means, that the directory in which
# tx_user.h is located is in the include directories as it needs to
# be includeable as "tx_user.h".
CFLAGS += -DTX_INCLUDE_USER_DEFINE_FILE

THREADX_DIR := dependencies/threadx
THREADX_BUILD_DIR := $(THREADX_DIR)/build/$(BUILD)
THREADX_LIB := $(THREADX_BUILD_DIR)/libthreadx.a
THREADX_TX_USER := src/system/threadx/tx_user.h

THREADX_FLAGS.debug         := -DCMAKE_BUILD_TYPE=Debug
THREADX_FLAGS.release.small := -DCMAKE_BUILD_TYPE=Release
THREADX_FLAGS.release.fast  := -DCMAKE_BUILD_TYPE=Release

# ThreadX
$(THREADX_BUILD_DIR): $(THREADX_TX_USER)
	cmake -S $(THREADX_DIR) -B $(THREADX_BUILD_DIR) -G Ninja \
		--toolchain=cmake/cortex_m7.cmake \
		$(THREADX_FLAGS.$(BUILD)) \
		-D TX_USER_FILE=../../$(THREADX_TX_USER)

$(THREADX_LIB): $(THREADX_TX_USER) | $(THREADX_BUILD_DIR)
	cmake --build $(THREADX_BUILD_DIR)

clean::
	/bin/rm -r $(THREADX_BUILD_DIR)
