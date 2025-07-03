import serial
import time
import numpy as np
import pyqtgraph as pg
from PyQt5 import QtWidgets, QtCore

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

# Configurar ventana
app = QtWidgets.QApplication([])
win = pg.GraphicsLayoutWidget(title="PSD en Tiempo Real - Métodos Dinámicos")
win.show()
win.setWindowTitle('PSD Viewer - Welch/Bartlett/Periodogram')

# Configurar plot principal
plot = win.addPlot(title=f"Método Activo: {current_method}")
plot.setLabel('bottom', 'Frecuencia', units='Hz')
plot.setLabel('left', 'Potencia Estimada (dB)')
curve = plot.plot(pen='y', linewidth=2)
plot.setYRange(DB_FLOOR - 10, 100)

# Agregar grid para mejor visualización
plot.showGrid(x=True, y=True, alpha=0.3)

# Configurar leyenda de información
info_label = pg.LabelItem(justify='left')
win.addItem(info_label, row=1, col=0)

coord_label = pg.LabelItem(justify='right')
win.addItem(coord_label, row=2, col=0)

def mouseMoved(evt):
    pos = evt[0]
    if plot.sceneBoundingRect().contains(pos):
        mouse_point = plot.vb.mapSceneToView(pos)
        x = mouse_point.x()
        y = mouse_point.y()
        coord_label.setText(f"<span style='font-size: 12pt'>f = {x:.1f} Hz,&nbsp;&nbsp; Mag = {y:.1f} dB</span>")

def update_method_info(method_name):
    """Actualizar información del método activo"""
    global current_method
    current_method = method_name
    
    # Actualizar título del plot
    dc_status = "sin DC" if EXCLUDE_DC_BIN else "con DC"
    plot.setTitle(f"Método Activo: {method_name} ({dc_status})")
    
    # Actualizar color de la curva según el método
    colors = {
        'WELCH': 'y',        # Amarillo
        'BARTLETT': 'c',     # Cyan
        'PERIODOGRAM': 'm'   # Magenta
    }
    curve.setPen(colors.get(method_name, 'w'), width=2)
    
    # Actualizar información del método
    method_descriptions = {
        'WELCH': 'Overlap 50%, Ventana Hann, 8 promedios',
        'BARTLETT': 'Sin overlap, Ventana rectangular, 8 promedios', 
        'PERIODOGRAM': 'Una ventana, Sin promediado, Ventana configurable'
    }
    
    info_text = f"<span style='font-size: 12pt; color: white;'>Método: {method_name}<br>"
    info_text += f"Descripción: {method_descriptions.get(method_name, 'Desconocido')}<br>"
    info_text += f"<br><b>Filtros STM32 (HPF + Notch CORREGIDOS):</b><br>"
    info_text += f"• Filtro DC: DESHABILITADO<br>"
    info_text += f"• <b>Filtro HPF: HABILITADO (200 Hz, 2º orden)</b><br>"
    info_text += f"• Pre-énfasis: DESHABILITADO<br>"
    info_text += f"• AGC: DESHABILITADO<br>"
    info_text += f"• <b>Filtro Notch 50 Hz: HABILITADO (Q=30)</b><br>"
    info_text += f"<br><b>Estado:</b> Filtros corregidos y operativos<br>"
    info_text += f"Visualización DC: {'Excluida' if EXCLUDE_DC_BIN else 'INCLUIDA'}</span>"
    info_label.setText(info_text)
    
    print(f"Método cambiado a: {method_name}")

proxy = pg.SignalProxy(plot.scene().sigMouseMoved, rateLimit=60, slot=mouseMoved)

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
                    print(f"Potencia DC (bin 0): {dc_power:.2f} dB")
                    
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
    print("- Mueve el mouse sobre el gráfico para ver coordenadas")
    print("- Cierra la ventana para salir")
    print("\n=== CONFIGURACIÓN ACTUAL (FILTROS CORREGIDOS) ===")
    print(f"- Visualización bin DC: {'EXCLUIDA' if EXCLUDE_DC_BIN else 'INCLUIDA (VISIBLE)'}")
    print("- FILTROS STM32 (CORREGIDOS):")
    print("  * Filtro DC: DESHABILITADO")
    print("  * HPF CORREGIDO: HABILITADO (fc=200 Hz, 2º orden, -40 dB/década)") 
    print("  * Pre-énfasis: DESHABILITADO")
    print("  * AGC: DESHABILITADO")
    print("  * FILTRO NOTCH CORREGIDO: HABILITADO (fc=50 Hz, Q=30)")
    print("- OBJETIVO:")
    print("  * HPF: Eliminar frecuencias < 200 Hz")
    print("  * NOTCH: Eliminar interferencia de red (50 Hz)")
    print("  * Filtros con implementación matemática correcta")
    print("  * Configuración coherente y estable")
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
    print("¡Hasta luego!")
