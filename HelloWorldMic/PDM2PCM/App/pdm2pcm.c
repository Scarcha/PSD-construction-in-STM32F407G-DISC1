/* USER CODE BEGIN Header */
/**
 ******************************************************************************
  * File Name          : pdm2pcm.c
  * Description        : This file provides code for the configuration
  *                      of the pdm2pcm instances.
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
#include "pdm2pcm.h"

/* USER CODE BEGIN 0 */
/* USER CODE END 0 */

/* Global variables ---------------------------------------------------------*/
PDM_Filter_Handler_t PDM1_filter_handler;
PDM_Filter_Config_t PDM1_filter_config;

/* USER CODE BEGIN 1 */
/* USER CODE END 1 */

/* PDM2PCM init function */
void MX_PDM2PCM_Init(void)
{
  /* USER CODE BEGIN 2 */
  /* USER CODE END 2 */

   /**
  */
  PDM1_filter_handler.bit_order = PDM_FILTER_BIT_ORDER_LSB;
  PDM1_filter_handler.endianness = PDM_FILTER_ENDIANNESS_BE;
  PDM1_filter_handler.high_pass_tap = 2104533974;
  PDM1_filter_handler.in_ptr_channels = 1;
  PDM1_filter_handler.out_ptr_channels = 1;
  PDM_Filter_Init(&PDM1_filter_handler);

  PDM1_filter_config.decimation_factor = PDM_FILTER_DEC_FACTOR_64;
  PDM1_filter_config.output_samples_number = 16;
  PDM1_filter_config.mic_gain = 0;
  PDM_Filter_setConfig(&PDM1_filter_handler, &PDM1_filter_config);

  /* USER CODE BEGIN 3 */
  /* USER CODE END 3 */

}

/* USER CODE BEGIN 4 */

/* process function */
uint8_t MX_PDM2PCM_Process(uint16_t *PDMBuf, uint16_t *PCMBuf)
{
  // PDM1_filter_handler ya está configurada por MX_PDM2PCM_Init()
  // PDM1_filter_config.output_samples_number (que es 16) también está configurada.
  // La librería PDM_Filter usará estos valores.

  // La función PDM_Filter de la librería de ST usualmente tiene una firma como:
  // void PDM_Filter_Raw(uint8_t* data_in, int16_t* data_out, PDM_Filter_Handler_t* handler);
  // o PDM_Filter(void* data_in, void* data_out, PDM_Filter_Handler_t* handler);
  // Los tipos de puntero son importantes. PDMBuf es uint16_t* y PCMBuf es uint16_t*.
  // La librería PDM a menudo espera uint8_t* para la entrada PDM (ya que son bits empaquetados)
  // y int16_t* para la salida PCM (audio con signo).

  // Ajusta los casts según la firma exacta de PDM_Filter en tu pdm_filter.h.
  // Es muy común que la entrada PDM sea (uint8_t*) y la salida PCM (int16_t*).
  PDM_Filter((uint8_t*)PDMBuf, (int16_t*)PCMBuf, &PDM1_filter_handler);

  // Si la función PDM_Filter no devuelve un código de error, asumimos éxito.
  return 0; // Retorna 0 para éxito (AUDIO_OK)
}

/* USER CODE END 4 */

/**
  * @}
  */
