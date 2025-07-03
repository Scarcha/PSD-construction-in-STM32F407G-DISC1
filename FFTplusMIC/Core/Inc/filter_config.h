#ifndef FILTER_CONFIG_H
#define FILTER_CONFIG_H

// ============================================================================
// CONFIGURACIÓN DE FILTROS PARA MEJORA DEL ESPECTRO
// ============================================================================

// 1. FILTRO DC (Elimina offset constante)
#define ENABLE_DC_FILTER    0         // DESHABILITADO - para ver espectro natural
#define DC_FILTER_ALPHA     0.999f    // Más suave - corte más bajo (~0.5 Hz)

// 2. FILTRO PASO ALTO (Elimina ruido de baja frecuencia)
#define ENABLE_HPF_FILTER   1         // HABILITADO - filtro fuerte para eliminar bajas frecuencias
#define HPF_CUTOFF_HZ       2000.0f    // FUERTE - elimina todo por debajo de 200 Hz
#define HPF_ORDER           2         // Orden 2 para mayor atenuación (-40 dB/década)

// 3. PRE-ÉNFASIS (Compensa ruido 1/f)
#define ENABLE_PREEMPHASIS  0         // DESHABILITADO - evitar alteraciones
#define PREEMPHASIS_ALPHA   0.95f     // Más suave cuando esté habilitado

// 4. CONTROL AUTOMÁTICO DE GANANCIA (Normaliza niveles)
#define ENABLE_AGC          0         // DESHABILITADO - evitar normalización artificial
#define AGC_TARGET_RMS      8192.0f   // RMS objetivo
#define AGC_ALPHA           0.995f    // Más suave

// 5. FILTRO NOTCH 50 Hz (Elimina interferencia de red eléctrica)
#define ENABLE_NOTCH_FILTER 0         // HABILITADO - para eliminar interferencia a 50 Hz
#define NOTCH_FREQ_HZ       50.0f     // Frecuencia de corte (50 Hz para red europea)
#define NOTCH_Q_FACTOR      30.0f     // Factor Q - ancho de banda estrecho

#endif // FILTER_CONFIG_H
