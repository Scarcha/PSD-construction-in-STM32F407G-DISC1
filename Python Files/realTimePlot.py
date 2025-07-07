import serial
import time
import numpy as np
import pyqtgraph as pg
from PyQt5 import QtWidgets, QtCore, QtGui
import datetime
import os

# Importar los exportadores disponibles de pyqtgraph
try:
    from pyqtgraph.exporters import ImageExporter, SVGExporter
    EXPORTERS_AVAILABLE = ['png', 'svg']
    try:
        from pyqtgraph.exporters import PDFExporter
        EXPORTERS_AVAILABLE.append('pdf')
    except ImportError:
        PDFExporter = None
        print("⚠️  PDFExporter no disponible en esta versión de pyqtgraph")
except ImportError:
    print("⚠️  Exportadores no disponibles en esta versión de pyqtgraph")
    ImageExporter = None
    SVGExporter = None
    PDFExporter = None
    EXPORTERS_AVAILABLE = []

# Configuración del puerto serial
SERIAL_PORT = 'COM3'
BAUD_RATE = 2000000
FFT_SIZE = 1024
DB_FLOOR = -80.0
FS = 32000  # Frecuencia de muestreo en Hz

START_MARKER = b'SOF\n'
NUM_BINS = FFT_SIZE // 2

# Variables para tracking del método actual
current_method = "WELCH"  # Método por defecto

# Opción para excluir el bin DC (bin 0) de la visualización
EXCLUDE_DC_BIN = False  # Cambiar a True para excluir el bin DC

def save_plot_image(format='png'):
    """
    Guardar imagen del plot en formato raster (PNG) o vectorial (SVG, PDF).
    Args:
        format (str): El formato de archivo deseado ('png', 'svg', 'pdf').
    """
    try:
        # Verificar si el formato está disponible
        if format not in EXPORTERS_AVAILABLE:
            print(f"❌ Formato {format.upper()} no disponible en esta versión de pyqtgraph")
            print(f"Formatos disponibles: {', '.join(EXPORTERS_AVAILABLE).upper()}")
            return None
        
        # Crear directorio de imágenes si no existe
        img_dir = "imagenes_psd"
        if not os.path.exists(img_dir):
            os.makedirs(img_dir)
        
        # Generar nombre de archivo con timestamp
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{img_dir}/PSD_{current_method}_{timestamp}.{format}"
        
        # Guardar configuración original (solo relevante para PNG con fondo blanco)
        original_pen = curve.opts['pen']
        original_bg = win.getBackground()
        
        if format == 'png' and ImageExporter is not None:
            # Configurar para fondo blanco para la imagen PNG
            win.setBackground('white')
            # Cambiar color de la curva para que sea visible en fondo blanco
            colors_for_white_bg = {
                'WELCH': pg.mkPen(color='b', width=3),        # Azul más grueso
                'BARTLETT': pg.mkPen(color='r', width=3),     # Rojo más grueso
                'PERIODOGRAM': pg.mkPen(color='darkgreen', width=3)  # Verde oscuro más grueso
            }
            curve.setPen(colors_for_white_bg.get(current_method, pg.mkPen(color='k', width=3)))
            
            # Exportar como PNG (raster)
            exporter = ImageExporter(plot.plotItem)
            exporter.parameters()['width'] = 1200
            exporter.parameters()['height'] = 800
            exporter.export(filename)
            
            # Restaurar configuración original después de exportar PNG
            curve.setPen(original_pen)
            win.setBackground(original_bg)
            
        elif format == 'svg' and SVGExporter is not None:
            # Exportar como SVG (vectorial)
            exporter = SVGExporter(plot.plotItem)
            exporter.export(filename)
            
        elif format == 'pdf' and PDFExporter is not None:
            # Exportar como PDF (vectorial)
            exporter = PDFExporter(plot.plotItem)
            exporter.export(filename)
            
        else:
            print(f"❌ Exportador para formato {format.upper()} no disponible")
            return None

        print(f"✅ Gráfico guardado: {filename}")
        return filename
        
    except Exception as e:
        print(f"❌ Error al guardar gráfico como {format}: {e}")
        # Intentar restaurar configuración en caso de error, solo si se modificó para PNG
        if format == 'png':
            try:
                curve.setPen(original_pen)
                win.setBackground(original_bg)
            except:
                pass
        return None

