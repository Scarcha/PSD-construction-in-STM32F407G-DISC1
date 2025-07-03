# Filtro Notch 50 Hz - Eliminación de Interferencia de Red Eléctrica

## ¿Qué es un Filtro Notch?

Un filtro notch (también llamado band-stop o rechazo de banda) es un filtro que elimina una frecuencia específica mientras permite que todas las demás pasen relativamente sin cambios. Es ideal para eliminar interferencias tonales específicas como la frecuencia de la red eléctrica.

## Implementación

### Configuración Actual
- **Frecuencia**: 50 Hz (red eléctrica europea)
- **Factor Q**: 30 (ancho de banda muy estrecho)
- **Tipo**: Filtro IIR de segundo orden
- **Ubicación**: Después del pre-procesamiento básico

### Cálculo de Coeficientes
```c
// Diseño del filtro notch
float32_t w = 2π * fc / fs;        // Frecuencia normalizada
float32_t α = sin(w) / (2 * Q);    // Factor de calidad
float32_t cos_w = cos(w);

// Coeficientes numerador (ceros)
b0 = 1
b1 = -2 * cos(w) 
b2 = 1

// Coeficientes denominador (polos)
a1 = -2 * cos(w) / (1 + α)
a2 = (1 - α) / (1 + α)
```

### Función de Transferencia
```
H(z) = (1 - 2*cos(w)*z^-1 + z^-2) / (1 + a1*z^-1 + a2*z^-2)
```

## Características del Filtro

### Ancho de Banda
Con Q = 30, el ancho de banda a -3dB es aproximadamente:
- BW = fc / Q = 50 Hz / 30 ≈ 1.67 Hz
- Esto significa que afecta principalmente entre ~49-51 Hz

### Atenuación
- **En 50 Hz**: > -40 dB (atenuación muy fuerte)
- **En 49/51 Hz**: ≈ -3 dB 
- **En 48/52 Hz**: ≈ -0.5 dB (prácticamente sin efecto)

## Ventajas del Filtro Notch

1. **Selectividad Alta**: Solo afecta la frecuencia objetivo
2. **Preservación del Espectro**: Mantiene el resto del contenido
3. **Eliminación Efectiva**: Reduce significativamente la interferencia
4. **Implementación Eficiente**: Solo requiere 5 multiplicaciones por muestra

## Posibles Fuentes de Interferencia a 50 Hz

1. **Red Eléctrica**: Acoplamiento capacitivo/inductivo
2. **Fuentes de Alimentación**: Ripple de rectificación
3. **Iluminación**: Lámparas fluorescentes, LED mal filtrados
4. **Motores**: Equipos conectados a la red
5. **Cables de Alimentación**: Radiación electromagnética

## Cómo Verificar la Efectividad

### Antes del Filtro
- Buscar un pico prominente exactamente en 50 Hz
- Puede aparecer como una línea espectral muy estrecha
- A menudo es mucho más alto que el ruido de fondo

### Después del Filtro
- El pico en 50 Hz debe desaparecer o reducirse drasticamente
- El resto del espectro debe permanecer prácticamente igual
- Mejora en la relación señal/ruido general

## Configuración Flexible

El filtro se puede ajustar modificando `filter_config.h`:

```c
// Para diferentes frecuencias de red
#define NOTCH_FREQ_HZ    60.0f    // Red americana
#define NOTCH_FREQ_HZ    50.0f    // Red europea/asiática

// Para diferentes anchos de banda
#define NOTCH_Q_FACTOR   10.0f    // Más ancho (BW = 5 Hz)
#define NOTCH_Q_FACTOR   50.0f    // Más estrecho (BW = 1 Hz)
```

## Comparación de Métodos

| Aspecto | Sin Filtro | Con Notch 50 Hz |
|---------|------------|-----------------|
| Interferencia 50 Hz | Visible | Eliminada |
| Resto del espectro | Natural | Prácticamente igual |
| Latencia | Mínima | +2 muestras |
| Complejidad | Baja | Baja |
| Uso CPU | Mínimo | +0.1% |

## Alternativas Consideradas

1. **Filtro Comb**: Múltiples armónicos (50, 100, 150 Hz)
2. **Filtro Adaptativo**: Auto-ajuste de frecuencia
3. **Filtro FIR**: Mayor latencia pero fase lineal
4. **Processado Post-FFT**: Eliminar bins específicos

## Recomendaciones de Uso

1. **Usar cuando**: Hay interferencia visible en 50 Hz
2. **No usar cuando**: El espectro es limpio en esa frecuencia
3. **Monitorear**: Efectividad a través de comparación antes/después
4. **Combinar**: Con otros filtros si es necesario

## Estado Actual del Sistema

- ✅ Filtro notch implementado y activo
- ✅ Factor Q = 30 (muy selectivo)
- ✅ Frecuencia = 50 Hz
- ✅ Todos los otros filtros deshabilitados
- ✅ Visualización actualizada en Python

## Próximos Experimentos Sugeridos

1. **Comparación A/B**: Habilitar/deshabilitar filtro
2. **Sweep de Q**: Probar Q = 10, 20, 30, 50
3. **Múltiples Frecuencias**: 50 Hz + 100 Hz (segundo armónico)
4. **Análisis de Armónicos**: Verificar si hay múltiplos de 50 Hz
