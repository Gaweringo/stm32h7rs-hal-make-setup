#ifndef BOARD_H
#define BOARD_H

#include "stm32h7rsxx_hal.h"

struct GPIO_Setup {
    GPIO_TypeDef *Port;
    GPIO_InitTypeDef Setup;
};

enum GPIO_Pins {
    USER_BUTTON,
    USER_LED2,
    USER_LED3,
    GPIO_SETUP_COUNT,
};

void board_init(void);
void SystemClock_Config(void);
void error_handler(void);

void board_set_pin(enum GPIO_Pins pin, GPIO_PinState state);

#endif

