/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "crc.h"
#include "dma.h"
#include "i2c.h"
#include "i2s.h"
#include "pdm2pcm.h"
#include "spi.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdint.h>
#include <string.h>
#include "../Components/cs43l22/cs43l22.h"
#include "../STM32F4-Discovery/stm32f4_discovery.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
enum ERROR{
	CHILL = -20,
	PDM2PCM = -21,
	CODEC = -22,
	I2S_TX = -23,
	I2S_RX = -24,
	CODEC_PLAY = -25,
	OVR = -26,
	UDR = -27,
};
/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define PCM_SAMPLING_FREQ       32000U  // Salida PCM deseada en Hz
#define PDM_MIC_CHANNELS        1U      // Micrófono PDM es mono
#define PCM_OUT_CHANNELS        1U
#define CODEC_PCM_OUT_CHANNELS  2U
#define AUDIO_FREQ_PDM_HAL      64000U
#define PCM_MONO_SAMPLES_PER_HALF_BUFFER    (16 * 32) // 512 muestras MONO; 16 llamadas a MX_PDM2PCM_Process
#define PCM_STEREO_OUTPUT_HALF_BUFFER_SIZE_UINT16  (PCM_MONO_SAMPLES_PER_HALF_BUFFER * CODEC_PCM_OUT_CHANNELS) // 256 * 2 = 512
#define PDM_BYTES_PER_PROCESS_CALL         (16 * (64 / 8U)) // 16 * 8 = 128 bytes PDM
#define NUM_PDM_PROCESS_CALLS_PER_HALF_BUFFER (PCM_MONO_SAMPLES_PER_HALF_BUFFER / 16) // 256 / 16 = 16
#define PDM_RAW_INPUT_HALF_BUFFER_SIZE_BYTES       (PDM_BYTES_PER_PROCESS_CALL * NUM_PDM_PROCESS_CALLS_PER_HALF_BUFFER) // 128 * 16 = 2048 bytes
#define PDM_RAW_INPUT_HALF_BUFFER_SIZE_UINT16      (PDM_RAW_INPUT_HALF_BUFFER_SIZE_BYTES / 2U) // 1024
#define CS43L22_ADDRESS         0x94U  // Dirección I2C de 8 bits para CS43L22 (0x4A << 1)
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
uint16_t pdm_raw_buffer[2][PDM_RAW_INPUT_HALF_BUFFER_SIZE_UINT16];
int16_t  pcm_mono_processed_half_buffer[PCM_MONO_SAMPLES_PER_HALF_BUFFER]; // << VUELVE EL BUFFER MONO
uint16_t pcm_stereo_output_buffer[2][PCM_STEREO_OUTPUT_HALF_BUFFER_SIZE_UINT16];

