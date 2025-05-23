################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctions.c \
../Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctionsF16.c \
../Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f16.c \
../Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f32.c 

OBJS += \
./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctions.o \
./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctionsF16.o \
./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f16.o \
./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f32.o 

C_DEPS += \
./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctions.d \
./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctionsF16.d \
./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f16.d \
./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f32.d 


# Each subdirectory must supply rules for building sources it contributes
Drivers/CMSIS_DSP/Source/BayesFunctions/%.o Drivers/CMSIS_DSP/Source/BayesFunctions/%.su Drivers/CMSIS_DSP/Source/BayesFunctions/%.cyclo: ../Drivers/CMSIS_DSP/Source/BayesFunctions/%.c Drivers/CMSIS_DSP/Source/BayesFunctions/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F407xx -c -I../USB_HOST/App -I../USB_HOST/Target -I../Core/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Middlewares/ST/STM32_USB_Host_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Host_Library/Class/CDC/Inc -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/HelloWorldFFT/Drivers/CMSIS_DSP/Include" -I"C:/Users/Tomas/STM32CubeIDE/workspace_1.16.1/HolaMundoFFTCMSIS5/PSD-construction-in-STM32F407G-DISC1/HelloWorldFFT/Drivers/CMSIS_DSP/PrivateInclude" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Drivers-2f-CMSIS_DSP-2f-Source-2f-BayesFunctions

clean-Drivers-2f-CMSIS_DSP-2f-Source-2f-BayesFunctions:
	-$(RM) ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctions.cyclo ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctions.d ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctions.o ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctions.su ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctionsF16.cyclo ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctionsF16.d ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctionsF16.o ./Drivers/CMSIS_DSP/Source/BayesFunctions/BayesFunctionsF16.su ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f16.cyclo ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f16.d ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f16.o ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f16.su ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f32.cyclo ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f32.d ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f32.o ./Drivers/CMSIS_DSP/Source/BayesFunctions/arm_gaussian_naive_bayes_predict_f32.su

.PHONY: clean-Drivers-2f-CMSIS_DSP-2f-Source-2f-BayesFunctions