def keyPressEvent(event):
    """Manejar eventos de teclado"""
    if event.key() == QtCore.Qt.Key_S:
        save_plot_image(format='png') # Guarda como PNG (con fondo blanco)
    elif event.key() == QtCore.Qt.Key_V:
        if 'svg' in EXPORTERS_AVAILABLE:
            save_plot_image(format='svg') # Guarda como SVG (vectorial)
        else:
            print("❌ Exportación SVG no disponible")
    elif event.key() == QtCore.Qt.Key_P:
        if 'pdf' in EXPORTERS_AVAILABLE:
            save_plot_image(format='pdf') # Guarda como PDF (vectorial)
        else:
            print("❌ Exportación PDF no disponible")
    elif event.key() == QtCore.Qt.Key_Q:
        app.quit()

# Configurar ventana
app = QtWidgets.QApplication([])
win = pg.GraphicsLayoutWidget(title="PSD en Tiempo Real - Métodos Dinámicos")
win.show()
win.setWindowTitle('PSD Viewer - Welch/Bartlett/Periodogram')

# Conectar eventos de teclado
win.keyPressEvent = keyPressEvent

# Configurar plot principal
plot = win.addPlot(title=f"Método Activo: {current_method}")
plot.setLabel('bottom', 'Frecuencia', units='Hz')
plot.setLabel('left', 'Potencia Estimada (dB)')
curve = plot.plot(pen='y', linewidth=2)
plot.setYRange(DB_FLOOR - 10, 100)

# Agregar grid para mejor visualización
plot.showGrid(x=True, y=True, alpha=0.3)

def mouseMoved(evt):
    # Función eliminada - no hay etiquetas de coordenadas
    pass

def update_method_info(method_name):
    """Actualizar información del método activo"""
    global current_method
    current_method = method_name
    
    # Actualizar título del plot
    dc_status = "sin DC" if EXCLUDE_DC_BIN else "con DC"
    plot.setTitle(f"Método Activo: {method_name} ({dc_status})")
    
    # Actualizar color de la curva según el método
    # Estos colores se usarán para la visualización en pantalla y exportaciones vectoriales
    colors = {
        'WELCH': 'b',        # Azul
        'BARTLETT': 'r',     # Rojo
        'PERIODOGRAM': 'darkgreen'   # Verde oscuro
    }
    curve.setPen(colors.get(method_name, 'w'), width=2)
    
    # Actualizar información del método
    method_descriptions = {
        'WELCH': 'Overlap 50%, Ventana Hann, 8 promedios',
        'BARTLETT': 'Sin overlap, Ventana rectangular, 8 promedios', 
        'PERIODOGRAM': 'Una ventana, Sin promediado, Ventana configurable'
    }
    
    # No hay etiquetas de información en el gráfico - información solo en consola
    print(f"Método cambiado a: {method_name}")
    print(f"Descripción: {method_descriptions.get(method_name, 'Desconocido')}")

