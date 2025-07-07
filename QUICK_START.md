# 🚀 Guía de Inicio Rápido

## ⚡ Configuración en 5 minutos

### 1. **Preparar Hardware** (2 min)
```bash
# Conectar STM32F407G-DISC1 vía USB
# Verificar LED verde encendido
# Anotar puerto COM en Device Manager (ej: COM3)
```

### 2. **Flashear STM32** (2 min)
```bash
# Abrir STM32CubeIDE
# Importar proyecto: FFTplusMIC
# Build + Flash al dispositivo
```

### 3. **Instalar Python** (1 min)
```bash
cd "Python Files"
pip install -r ../requirements.txt
```

### 4. **¡Ejecutar!** ⚡
```bash
python realTimePlot.py
```

## 🎯 Primera Prueba

1. **Verificar comunicación**: Debes ver datos llegando en consola
2. **Cambiar método**: Presiona botón azul en STM32 
3. **Guardar imagen**: Presiona 'S' para exportar PNG
4. **Hacer ruido**: Habla/silba para ver cambios en tiempo real

## 🔧 Configuración Rápida

### Cambiar Puerto Serial
```python
# En realTimePlot.py línea 24:
SERIAL_PORT = 'COM3'  # ← Cambiar aquí
```

### Ocultar Bin DC
```python
# En realTimePlot.py línea 35:
EXCLUDE_DC_BIN = True  # ← True para ocultar
```

### Cambiar Filtros
```c
// En filter_config.h:
#define ENABLE_HPF_FILTER    1    // ← 0 para desactivar
#define HPF_CUTOFF_HZ       200.0f // ← Cambiar frecuencia
```

## 🆘 Problemas Comunes

| Problema | Solución Rápida |
|----------|----------------|
| No hay datos | Verificar puerto COM y velocidad |
| Imagen negra | Presionar 'S' con datos activos |
| Mucho ruido | Activar filtros HPF y Notch |
| Error Python | Instalar: `pip install pyqtgraph PyQt5` |

## 🎨 Métodos Disponibles

- **Azul** = Welch (recomendado para análisis general)
- **Rojo** = Bartlett (bueno para señales transitorias)  
- **Verde** = Periodograma (máxima resolución)

## 🔥 ¡Ya está listo!

✅ **Hardware configurado**  
✅ **Software funcionando**  
✅ **Visualización en tiempo real**  
✅ **Exportación de imágenes**

**→ Siguiente paso**: Leer [README.md](README.md) completo para funciones avanzadas
