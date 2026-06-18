# Setup
## Requirements

- Ninja
- CMake
- Make
- arm-none-eabi-gcc
- pyOCD
- STM32_Programmer_CLI (optional)

## Build
To get the required dependencies firt run
```
git submodule update --init --recursive
```

Then build with
```
make
```

and flash with
```
make flash-pyocd
```
(requires `pyocd pack install stm32h7s3l8Hx`)

For a list of available make commands run
```bash
make help
```
