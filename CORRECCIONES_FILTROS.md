# Correcciones Realizadas en el Sistema de Filtros

## Problemas Identificados y Corregidos

### 1. Filtro HPF Mal Implementado (CRÍTICO)

**Problema**: El filtro estaba implementado como paso-bajo, no paso-alto.

**Causa**: Coeficientes incorrectos en la función `init_hpf_filter()`.

**Corrección**:
```c
// ANTES (INCORRECTO - era paso bajo):
hpf_b0 = (1.0f + cos_w) / (2.0f * norm);  // ❌ Paso bajo
hpf_b1 = -(1.0f + cos_w) / norm;          // ❌ Paso bajo  
hpf_b2 = hpf_b0;                          // ❌ Paso bajo

// DESPUÉS (CORRECTO - paso alto):
hpf_b0 = (1.0f - cos_w) / (2.0f * norm);  // ✅ Paso alto
hpf_b1 = -(1.0f - cos_w) / norm;          // ✅ Paso alto
hpf_b2 = (1.0f - cos_w) / (2.0f * norm);  // ✅ Paso alto
```

### 2. Filtro HPF de Primer Orden Incorrecto

**Problema**: Implementación matemática incorrecta.

**Corrección**:
```c
// ANTES (INCORRECTO):
float32_t alpha = 1.0f / (1.0f + 2.0f / w);

// DESPUÉS (CORRECTO):
float32_t RC = 1.0f / (2.0f * PI * fc);
float32_t dt = 1.0f / fs;
float32_t alpha = RC / (RC + dt);
```

### 3. Orden Incorrecto de Filtros

**Problema**: El filtro notch se aplicaba después del AGC, lo cual es incorrecto.

**Orden INCORRECTO**:
1. DC Filter
2. HPF
3. Pre-emphasis
4. AGC
5. Notch ❌ (muy tarde)

**Orden CORRECTO**:
1. DC Filter (eliminar offset)
2. HPF (eliminar bajas frecuencias)
3. **Notch (eliminar frecuencias específicas)** ✅
4. Pre-emphasis (modificar respuesta)
5. AGC (control ganancia - siempre último)

### 4. Inconsistencias en Configuración

**Problemas en `filter_config.h`**:
- HPF_CUTOFF_HZ decía 400.0f pero comentario decía 200 Hz
- ENABLE_NOTCH_FILTER estaba en 0 pero comentario decía "HABILITADO"

**Correcciones**:
```c
// Corregido:
#define HPF_CUTOFF_HZ       200.0f    // ✅ Coherente con comentario
#define ENABLE_NOTCH_FILTER 1         // ✅ Habilitado como se esperaba
```

### 5. Falta de Mensajes de Debug

**Agregado**: Mensajes de inicialización para verificar que los filtros se configuran correctamente.

```c
uart_len = sprintf(uart_tx_buffer, "HPF inicializado: fc=%.1f Hz, orden=%d\r\n", HPF_CUTOFF_HZ, HPF_ORDER);
uart_len = sprintf(uart_tx_buffer, "Filtro Notch inicializado: fc=%.1f Hz, Q=%.1f\r\n", NOTCH_FREQ_HZ, NOTCH_Q_FACTOR);
```

## Estado Actual Correcto

### Configuración Activa
- **HPF**: 200 Hz, 2º orden, Butterworth ✅
- **Notch**: 50 Hz, Q=30 ✅
- **Otros filtros**: Deshabilitados ✅

### Cadena de Procesamiento
```
Señal → DC → HPF(200Hz) → Notch(50Hz) → Pre-emphasis → AGC → Salida
        ❌   ✅          ✅           ❌            ❌
```

### Efectos Esperados
1. **HPF 200 Hz**: Eliminación fuerte de 0-200 Hz
   - A 50 Hz: ≈ -24 dB
   - A 100 Hz: ≈ -12 dB  
   - A 200 Hz: -3 dB
   - 200+ Hz: Sin afectación

2. **Notch 50 Hz**: Eliminación específica de interferencia de red
   - A 50 Hz: > -40 dB adicional
   - 49-51 Hz: Atenuación gradual
   - Resto: Sin efecto

### Resultado Final Esperado
- **0-50 Hz**: Eliminación total (HPF + Notch)
- **50-200 Hz**: Fuerte atenuación (solo HPF)
- **200+ Hz**: Espectro natural y limpio

## Pruebas Recomendadas

1. **Verificar inicialización**: Los mensajes UART deben mostrar:
   ```
   HPF inicializado: fc=200.0 Hz, orden=2
   Filtro Notch inicializado: fc=50.0 Hz, Q=30.0
   ```

2. **Verificar respuesta**: 
   - Debe haber eliminación dramática en 0-200 Hz
   - El pico de 50 Hz debe desaparecer completamente
   - Frecuencias > 200 Hz deben verse naturales

3. **Comparar**: Habilitar/deshabilitar filtros para ver diferencias

## Archivos Modificados

1. **`main.c`**:
   - ✅ Corregidos coeficientes HPF (paso alto)
   - ✅ Corregido orden de filtros
   - ✅ Agregados mensajes debug

2. **`filter_config.h`**:
   - ✅ Corregida frecuencia HPF (200 Hz)
   - ✅ Habilitado filtro Notch

3. **`realTimePlot.py`**:
   - ✅ Actualizada información mostrada

## Impacto de las Correcciones

**Antes**: El sistema no funcionaba como se esperaba porque:
- El "HPF" era en realidad un paso-bajo
- Los filtros se aplicaban en orden incorrecto
- Configuración inconsistente

**Después**: El sistema debe funcionar correctamente:
- HPF real eliminando bajas frecuencias
- Notch eliminando interferencia de 50 Hz  
- Cadena de procesamiento lógica y efectiva
