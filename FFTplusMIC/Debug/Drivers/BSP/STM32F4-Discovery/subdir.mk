################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (13.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/BSP/STM32F4-Discovery/stm32f4_discovery.c 

OBJS += \
./Drivers/BSP/STM32F4-Discovery/stm32f4_discovery.o 

C_DEPS += \
./Drivers/BSP/STM32F4-Discovery/stm32f4_discovery.d 


# Each subdirectory must supply rules for building sources it contributes
Drivers/BSP/STM32F4-Discovery/%.o Drivers/BSP/STM32F4-Discovery/%.su Drivers/BSP/STM32F4-Discovery/%.cyclo: ../Drivers/BSP/STM32F4-Discovery/%.c Drivers/BSP/STM32F4-Discovery/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F407xx -c -I../Core/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I../PDM2PCM/App -I../Middlewares/ST/STM32_Audio/Addons/PDM/Inc -I"C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/FFTplusMIC/Drivers/BSP" -I"C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/FFTplusMIC/Drivers/BSP/Components" -I"C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/FFTplusMIC/Drivers/CMSIS_DSP/Include" -I"C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/FFTplusMIC/Drivers/CMSIS_DSP/PrivateInclude" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Drivers-2f-BSP-2f-STM32F4-2d-Discovery

clean-Drivers-2f-BSP-2f-STM32F4-2d-Discovery:
	-$(RM) ./Drivers/BSP/STM32F4-Discovery/stm32f4_discovery.cyclo ./Drivers/BSP/STM32F4-Discovery/stm32f4_discovery.d ./Drivers/BSP/STM32F4-Discovery/stm32f4_discovery.o ./Drivers/BSP/STM32F4-Discovery/stm32f4_discovery.su

.PHONY: clean-Drivers-2f-BSP-2f-STM32F4-2d-Discovery

