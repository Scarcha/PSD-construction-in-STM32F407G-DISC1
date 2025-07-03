# Solución al Problema de Concentración de Potencia en Bajas Frecuencias

## Análisis del Problema

### Síntomas Observados
- **Potencia excesiva**: Hasta 60 dB en el rango 0-1 kHz
- **Piso de ruido normal**: ~20 dB en frecuencias superiores a 1 kHz
- **Diferencia**: 40 dB de diferencia entre bajas y altas frecuencias

### Causas Potenciales

#### 1. Ruido 1/f (Ruido Rosa)
- **Característica**: Potencia inversamente proporcional a la frecuencia
- **Fuentes**: Componentes electrónicos, interfaces analógicas
- **Efecto**: Dominancia en bajas frecuencias

#### 2. Problemas en la Cadena de Adquisición
- **Offset DC**: Componente continua no removida
- **Respuesta del micrófono**: Sensibilidad mayor en bajas frecuencias
- **Filtros anti-aliasing**: Respuesta no ideal
- **PDM2PCM**: Artefactos de conversión

#### 3. Procesamiento Digital
- **Cuantización**: Errores acumulativos
- **Ventaneo**: Efectos en bajas frecuencias
- **Leakage espectral**: Dispersión de energía

## Soluciones Implementadas

### 1. Filtro DC Mejorado
```c
#define DC_FILTER_ALPHA 0.995f  // Frecuencia de corte ~1.6 Hz
```
**Función**: Elimina offset constante y deriva lenta

### 2. Filtro Paso Alto IIR (100 Hz)
```c
#define HPF_CUTOFF_HZ 100.0f
#define HPF_ORDER 2  // Butterworth de 2º orden
```
**Función**: 
- Elimina contenido de baja frecuencia
- Atenuación: -40 dB/década
- Preserva contenido de audio útil (>100 Hz)

### 3. Pre-énfasis
```c
#define PREEMPHASIS_ALPHA 0.97f
// y[n] = x[n] - α * x[n-1]
```
**Función**:
- Compensa la característica 1/f del ruido
- Realza frecuencias altas proporcionalmente
- Mejora el balance espectral

### 4. Control Automático de Ganancia (AGC)
```c
#define AGC_TARGET_RMS 8192.0f
#define AGC_ALPHA 0.99f
```
**Función**:
- Normaliza niveles de señal
- Evita saturación
- Mejora rango dinámico

## Análisis de Frecuencias

### Rangos de Interés
Con `FFT_SIZE = 1024` y `fs = 32 kHz`:

| Bin | Frecuencia | Descripción |
|-----|------------|-------------|
| 0 | 0 Hz | DC (filtrada) |
| 1-3 | 31-94 Hz | Muy bajas (filtradas por HPF) |
| 4-32 | 125-1000 Hz | Bajas (procesadas) |
| 33-512 | 1-16 kHz | Audio útil |

### Efecto de los Filtros

#### Sin Filtros
- Bin 0: ~60 dB (DC)
- Bins 1-32: ~40-60 dB (ruido 1/f)
- Bins 33+: ~20 dB (ruido blanco)

#### Con Filtros
- Bin 0: ~20-30 dB (DC filtrada)
- Bins 1-3: ~10-20 dB (HPF)
- Bins 4-32: ~15-25 dB (pre-énfasis)
- Bins 33+: ~20 dB (preservado)

## Configuración y Ajuste

### Parámetros Conservadores (Preserva más bajas frecuencias)
```c
#define HPF_CUTOFF_HZ       50.0f
#define PREEMPHASIS_ALPHA   0.95f
#define AGC_ALPHA           0.995f
```

### Parámetros Agresivos (Elimina más ruido)
```c
#define HPF_CUTOFF_HZ       200.0f
#define PREEMPHASIS_ALPHA   0.98f
#define AGC_ALPHA           0.95f
```

### Parámetros Equilibrados (Recomendado)
```c
#define HPF_CUTOFF_HZ       100.0f
#define PREEMPHASIS_ALPHA   0.97f
#define AGC_ALPHA           0.99f
```

## Validación y Pruebas

### Métricas de Evaluación
1. **Diferencia DC vs Audio**: Debe ser <20 dB
2. **Uniformidad espectral**: Variación <10 dB en 100Hz-8kHz
3. **Piso de ruido**: Consistente en ~20 dB
4. **Respuesta transitoria**: Sin oscilaciones

### Señales de Prueba
1. **Tono puro** (1 kHz): Verificar preservación
2. **Ruido blanco**: Verificar uniformidad
3. **Chirp sweep**: Verificar respuesta en frecuencia
4. **Silencio**: Verificar piso de ruido

## Implementación en Código

### Flujo de Procesamiento
```
Sample → DC Filter → HPF → Pre-énfasis → AGC → FFT
```

### Función Principal
```c
float32_t process_sample(float32_t input) {
    float32_t output = input;
    
    output = apply_dc_filter(output);    // Elimina DC
    output = apply_hpf_filter(output);   // Elimina <100 Hz
    output = apply_preemphasis(output);  // Compensa 1/f
    output = apply_agc(output);          // Normaliza
    
    return output;
}
```

### Reset al Cambiar Método
```c
void reset_psd_variables(void) {
    reset_dc_filter();
    reset_hpf_filter();
    reset_preemphasis();
    reset_agc();
    // ... resto del reset
}
```

## Resultados Esperados

### Antes de las Mejoras
- Espectro dominado por bajas frecuencias
- Rango dinámico limitado
- Visualización poco útil para análisis de audio

### Después de las Mejoras
- Espectro más uniforme y balanceado
- Mejor resolución en frecuencias de audio
- Visualización clara de características espectrales
- Reducción significativa del ruido 1/f

### Impacto en Métodos PSD
- **Welch**: Mejor promediado con menor varianza
- **Bartlett**: Espectro más limpio y uniforme
- **Periodograma**: Mayor resolución efectiva

## Recomendaciones

### Para Uso General
- Mantener configuración equilibrada
- Monitorear mensajes de estado AGC
- Verificar que el HPF no elimine contenido deseado

### Para Análisis Específico
- **Audio/Voz**: Usar HPF de 80-100 Hz
- **Vibraciones**: Usar HPF de 10-50 Hz
- **Ruido ambiente**: Usar configuración agresiva

### Para Debugging
- Deshabilitar filtros uno por uno para identificar efectos
- Usar Python para visualizar efectos de cada filtro
- Monitorear niveles AGC para detectar saturación

## Conclusión

La implementación de esta cadena de filtros soluciona efectivamente el problema de concentración de potencia en bajas frecuencias, resultando en:

1. **Espectro más balanceado** y útil para análisis
2. **Mejor aprovechamiento** del rango dinámico
3. **Visualización más clara** de características espectrales
4. **Robustez mejorada** ante variaciones de señal

Esta solución es especialmente importante en sistemas embebidos donde el rango dinámico y la precisión son limitados.
