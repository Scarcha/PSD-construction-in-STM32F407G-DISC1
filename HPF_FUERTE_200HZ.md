# Filtro Paso Alto Fuerte (200 Hz) - Eliminación Agresiva de Bajas Frecuencias

## Configuración Actual

### Filtro HPF
- **Frecuencia de corte**: 200 Hz
- **Orden**: 2 (Butterworth)
- **Atenuación**: -40 dB/década
- **Efecto**: Elimina completamente contenido < 200 Hz

### Filtro Notch (combinado)
- **Frecuencia**: 50 Hz
- **Factor Q**: 30
- **Efecto**: Elimina interferencia de red (aunque ya estará atenuada por HPF)

## Efectos Esperados

### Eliminación Completa de Bajas Frecuencias
Con fc = 200 Hz y orden 2:
- **A 200 Hz**: -3 dB (frecuencia de corte)
- **A 100 Hz**: ≈ -12 dB
- **A 50 Hz**: ≈ -24 dB
- **A 25 Hz**: ≈ -36 dB
- **A 10 Hz**: ≈ -52 dB
- **DC (0 Hz)**: ≈ -∞ dB

### Banda de Análisis Resultante
- **Banda útil**: 200 Hz - 16 kHz
- **Resolución freq**: 31.25 Hz por bin
- **Bins útiles**: ~6-512 (de 1024 total)
- **Bins eliminados**: 0-6 (0-200 Hz)

## Comparación de Configuraciones

| Frecuencia | Sin Filtro | HPF 25 Hz | HPF 200 Hz (ACTUAL) |
|------------|------------|-----------|---------------------|
| DC - 10 Hz | Natural | -20 dB | -52 dB |
| 10 - 50 Hz | Natural | -6 dB | -24 dB |
| 50 - 100 Hz | Natural | -1 dB | -12 dB |
| 100 - 200 Hz | Natural | -0.2 dB | -3 dB |
| 200+ Hz | Natural | Natural | Natural |

## Ventajas del Filtro HPF Fuerte

1. **Eliminación Total**: Remueve completamente el problema de 0-200 Hz
2. **Espectro Limpio**: Enfoque en frecuencias de interés real (voz, música)
3. **Mejor Resolución**: Sin bins "desperdiciados" en bajas frecuencias problemáticas
4. **Diagnóstico Claro**: Permite ver claramente qué pasa en frecuencias útiles

## Posibles Desventajas

1. **Pérdida de Información**: Se elimina contenido potencialmente útil 100-200 Hz
2. **Artefactos de Filtrado**: Posible ringing o overshooting cerca de 200 Hz
3. **Transiente**: Filtro IIR puede introducir delay de grupo
4. **Sobre-filtrado**: Podría ser más agresivo de lo necesario

## Implementación del Filtro

### Cálculo de Coeficientes (Butterworth 2º orden)
```c
// Para fc = 200 Hz, fs = 32000 Hz
float32_t wc = 2π * 200 / 32000 = 0.0393
float32_t alpha = sin(wc) / sqrt(2)  // Q = 0.707 para Butterworth

// Coeficientes del filtro
b0 = (1 + cos(wc)) / 2
b1 = -(1 + cos(wc))
b2 = (1 + cos(wc)) / 2
a1 = -2 * cos(wc)
a2 = (1 - alpha)
```

### Respuesta en Frecuencia
- **Fase**: Lineal en banda de paso
- **Transición**: Suave pero rápida
- **Rizado**: Mínimo (Butterworth)

## Análisis de Resultados Esperados

### Antes del HPF (problemático)
```
0-50 Hz:    ████████████████████ 60 dB (PROBLEMA)
50-100 Hz:  ██████████ 40 dB
100-200 Hz: ██████ 30 dB
200+ Hz:    ███ 20 dB (señal útil)
```

### Después del HPF 200 Hz (esperado)
```
0-50 Hz:    (eliminado)
50-100 Hz:  (eliminado)
100-200 Hz: █ 5-10 dB (atenuado)
200+ Hz:    ███ 20 dB (ENFOQUE AQUÍ)
```

## Monitoreo y Evaluación

### Puntos de Control
1. **Verificar eliminación**: 0-200 Hz debe estar muy atenuado
2. **Transición suave**: Alrededor de 200 Hz sin artifacts
3. **Preservación**: 200+ Hz debe mantenerse natural
4. **Mejora S/N**: Relación señal/ruido general

### Métricas de Éxito
- Potencia en 0-200 Hz < -40 dB
- Sin picos artificiales en 200-300 Hz
- Espectro limpio y bien definido en frecuencias altas
- Eliminación del problema de concentración en bajas frecuencias

## Casos de Uso Ideal

Este filtro es ideal cuando:
- El problema está claramente en bajas frecuencias (0-200 Hz)
- Se quiere analizar principalmente voz/música (300+ Hz)
- Las frecuencias 100-200 Hz no son críticas
- Se prefiere un espectro limpio vs. completitud

## Próximos Experimentos

1. **Evaluar efectividad**: Comparar con configuración anterior
2. **Ajustar frecuencia**: Probar 100 Hz, 150 Hz, 300 Hz
3. **Cambiar orden**: Probar orden 1 (más suave) vs orden 3 (más agresivo)
4. **Combinaciones**: HPF + otros filtros para optimización fina

## Estado del Sistema

- ✅ HPF 200 Hz habilitado (2º orden)
- ✅ Filtro Notch 50 Hz habilitado (redundante pero activo)
- ✅ Otros filtros deshabilitados
- ✅ Configuración agresiva para eliminar problema de bajas frecuencias
- ✅ Enfoque en análisis de frecuencias útiles (200+ Hz)
