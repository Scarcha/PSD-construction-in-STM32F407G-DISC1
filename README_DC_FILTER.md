# PSD Construction en STM32F407G-DISC1

Este proyecto implementa estimación de **Densidad Espectral de Potencia (PSD)** en tiempo real usando un STM32F407G-DISC1 con diferentes métodos:
- **Welch** (con overlap del 50%)
- **Bartlett** (sin overlap)
- **Periodograma** (ventana única)

## Problema del Bin DC (Frecuencia 0 Hz) y Su Solución

### ¿Por qué el bin DC es muy alto?

El bin DC (bin 0, frecuencia 0 Hz) representa la **componente de corriente continua** de la señal y puede ser extremadamente alto debido a:

1. **Offset del ADC**: Los convertidores A/D tienen un offset que se suma a todas las muestras
2. **Bias del micrófono PDM**: Los micrófonos PDM pueden tener una componente DC
3. **Procesamiento de la señal**: Los filtros PDM2PCM pueden introducir offsets
4. **Acumulación de errores**: En operaciones de punto flotante

### Soluciones Implementadas

#### 1. Filtro Paso Alto Digital en STM32
```c
#define ENABLE_DC_FILTER 1
#define DC_FILTER_ALPHA 0.995f  // Factor del filtro paso alto

// Filtro paso alto de primer orden: y[n] = α * (y[n-1] + x[n] - x[n-1])
float32_t apply_dc_filter(float32_t input) {
    float32_t output = DC_FILTER_ALPHA * (dc_filter_prev_output + input - dc_filter_prev_input);
    dc_filter_prev_input = input;
    dc_filter_prev_output = output;
    return output;
}
```

**Características del filtro:**
- **α = 0.995**: Frecuencia de corte muy baja (~1.6 Hz a 32 kHz)
- **Tipo**: Filtro paso alto IIR de primer orden
- **Función**: Elimina componentes DC preservando las frecuencias de audio

#### 2. Opción de Visualización en Python
```python
EXCLUDE_DC_BIN = True  # Excluir bin DC de la visualización
```

**Configuraciones:**
- `True`: Muestra frecuencias desde ~31 Hz hasta 16 kHz
- `False`: Incluye el bin DC pero ajusta la escala automáticamente

### Análisis de Frecuencias

Con `FFT_SIZE = 1024` y `FS = 32000 Hz`:
- **Resolución frecuencial**: 32000/1024 = 31.25 Hz
- **Bin 0**: 0 Hz (DC)
- **Bin 1**: 31.25 Hz (primera frecuencia útil)
- **Bin 511**: 15968.75 Hz (máxima frecuencia)

## Características Implementadas

### Métodos PSD
1. **Welch**: Overlap 50%, ventana Hann, 8 promedios
2. **Bartlett**: Sin overlap, ventana rectangular, 8 promedios  
3. **Periodograma**: Ventana única (Hann/Hamming/Rectangular)

### Control Dinámico
- **Botón PA0**: Cambio de método en tiempo real
- **UART**: Notificaciones de cambio de método
- **Reset automático**: Variables y filtros al cambiar método

### Visualización
- **Tiempo real**: Actualización cada 10ms
- **Escalado automático**: Con/sin bin DC
- **Información del método**: Color y descripción dinámicos
- **Coordenadas del mouse**: Frecuencia y magnitud en tiempo real

## Uso

### 1. Compilar y Cargar en STM32
```bash
# En STM32CubeIDE
Build Project -> Run
```

### 2. Ejecutar Visualización
```bash
# Windows
run_realtime_plot.bat

# Manual
cd "Python Files"
python realTimePlot.py
```

### 3. Controles
- **Botón en STM32**: Cambiar método PSD (Welch → Bartlett → Periodograma → Welch)
- **Visualización**: El gráfico se actualiza automáticamente con nuevos colores y escalas

## Configuración Avanzada

### Ajustar Filtro DC
```c
// En main.c
#define DC_FILTER_ALPHA 0.995f  // Valor más alto = corte más bajo
```

### Cambiar Visualización DC
```python
# En realTimePlot.py
EXCLUDE_DC_BIN = False  # Para incluir bin DC
```

### Modificar Ventana del Periodograma
```c
// En main.c
#define PERIODOGRAM_WINDOW_TYPE 1  // 0: Rectangular, 1: Hann, 2: Hamming
```

## Diagnóstico de Problemas

### Si el bin DC sigue siendo muy alto:
1. Verificar `ENABLE_DC_FILTER = 1`
2. Reducir `DC_FILTER_ALPHA` (ej: 0.99)
3. Verificar calibración del micrófono
4. Revisar configuración PDM2PCM

### Si no se ven cambios de método:
1. Verificar conexión UART (COM3, 2M baud)
2. Verificar que el botón PA0 esté funcionando
3. Revisar mensajes en consola Python

## Hardware Requerido

- **STM32F407G-DISC1**
- **Micrófono PDM** (integrado en la Discovery)
- **Conexión USB** para UART (ST-Link)
- **PC con Python** para visualización

## Dependencias Python

```
pip install pyserial numpy pyqtgraph PyQt5
```

---

**Nota**: El filtro DC es esencial para obtener mediciones PSD precisas en sistemas de audio embebidos. Sin él, la componente DC puede dominar completamente el espectro y ocultar las características importantes de la señal de audio.
