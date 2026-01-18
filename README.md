# Setup
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

# Requirements
## Arch / Linux
- `arm-none-eabi-gcc`
- `arm-none-eabi-newlib`
