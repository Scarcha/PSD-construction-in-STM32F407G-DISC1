# Diagnóstico de Curvas en Altas Frecuencias

## Estado Actual

**Todos los filtros están DESHABILITADOS** para obtener el espectro completamente natural del sistema.

## Posibles Fuentes de Curvas en Altas Frecuencias

### 1. 🔍 **Artefactos del Sistema PDM2PCM**
- **Causa**: Filtros anti-aliasing internos del convertidor PDM2PCM
- **Característica**: Caída en la respuesta cerca de Nyquist (16 kHz)
- **Normal**: Esperado en sistemas PDM
- **Solución**: Inherente al sistema, no requiere corrección

### 2. 🎤 **Respuesta del Micrófono**
- **Causa**: Respuesta en frecuencia no plana del micrófono MEMS
- **Característica**: Picos o caídas en ciertas frecuencias
- **Verificación**: Consultar datasheet del micrófono
- **Solución**: Compensación específica del modelo de micrófono

### 3. ⚡ **Aliasing Residual**
- **Causa**: Filtros anti-aliasing insuficientes
- **Característica**: Réplicas espectrales en altas frecuencias
- **Verificación**: Patrones repetitivos o simétricos
- **Solución**: Verificar configuración de filtros PDM

### 4. 🔧 **Efectos de Ventaneo FFT**
- **Causa**: Discontinuidades en los bordes de la ventana
- **Característica**: Oscilaciones o ondulaciones
- **Verificación**: Comparar diferentes tipos de ventana
- **Solución**: Verificar implementación de ventanas

### 5. 🏗️ **Configuración del I2S/PDM**
- **Causa**: Configuración incorrecta de clock o formato
- **Característica**: Distorsión o patrones artificiales
- **Verificación**: Revisar configuración IOC
- **Solución**: Verificar parámetros de reloj

## Plan de Diagnóstico

### Paso 1: Identificar el Patrón
Observa la curva y determina:
- ¿En qué frecuencias aparece? (ej: 8-16 kHz)
- ¿Es consistente entre métodos PSD?
- ¿Tiene forma específica? (caída, pico, ondulación)

### Paso 2: Análisis por Método
Compara los tres métodos PSD:
- **Welch**: ¿La curva es más suave debido al promediado?
- **Bartlett**: ¿Similar a Welch pero con más varianza?
- **Periodograma**: ¿Muestra la curva más claramente?

### Paso 3: Características Esperadas
Según el sistema STM32F407G-DISC1:
- **0-100 Hz**: Puede tener ruido 1/f natural
- **100-8000 Hz**: Debería ser relativamente plano
- **8000-16000 Hz**: Caída natural del anti-aliasing PDM
- **Bin DC**: Puede ser alto debido a offset

## Configuraciones de Prueba

### Para Verificar Fuente de la Curva

#### Prueba 1: Solo Filtro DC Extremadamente Suave
```c
#define ENABLE_DC_FILTER    1
#define DC_FILTER_ALPHA     0.9999f  // Casi imperceptible
```

#### Prueba 2: Cambiar Tipo de Ventana
En `main.c`, temporalmente cambiar:
```c
#define PERIODOGRAM_WINDOW_TYPE 0  // Rectangular
#define PERIODOGRAM_WINDOW_TYPE 2  // Hamming
```

#### Prueba 3: Verificar con Señal de Prueba
- Generar tono puro de 1 kHz
- Verificar si la curva persiste
- Comparar con ruido ambiente

## Interpretación de Resultados

### Si la Curva es Consistente
- Probablemente es característica del hardware (micrófono/PDM)
- **Normal y esperado** en sistemas embebidos
- No requiere corrección agresiva

### Si la Curva Varía
- Puede ser artefacto de procesamiento
- Revisar configuración de ventanas
- Verificar implementación FFT

### Si Aparece Solo en Ciertos Métodos
- Problema específico del algoritmo PSD
- Revisar implementación del método específico
- Verificar normalización o escalado

## Acciones Recomendadas

1. **Compilar y probar** con filtros deshabilitados
2. **Documentar** las características de la curva observada
3. **Comparar** entre los tres métodos PSD
4. **Identificar** si es característica del hardware o artefacto
5. **Decidir** si requiere compensación o es aceptable

## Notas Importantes

- **Las curvas en altas frecuencias son NORMALES** en sistemas PDM
- **El roll-off cerca de Nyquist es ESPERADO**
- **No todos los artefactos requieren corrección**
- **El objetivo es un espectro útil, no perfecto**

Con todos los filtros deshabilitados, ahora verás el comportamiento real del sistema sin alteraciones artificiales.
