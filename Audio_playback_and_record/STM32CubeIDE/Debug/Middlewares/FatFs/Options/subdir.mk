################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (13.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/Audio_playback_and_record/Middlewares/Third_Party/FatFs/src/option/syscall.c \
C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/Audio_playback_and_record/Middlewares/Third_Party/FatFs/src/option/unicode.c 

OBJS += \
./Middlewares/FatFs/Options/syscall.o \
./Middlewares/FatFs/Options/unicode.o 

C_DEPS += \
./Middlewares/FatFs/Options/syscall.d \
./Middlewares/FatFs/Options/unicode.d 


# Each subdirectory must supply rules for building sources it contributes
Middlewares/FatFs/Options/syscall.o: C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/Audio_playback_and_record/Middlewares/Third_Party/FatFs/src/option/syscall.c Middlewares/FatFs/Options/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_STM32F4_DISCO -DSTM32F407xx -DUSE_HAL_DRIVER -c -I../../Inc -I../../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../../Drivers/STM32F4xx_HAL_Driver/Inc -I../../Drivers/BSP/STM32F4-Discovery -I../../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../../Middlewares/ST/STM32_USB_Host_Library/Class/MSC/Inc -I../../Middlewares/ST/STM32_USB_Host_Library/Core/Inc -I../../Middlewares/ST/STM32_Audio/Addons/PDM/Inc -I../../Middlewares/Third_Party/FatFs/src -I../../Drivers/CMSIS/Include -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Middlewares/FatFs/Options/unicode.o: C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/Audio_playback_and_record/Middlewares/Third_Party/FatFs/src/option/unicode.c Middlewares/FatFs/Options/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_STM32F4_DISCO -DSTM32F407xx -DUSE_HAL_DRIVER -c -I../../Inc -I../../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../../Drivers/STM32F4xx_HAL_Driver/Inc -I../../Drivers/BSP/STM32F4-Discovery -I../../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../../Middlewares/ST/STM32_USB_Host_Library/Class/MSC/Inc -I../../Middlewares/ST/STM32_USB_Host_Library/Core/Inc -I../../Middlewares/ST/STM32_Audio/Addons/PDM/Inc -I../../Middlewares/Third_Party/FatFs/src -I../../Drivers/CMSIS/Include -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Middlewares-2f-FatFs-2f-Options

clean-Middlewares-2f-FatFs-2f-Options:
	-$(RM) ./Middlewares/FatFs/Options/syscall.cyclo ./Middlewares/FatFs/Options/syscall.d ./Middlewares/FatFs/Options/syscall.o ./Middlewares/FatFs/Options/syscall.su ./Middlewares/FatFs/Options/unicode.cyclo ./Middlewares/FatFs/Options/unicode.d ./Middlewares/FatFs/Options/unicode.o ./Middlewares/FatFs/Options/unicode.su

.PHONY: clean-Middlewares-2f-FatFs-2f-Options