# Eliminar la conexión del mouse ya que no hay etiquetas de coordenadas
# proxy = pg.SignalProxy(plot.scene().sigMouseMoved, rateLimit=60, slot=mouseMoved)

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    print(f"Puerto serial {SERIAL_PORT} abierto correctamente.")
    print("Esperando datos del STM32...")
    print("Presiona el botón en el STM32 para cambiar métodos de PSD")

    freqs = np.linspace(0, FS / 2, NUM_BINS)
    buffer = []
    
    # Inicializar información del método
    update_method_info(current_method)

    def update():
        global buffer
        while ser.in_waiting > 0:
            line = ser.readline().decode('ascii', errors='ignore').strip()
            
            # Verificar mensajes de cambio de método
            if line.startswith('INITIAL_METHOD:'):
                method_name = line.split(':')[1]
                update_method_info(method_name)
                continue
            elif line.startswith('METHOD_CHANGED:'):
                method_name = line.split(':')[1]
                update_method_info(method_name)
                continue
            elif line == 'SOF':
                buffer = []
                continue
            
            # Procesar datos de PSD
            try:
                value = float(line)
                buffer.append(value)
                if len(buffer) == NUM_BINS:
                    data_values = np.array(buffer)
                    
                    # ANÁLISIS DEL BIN DC (bin 0)
                    dc_power = data_values[0]
                    
                    if EXCLUDE_DC_BIN:
                        # Excluir el bin DC de la visualización
                        display_data = data_values[1:]  # Empezar desde bin 1
                        display_freqs = freqs[1:]
                        print(f"Visualización sin DC: rango {display_freqs[0]:.1f} - {display_freqs[-1]:.1f} Hz")
                        
                        # Actualizar datos sin incluir DC
                        curve.setData(display_freqs, display_data)
                        
                        # Ajustar escala automáticamente sin DC
                        if len(display_data) > 0:
                            max_val = np.max(display_data)
                            min_val = max(np.min(display_data), DB_FLOOR)
                            plot.setYRange(min_val - 5, max_val + 10)
                        
                    else:
                        # Mostrar todo incluyendo DC
                        curve.setData(freqs, data_values)
                        
                        # Para mejor visualización, ajustar escala excluyendo DC si es muy alto
                        valid_data = data_values[3:]  # Excluir los primeros 3 bins para evaluar
                        if len(valid_data) > 0:
                            max_val = np.max(valid_data)
                            min_val = max(np.min(valid_data), DB_FLOOR)
                            
                            # Si el DC es mucho mayor que el resto, ajustar escala
                            if dc_power > (max_val + 20):  # DC 20dB mayor que el máximo
                                plot.setYRange(min_val - 5, max_val + 15)
                                print(f"Escala ajustada: DC muy alto ({dc_power:.1f} dB) vs señal útil ({max_val:.1f} dB)")
                            else:
                                # Incluir DC en la escala si no es extremo
                                plot.setYRange(min(min_val, dc_power) - 5, max(max_val, dc_power) + 10)
                        
                    buffer = []
            except ValueError:
                # Ignorar líneas que no son números
                continue

    timer = QtCore.QTimer()
    timer.timeout.connect(update)
    timer.start(10)  # Actualizar cada 10ms para mejor responsividad

    print("\n=== CONTROLES ===")
    print("- Presiona el botón del STM32 para cambiar métodos")
    if 'png' in EXPORTERS_AVAILABLE:
        print("- Presiona 'S' para guardar imagen (PNG, fondo blanco)")
    if 'svg' in EXPORTERS_AVAILABLE:
        print("- Presiona 'V' para guardar gráfico (SVG, vectorial)")
    if 'pdf' in EXPORTERS_AVAILABLE:
        print("- Presiona 'P' para guardar gráfico (PDF, vectorial)")
    if not EXPORTERS_AVAILABLE:
        print("- ⚠️  No hay exportadores disponibles en esta versión de pyqtgraph")
    print("- Presiona 'Q' para salir")
    print(f"\n=== EXPORTADORES DISPONIBLES: {', '.join(EXPORTERS_AVAILABLE).upper()} ===")
    print("\n=== CONFIGURACIÓN ACTUAL ===")
    print(f"- Visualización bin DC: {'EXCLUIDA' if EXCLUDE_DC_BIN else 'INCLUIDA'}")
    print("- Procesamiento: HPF 200Hz + Notch 50Hz")
    print("- Métodos disponibles: Welch, Bartlett, Periodogram")
    print("=============================\n")

    app.exec_()

except serial.SerialException as e:
    print(f"Error de puerto serial: {e}")
    print("Verifica que:")
    print("- El puerto COM3 sea correcto")
    print("- El STM32 esté conectado")
    print("- No haya otros programas usando el puerto")
except KeyboardInterrupt:
    print("\nPrograma terminado por el usuario.")
finally:
    if 'ser' in locals() and ser.isOpen():
        ser.close()
        print("Puerto serial cerrado.")