#include "board.h"

static struct GPIO_Setup gpio_setup[GPIO_SETUP_COUNT] = {
    [USER_BUTTON] =
        {
            GPIOC,
            {
                .Pin = GPIO_PIN_13,
                .Mode = GPIO_MODE_INPUT,
                .Pull = GPIO_PULLUP,
                .Speed = GPIO_SPEED_FREQ_LOW,
            },
        },
    [USER_LED1] =
        {
            GPIOD,
            {
                .Pin = GPIO_PIN_10,
                .Mode = GPIO_MODE_OUTPUT_PP,
                .Pull = GPIO_NOPULL,
                .Speed = GPIO_SPEED_FREQ_MEDIUM,
            },
        },
    [USER_LED2] =
        {
            GPIOD,
            {
                .Pin = GPIO_PIN_13,
                .Mode = GPIO_MODE_OUTPUT_PP,
                .Pull = GPIO_NOPULL,
                .Speed = GPIO_SPEED_FREQ_MEDIUM,
            },
        },
    [USER_LED3] =
        {
            GPIOB,
            {
                .Pin = GPIO_PIN_7,
                .Mode = GPIO_MODE_OUTPUT_PP,
                .Pull = GPIO_NOPULL,
                .Speed = GPIO_SPEED_FREQ_MEDIUM,
            },
        },
};

void board_init(void) {
    HAL_Init();

    SystemClock_Config();

    SystemCoreClockUpdate();

    // Required GPIO Clocks
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOC_CLK_ENABLE();
    __HAL_RCC_GPIOD_CLK_ENABLE();

    // Initialize all gpio pins
    for (size_t i = 0; i < GPIO_SETUP_COUNT; i++) {
        HAL_GPIO_Init(gpio_setup[i].Port, &gpio_setup[i].Setup);
    }
}

void board_set_pin(enum GPIO_Pins pin, GPIO_PinState state) {
    HAL_GPIO_WritePin(gpio_setup[pin].Port, gpio_setup[pin].Setup.Pin, state);
}

// TODO(MaHa): Maybe call it something like 'give_up' or semething else that signals, that it
// doesn't 'handle' errors, but just stops everything and gives up
void error_handler(void) {
    // TODO(MaHa): Dump state to trace output, same for HardFault or other fault handlers
    __disable_irq();
    board_set_pin(USER_LED3, GPIO_PIN_SET);
    while (1) {}
}

void SystemClock_Config(void) {

    if (HAL_PWREx_ConfigSupply(PWR_LDO_SUPPLY) != HAL_OK) { error_handler(); }

    if (HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE0) != HAL_OK) {
        error_handler();
    }

    RCC_OscInitTypeDef osc_init = {
        .OscillatorType = RCC_OSCILLATORTYPE_HSI,
        .HSIState = RCC_HSI_ON,
        .HSIDiv = RCC_HSI_DIV1,
        .HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT,
        .PLL1.PLLState = RCC_PLL_ON,
        .PLL1.PLLSource = RCC_PLLSOURCE_HSI,
        .PLL1.PLLM = 16,
        .PLL1.PLLN = 150,
        .PLL1.PLLP = 1,
        .PLL1.PLLQ = 2,
        .PLL1.PLLR = 2,
        .PLL1.PLLS = 2,
        .PLL1.PLLT = 2,
        .PLL1.PLLFractional = 0,
        .PLL2.PLLState = RCC_PLL_NONE,
        .PLL3.PLLState = RCC_PLL_NONE,
    };

    if (HAL_RCC_OscConfig(&osc_init) != HAL_OK) { error_handler(); }

    RCC_ClkInitTypeDef RCC_ClkInitStruct = {
        .ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_PCLK1 |
                     RCC_CLOCKTYPE_PCLK2 | RCC_CLOCKTYPE_PCLK4 | RCC_CLOCKTYPE_PCLK5,
        .SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK,
        .SYSCLKDivider = RCC_SYSCLK_DIV1,
        .AHBCLKDivider = RCC_HCLK_DIV2,
        .APB1CLKDivider = RCC_APB1_DIV2,
        .APB2CLKDivider = RCC_APB2_DIV2,
        .APB4CLKDivider = RCC_APB4_DIV2,
        .APB5CLKDivider = RCC_APB5_DIV2,
    };

    if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_7) != HAL_OK) { error_handler(); }
}
