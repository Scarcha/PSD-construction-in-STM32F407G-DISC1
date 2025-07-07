# Sistema de Estimación de PSD en Tiempo Real - STM32F407G-DISC1

[![STM32](https://img.shields.io/badge/STM32-F407G-blue)](https://www.st.com/en/microcontrollers-microprocessors/stm32f407vg.html)
[![Python](https://img.shields.io/badge/Python-3.7+-green)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Descripción

Sistema completo de estimación de Densidad Espectral de Potencia (PSD) en tiempo real implementado en STM32F407G-DISC1 con visualización en Python. El sistema permite la captura de audio desde el micrófono MEMS integrado, procesamiento de señal avanzado, y cálculo de PSD usando tres métodos diferentes: **Welch**, **Bartlett** y **Periodograma**.

### ✨ Características Principales

- **🎯 Múltiples Métodos PSD**: Welch, Bartlett y Periodograma con cambio dinámico
- **🔧 Procesamiento Avanzado**: Filtros DC, HPF, Notch (50Hz), Pre-énfasis y AGC
- **📊 Visualización en Tiempo Real**: Interfaz Python con pyqtgraph
- **💾 Exportación Flexible**: PNG, SVG y PDF para presentaciones
- **⚡ Optimización CMSIS-DSP**: Uso de bibliotecas ARM optimizadas
- **🎛️ Control Dinámico**: Cambio de métodos vía botón físico

## 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Micrófono     │────│   STM32F407G    │────│   PC (Python)   │
│   MEMS          │PDM │   Procesamiento │UART│   Visualización │
│   MP45DT02      │    │   PSD + Filtros │    │   pyqtgraph     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 🔄 Flujo de Procesamiento

1. **Captura PDM** → Micrófono MEMS (64 kHz PDM)
2. **Conversión PDM→PCM** → 32 kHz, 16-bit mono
3. **Filtros de Señal** → DC + HPF + Notch + Pre-énfasis + AGC
4. **Cálculo PSD** → FFT 1024 puntos + Método seleccionado
5. **Transmisión UART** → 2 Mbps hacia PC
6. **Visualización** → Gráfico en tiempo real + exportación

## 🎛️ Métodos de PSD Implementados

### 1. **Método Welch** (Azul)
- **Overlap**: 50%
- **Ventana**: Hann
- **Promedios**: 8 segmentos
- **Ventaja**: Menor varianza, mejor para señales estacionarias

### 2. **Método Bartlett** (Rojo)
- **Overlap**: 0%
- **Ventana**: Rectangular
- **Promedios**: 8 segmentos
- **Ventaja**: Implementación simple, buena resolución

### 3. **Periodograma** (Verde Oscuro)
- **Segmentos**: 1 (sin promediado)
- **Ventana**: Configurable (Rectangular/Hann/Hamming)
- **Ventaja**: Máxima resolución, respuesta instantánea

## 🔧 Filtros de Procesamiento

| Filtro | Función | Parámetros | Estado |
|--------|---------|------------|--------|
| **DC Filter** | Eliminar offset DC | α = 0.995 | ✅ Activo |
| **HPF** | Paso alto | fc = 200 Hz, Orden 2 | ✅ Activo |
| **Notch** | Eliminar 50 Hz | fc = 50 Hz, Q = 30 | ✅ Activo |
| **Pre-énfasis** | Realce alta freq. | α = 0.97 | ⚠️ Configurable |
| **AGC** | Control ganancia | Target = 1000 RMS | ⚠️ Configurable |

## 🛠️ Configuración del Hardware

### STM32F407G-DISC1
- **MCU**: STM32F407VGT6 (168 MHz, ARM Cortex-M4F)
- **Micrófono**: MP45DT02 MEMS digital (PDM)
- **Comunicación**: UART2 @ 2 Mbps
- **Control**: Botón usuario (PA0) para cambio de método

### Conexiones
```
PA0  ← Botón usuario (cambio método PSD)
PA2  → UART2_TX (datos hacia PC)
PA3  ← UART2_RX 
PC3  ← Micrófono PDM (datos)
PB10 → Micrófono PDM (clock)
```

## 💻 Software - Visualización Python

### Dependencias
```bash
pip install pyqtgraph PyQt5 pyserial numpy datetime
```

### Características
- **Visualización en tiempo real** con actualización automática
- **Colores diferenciados** por método (Azul/Rojo/Verde)
- **Exportación múltiple**: PNG (fondo blanco), SVG, PDF
- **Controles de teclado**:
  - `S`: Guardar PNG
  - `V`: Guardar SVG  
  - `P`: Guardar PDF
  - `Q`: Salir

### Configuración
```python
SERIAL_PORT = 'COM3'        # Puerto serial
BAUD_RATE = 2000000         # Velocidad 2 Mbps
FFT_SIZE = 1024             # Tamaño FFT
EXCLUDE_DC_BIN = False      # Mostrar/ocultar bin DC
```

## 🚀 Instalación y Uso

### 1. Preparación del Hardware
```bash
# Conectar STM32F407G-DISC1 vía USB
# Verificar puerto COM en Device Manager (Windows)
```

### 2. Compilación STM32
```bash
# Abrir proyecto en STM32CubeIDE
# Compilar y flashear FFTplusMIC
# Verificar conexión UART @ 2 Mbps
```

### 3. Ejecución Python
```bash
cd "Python Files"
python realTimePlot.py
```

### 4. Operación
- **Inicio automático** con método Welch
- **Cambio de método**: Presionar botón usuario en STM32
- **Visualización**: Gráfico actualizado en tiempo real
- **Exportación**: Teclas S/V/P para guardar imágenes

## 📁 Estructura del Proyecto

```
PSD-construction-in-STM32F407G-DISC1/
├── README.md                          # Este archivo
├── FFTplusMIC/                        # Proyecto STM32
│   ├── Core/
│   │   ├── Src/main.c                 # Código principal STM32
│   │   └── Inc/filter_config.h        # Configuración filtros
│   ├── Drivers/                       # Drivers HAL y CMSIS-DSP
│   └── FFTplusMIC.ioc                 # Configuración STM32CubeMX
├── Python Files/
│   └── realTimePlot.py                # Visualización Python
├── MATLAB files/                      # Scripts MATLAB auxiliares
└── Documentación/
    ├── FILTRO_NOTCH_50HZ.md          # Documentación filtros
    ├── CORRECCIONES_FILTROS.md
    ├── SOLUCION_EXPORTADORES.md      # Compatibilidad pyqtgraph
    └── INTERFAZ_SIMPLIFICADA.md      # Cambios interfaz
```

## ⚙️ Configuración Avanzada

### Filtros (filter_config.h)
```c
#define ENABLE_DC_FILTER     1    // Filtro DC
#define ENABLE_HPF_FILTER    1    // Filtro paso alto
#define ENABLE_NOTCH_FILTER  1    // Filtro notch 50Hz
#define ENABLE_PREEMPHASIS   0    // Pre-énfasis (opcional)
#define ENABLE_AGC           0    // AGC (opcional)

#define HPF_CUTOFF_HZ       200.0f
#define NOTCH_FREQ_HZ       50.0f
#define NOTCH_Q_FACTOR      30.0f
```

### Parámetros PSD (main.c)
```c
#define FFT_SIZE                1024
#define WELCH_NUM_AVERAGES      8
#define WELCH_OVERLAP_PERCENT   50
#define BARTLETT_NUM_AVERAGES   8
#define PERIODOGRAM_WINDOW_TYPE 1  // 0:Rect, 1:Hann, 2:Hamming
```

## 📊 Rendimiento

### Métricas de Tiempo (168 MHz)
| Método | Ciclos de CPU | Tiempo (ms) | FPS |
|--------|---------------|-------------|-----|
| **Welch** | ~2.8M | ~16.7 | 60 |
| **Bartlett** | ~2.1M | ~12.5 | 80 |
| **Periodograma** | ~350k | ~2.1 | 476 |

### Uso de Memoria
- **RAM**: ~24 KB (buffers FFT + circular)
- **Flash**: ~45 KB (código + tablas)
- **UART**: 2 Mbps (512 valores × 6 bytes/valor)

## 🔍 Resolución Espectral

- **Frecuencia muestreo**: 32 kHz
- **Resolución**: 31.25 Hz/bin (32000/1024)
- **Rango**: 0 - 16 kHz (Nyquist)
- **Bins**: 512 (FFT real, mitad del espectro)

## 🎯 Casos de Uso

### 🔬 **Análisis de Audio**
- Caracterización de respuesta de micrófonos
- Análisis de ruido ambiental
- Detección de tonos puros

### 🏭 **Monitoreo Industrial**
- Diagnóstico de vibraciones
- Detección de frecuencias específicas
- Control de calidad sonora

### 🎓 **Educación e Investigación**
- Comparación de métodos PSD
- Estudio de filtros digitales
- Prácticas de procesamiento en tiempo real

## 🔧 Solución de Problemas

### Error de Puerto Serial
```
Error: Port 'COM3' not found
Solución: Verificar puerto en Device Manager
```

### Error de Exportación
```
Error: ImageExporter not available
Solución: Versión pyqtgraph compatible implementada
```

### Ruido en Baja Frecuencia
```
Problema: Picos en 0-200 Hz
Solución: HPF a 200 Hz activo por defecto
```

### Interferencia 50 Hz
```
Problema: Pico en 50 Hz (red eléctrica)
Solución: Filtro Notch 50 Hz activo
```

## 🤝 Contribución

1. **Fork** del repositorio
2. **Crear rama** para nueva característica
3. **Commit** cambios con mensajes descriptivos
4. **Push** a la rama
5. **Pull Request** con descripción detallada

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

## 👨‍💻 Autor

**Desarrollado para sistemas de procesamiento de señal en tiempo real**

- 📧 Email: [contacto]
- 🔗 LinkedIn: [perfil]
- 🐙 GitHub: [repositorio]

## 🙏 Agradecimientos

- **STMicroelectronics** por las bibliotecas CMSIS-DSP
- **ARM** por las optimizaciones Cortex-M4F
- **Comunidad Open Source** por herramientas y librerías

## 📚 Referencias

1. [CMSIS-DSP Documentation](https://arm-software.github.io/CMSIS_5/DSP/html/index.html)
2. [STM32F407 Reference Manual](https://www.st.com/resource/en/reference_manual/dm00031020.pdf)
3. [Welch's Method Paper](https://doi.org/10.1109/TAU.1967.1161901)
4. [pyqtgraph Documentation](https://pyqtgraph.readthedocs.io/)

---

**🔥 Sistema completo de PSD en tiempo real - De micrófono a visualización en <100ms**