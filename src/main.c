#include "board.h"
#include "stm32h7rsxx_hal.h"
#include "stm32h7s3xx.h" // IWYU pragma: keep
#include "tx_api.h"
#include "util.h"
#include <stdint.h>

#define BYTE_POOL_SIZE KiB(3)
#define DEFAULT_STACK_SIZE KiB(1)

#define DEFAULT_PREEMPT_THRESHOLD 7
#define DEFAULT_PRIORITY 7

static inline size_t ms_to_tx_ticks(size_t ms) {
    return (ms * TX_TIMER_TICKS_PER_SECOND) / 1000;
}

static void main_thread_entry(ULONG thread_input);

// Entry point after calling tx_kernel_enter();
//
// Here, memory pools, stacks, threads, mutex, semaphores, queues and so on will be created
// In here no HAL Functiosn should be called, since (as far as I understood it, interrupts are
// disabled during this function)
void tx_application_define(void *first_unused_memory) {
    // TODO(MaHa): Figure out what this is set to and how to work with it.
    // What is the recommended way to create the byte pools? Should they be in first_unused_memory?
    // Is first_unused_memory specified from the linker script and then the tx_initialize_low_level?
    //
    // Seems like the first_unused_memory is used for heap / dynamic allocation and needs changes in
    // the linker script.
    //
    UNUSED(first_unused_memory);

    board_set_pin(USER_LED2, GPIO_PIN_SET);

    static TX_BYTE_POOL byte_pool_0;
    static UCHAR memory_area[BYTE_POOL_SIZE];
    static TX_THREAD main_thread;

    // Buffer backed byte pool
    if (tx_byte_pool_create(&byte_pool_0, "byte pool 0", memory_area, BYTE_POOL_SIZE) != TX_SUCCESS) {
        error_handler();
    }

    // Allocate space for a stack in the byte pool
    CHAR *main_thread_stack_start = TX_NULL;
    if (tx_byte_allocate(&byte_pool_0, (VOID **)&main_thread_stack_start, DEFAULT_STACK_SIZE,
                     TX_NO_WAIT) != TX_SUCCESS) {
        error_handler();
    }

    // Create the first thread
    if (tx_thread_create(&main_thread, "main thread", main_thread_entry, 0, main_thread_stack_start,
                     DEFAULT_STACK_SIZE, DEFAULT_PRIORITY, DEFAULT_PREEMPT_THRESHOLD,
                     TX_NO_TIME_SLICE, TX_AUTO_START) != TX_SUCCESS) {
        error_handler();
    }
}

int main(void) {
    board_init();

    tx_kernel_enter();

    error_handler();
}

static void main_thread_entry(ULONG thread_input) {
    UNUSED(thread_input);

    while (1) {
        board_set_pin(USER_LED2, GPIO_PIN_RESET);
        board_set_pin(USER_LED1, GPIO_PIN_SET);
        tx_thread_sleep(ms_to_tx_ticks(500));
        board_set_pin(USER_LED2, GPIO_PIN_SET);
        board_set_pin(USER_LED1, GPIO_PIN_RESET);
        tx_thread_sleep(ms_to_tx_ticks(500));
    }
}