volatile uint8_t pdm_input_buffer_idx = 2;
volatile uint8_t pcm_output_buffer_ready_for_filling_idx = 0;
extern PDM_Filter_Config_t PDM1_filter_config;
enum ERROR e = CHILL;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
void PeriphCommonClock_Config(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */



/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */
	uint8_t initial_codec_volume = 120;
	uint16_t pdm_buffer_offset_uint16 = 0;
	uint16_t pcm_mono_buffer_offset = 0; // Offset para pcm_mono_processed_half_buffer

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* Configure the peripherals common clocks */
  PeriphCommonClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_CRC_Init();
  MX_PDM2PCM_Init();
  MX_I2S2_Init();
  MX_I2C1_Init();
  MX_I2S3_Init();
  MX_SPI1_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */

  if (cs43l22_Init(CS43L22_ADDRESS, OUTPUT_DEVICE_HEADPHONE, initial_codec_volume, PCM_SAMPLING_FREQ) != 0) {
      e = CODEC;
      Error_Handler();
  }

  if (cs43l22_Play(CS43L22_ADDRESS, NULL, 0) != 0) {
	  e = CODEC;
      Error_Handler();
  }

  memset(pcm_stereo_output_buffer, 0, sizeof(pcm_stereo_output_buffer));

  if (HAL_I2S_Transmit_DMA(&hi2s3, (uint16_t *)pcm_stereo_output_buffer, PCM_STEREO_OUTPUT_HALF_BUFFER_SIZE_UINT16 * 2) != HAL_OK) {
    Error_Handler();
  }

  if (HAL_I2S_Receive_DMA(&hi2s2, (uint16_t *)pdm_raw_buffer, PDM_RAW_INPUT_HALF_BUFFER_SIZE_UINT16 * 2) != HAL_OK) {
    Error_Handler();
  }

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
	  if (pdm_input_buffer_idx != 2) { // Un buffer PDM está listo (0 o 1)
	        uint16_t* pdm_half_buffer_start_ptr;
	        uint16_t* pcm_stereo_half_buffer_start_ptr;

	        if (pdm_input_buffer_idx == 0) {
	          pdm_half_buffer_start_ptr = pdm_raw_buffer[0];
	        } else {
	          pdm_half_buffer_start_ptr = pdm_raw_buffer[1];
	        }

	        // Procesar el PDM_RAW_INPUT_HALF_BUFFER en trozos, llenando pcm_mono_processed_half_buffer
	        pdm_buffer_offset_uint16 = 0;
	        pcm_mono_buffer_offset = 0; // Offset para pcm_mono_processed_half_buffer

	        for (int i = 0; i < NUM_PDM_PROCESS_CALLS_PER_HALF_BUFFER; i++) {
	          // MX_PDM2PCM_Process ahora toma (uint16_t *PDMBuf, uint16_t *PCMBuf)
	          // y PDM1_filter_config.output_samples_number = 16 (mono)
	          if (MX_PDM2PCM_Process(
	                  pdm_half_buffer_start_ptr + pdm_buffer_offset_uint16,
	                  (uint16_t*)(pcm_mono_processed_half_buffer + pcm_mono_buffer_offset) // Escribe 16 muestras mono aquí
	               ) != 0) { // Retorna 0 para éxito
	              e = PDM2PCM;
	          }
	          pdm_buffer_offset_uint16 += (PDM_BYTES_PER_PROCESS_CALL / 2U);
	          pcm_mono_buffer_offset += PDM1_filter_config.output_samples_number; // Avanza por 16 muestras mono
	        }

	        // Ahora que pcm_mono_processed_half_buffer está lleno, espera a que un buffer de salida estéreo esté libre
	        while (pcm_output_buffer_ready_for_filling_idx == 2) { /* Espera ocupada */ }

	        if (pcm_output_buffer_ready_for_filling_idx == 0) {
	          pcm_stereo_half_buffer_start_ptr = pcm_stereo_output_buffer[0];
	        } else { // pcm_output_buffer_ready_for_filling_idx == 1
	          pcm_stereo_half_buffer_start_ptr = pcm_stereo_output_buffer[1];
	        }

	        // Convertir el pcm_mono_processed_half_buffer a pcm_stereo_half_buffer_start_ptr
	        for (uint16_t i = 0; i < PCM_MONO_SAMPLES_PER_HALF_BUFFER; i++) {
	          pcm_stereo_half_buffer_start_ptr[i * 2]     = (uint16_t)pcm_mono_processed_half_buffer[i];
	          pcm_stereo_half_buffer_start_ptr[i * 2 + 1] = (uint16_t)pcm_mono_processed_half_buffer[i];
	        }

	        pdm_input_buffer_idx = 2;
	        pcm_output_buffer_ready_for_filling_idx = 2;
	      }
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 8;
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 7;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief Peripherals Common Clock Configuration
  * @retval None
  */
void PeriphCommonClock_Config(void)
{
  RCC_PeriphCLKInitTypeDef PeriphClkInitStruct = {0};

  /** Initializes the peripherals clock
  */
  PeriphClkInitStruct.PeriphClockSelection = RCC_PERIPHCLK_I2S;
  PeriphClkInitStruct.PLLI2S.PLLI2SN = 384;
  PeriphClkInitStruct.PLLI2S.PLLI2SR = 2;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */
void HAL_I2S_RxHalfCpltCallback(I2S_HandleTypeDef *hi2s)
{
  if (hi2s->Instance == SPI2) {
    pdm_input_buffer_idx = 0;
  }
}

void HAL_I2S_RxCpltCallback(I2S_HandleTypeDef *hi2s)
{
  if (hi2s->Instance == SPI2) {
    pdm_input_buffer_idx = 1;
  }
}

void HAL_I2S_TxHalfCpltCallback(I2S_HandleTypeDef *hi2s)
{
  if (hi2s->Instance == SPI3) {
    pcm_output_buffer_ready_for_filling_idx = 0;
  }
}

void HAL_I2S_TxCpltCallback(I2S_HandleTypeDef *hi2s)
{
  if (hi2s->Instance == SPI3) {
     pcm_output_buffer_ready_for_filling_idx = 1;
  }
}

void HAL_I2S_ErrorCallback(I2S_HandleTypeDef *hi2s)
{
  if (hi2s->Instance == SPI2) { // I2S2 para PDM Mic
	if (hi2s->ErrorCode & HAL_I2S_ERROR_OVR) {
	  e = OVR;
	}
  } else if (hi2s->Instance == SPI3) { // I2S3 para CODEC
	if (hi2s->ErrorCode & HAL_I2S_ERROR_UDR) {
	  e = UDR;
	}
  }
}


/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
