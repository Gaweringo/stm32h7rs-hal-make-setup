# ThreadX Setup

Get and build ThreadX
```bash
# Get ThreadX source
git clone https://github.com/eclipse-threadx/threadx
cd threadx
# Build it (for cortex_m7 in our case)
cmake -B build -G Ninja -D CMAKE_BUILD_TYPE=Debug --toolchain=cmake/cortex_m7.cmake
cmake --build build
```
This creates a archive file `build/libthreadx.a` which is the whole RTOS and can later be linked
with our application code.

## Integrate ThreadX
Just include it as a input file when doing the linking step. For example:
```bash
arm-none-eabi-gcc main.o my_other_file.o threadx/build/libthreadx.a -o out.elf
```

If there are problems with ThreadX not using VFP, set the `VFP_FLAGS` (in the toolchain file)
to the ones used when building the rest of the project.
```cmake
set(VFP_FLAGS "-mfloat-abi=hard -mfpu=fpv5-d16")
```

In this state you will get errors about undefined symbols and the like. ThreadX needs some stuff to
be set up.

1. Copy the `tx_user_sample.h` file into your project and name it `tx_user.h`, this file contains
   all the configuration for ThreadX.
   If you actually want to use this file, make sure to pass it when building ThreadX:
   ```bash
    cmake -B build -G Ninja -D CMAKE_BUILD_TYPE=Debug --toolchain=cmake/cortex_m7.cmake -D TX_USER_FILE=../../src/system/threadx/tx_user.h
   ```

2. ThreadX needs a system specific `tx_initialize_low_level.S` file, which can for the most part be
   taken from the `threadx/ports/<your_arch>/gnu/example_build` directory.
   For integration with the standard `startup_stm32...xx.s` file, only two things need to be changed:
    - `SYSTEM_CLOCK` needs to be set to the actual system core clock (e.g. `600000000` for 600MHz)
    - Where `_vectors` is referenced in the `tx_initialize_low_level` section change it to
    `g_pfnVectors` which is the symbol for the vector table from the `startup_stm32..xx.s` file.

3. Then, becaus ThreadX uses the `SysTick` Timer it cannot be used for the hal tick anymore. So we
   use a simple timer for that.
   From a STM32CubeMX project activate a timer like `TIM6`, and in `RCC`?? change the SysTick Source
   to that. This will create a `stm32h7rsxx_hal_timebase_tim.c` file, which should be copied to the
   project. Then **make sure** you have `TIM6_IRQHandler()` defined, which should call
   `HAL_IncTick()` if the `TIM_FLAG_UPDATE` is set, so the timer period has elapsed.
   Alternatively call `HAL_TIM_IRQHandler` and then define `HAL_TIM_PeriodElapsedCallback()` which
   then calls `HAL_IncTick()` if tim6 is the elapsed timer.

4. In the linker script add:
    ```ld
      ._threadx_heap :
      {
        . = ALIGN(8);
        __RAM_segment_used_end__ = .;
        . = . + 64K;
        . = ALIGN(8);
      } >RAM AT> RAM
    ```
    after `.bss` and before `._user_heap_stack`.
    **OR** put a `ifedf` / comment out the first section of `_tx_initialize_low_level` where
    `__RAM_segment_used_end__` is referenced. So comment out this section:
    ```asm
        /* Set base of available memory to end of non-initialised RAM area.  */
        LDR     r0, =_tx_initialize_unused_memory       // Build address of unused memory pointer
        LDR     r1, =__RAM_segment_used_end__           // Build first free address
        ADD     r1, r1, #4                              //
        STR     r1, [r0]                                // Setup first unused memory pointer
    ```


