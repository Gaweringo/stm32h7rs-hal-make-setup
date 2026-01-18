#include "board.h"
#include "stm32h7rsxx_hal.h"
#include "stm32h7s3xx.h"
#include <stdint.h>

int main(void) {
    board_init();

    while (1) {
        board_set_pin(USER_LED2, GPIO_PIN_RESET);
        board_set_pin(USER_LED3, GPIO_PIN_SET);
        HAL_Delay(500);
        board_set_pin(USER_LED2, GPIO_PIN_SET);
        board_set_pin(USER_LED3, GPIO_PIN_RESET);
        HAL_Delay(500);
    }
}
