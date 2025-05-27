% -------------------------------------------------------------------------
% MATLAB: Simulación del Procesamiento Welch del STM32
% -------------------------------------------------------------------------
clear; clc; close all;

% --- Parámetros de Configuración (Iguales al STM32) ---
PCM_SAMPLING_FREQ = 32000;      % Hz
FFT_SIZE = 1024;                % N
SINE_FREQ = 3000;                % Hz (Bin exacto: 500 / (32000/1024) = 16)
SINE_AMPLITUDE = 10000;         % Amplitud comparable a int16_t
WELCH_NUM_AVERAGES = 8;         % K_avg

DB_FLOOR = -80.0;
EPSILON_POWER = 1e-18; % Epsilon para potencia (magnitud^2)

NUM_BINS_OUTPUT = FFT_SIZE / 2; % Número de bins de potencia que calcula el STM32

% --- 1. Generar Ventana Hann (como en STM32) ---
hann_window = zeros(FFT_SIZE, 1);
for i = 0:FFT_SIZE-1
    hann_window(i+1) = 0.5 * (1.0 - cos(2.0 * pi * i / (FFT_SIZE - 1.0)));
end
% Alternativa de MATLAB: hann_window = hann(FFT_SIZE, 'periodic');

% --- 2. Inicializar Acumulador de Potencia ---
accumulated_psd_matlab = zeros(NUM_BINS_OUTPUT, 1); % Vector columna

% --- 3. Simular el Procesamiento de WELCH_NUM_AVERAGES Segmentos ---
for segment_idx = 1:WELCH_NUM_AVERAGES
    
    % a. Generar Segmento de Señal Sinusoidal
    % Para simular un flujo continuo, podríamos avanzar la fase,
    % pero para una sinusoide pura y promediado de potencia, la fase inicial no es crítica.
    t_segment = (0:FFT_SIZE-1)' / PCM_SAMPLING_FREQ; % Vector de tiempo para el segmento
    current_segment_pcm = SINE_AMPLITUDE * sin(2 * pi * SINE_FREQ * t_segment);
    
    % b. Aplicar Ventana Hann (como en STM32)
    % STM32: fft_input_f32[i] = (float32_t)pcm_mono_fft_input_buffer[i] * hann_window[i];
    % Aquí current_segment_pcm ya es tipo double (equivalente a float32_t para este propósito)
    windowed_segment = current_segment_pcm .* hann_window;
    
    % c. Calcular RFFT (Simulando la salida empaquetada de CMSIS para el cálculo de potencia)
    % MATLAB fft() devuelve un espectro complejo de doble cara.
    X_matlab_sided = fft(windowed_segment, FFT_SIZE);
    
    % Simular los componentes que usa el STM32 para calcular la potencia:
    % R(0)_cmsis_equiv = X_matlab_sided(1); % Componente DC (MATLAB es 1-indexado)
    % R(N/2)_cmsis_equiv = X_matlab_sided(FFT_SIZE/2 + 1); % Componente Nyquist
    % Para k=1..N/2-1: Re_k_cmsis_equiv = real(X_matlab_sided(k+1)), Im_k_cmsis_equiv = imag(X_matlab_sided(k+1))

    % d. Calcular Espectro de Potencia del Segmento (como en STM32)
    % El STM32 calcula N/2 potencias.
    
    % Bin 0 (DC) en STM32 corresponde a X_matlab_sided(1)
    % La "magnitud" que usa STM32 para DC es directamente el valor real de R(0) de CMSIS RFFT.
    % Si CMSIS RFFT escala la salida por N, y MATLAB no, necesitamos escalar para comparar.
    % PERO, para este script, queremos replicar el *cálculo del STM32* sobre *su* salida FFT.
    % Si el STM32 usa fft_output_f32[0] (que es R(0) de CMSIS),
    % entonces en MATLAB, el equivalente sería real(X_matlab_sided(1)).
    % La potencia sería (real(X_matlab_sided(1)))^2.
    % Nota: abs(X(1))^2 es lo mismo que real(X(1))^2 ya que X(1) es real para entrada real.
    
    power_spectrum_segment = zeros(NUM_BINS_OUTPUT, 1);
    
    % Potencia DC (Bin 0 en el array de salida del STM32)
    % El fft_output_f32[0] del STM32 es R(0). Potencia = R(0)^2
    power_spectrum_segment(1) = abs(X_matlab_sided(1))^2; % Corresponde a (fft_output_f32[0])^2
                                                         % abs() para manejar cualquier residuo complejo numérico
                                                         % X_matlab_sided(1) es real para entrada real.
                                                         
    % Potencia para Bins k = 1 a NUM_BINS_OUTPUT - 1 (corresponde a k=1 a FFT_SIZE/2 - 1 en STM32)
    % STM32: (fft_output_f32[2*k])^2 + (fft_output_f32[2*k+1])^2
    % Esto es |X_k|^2 para el k-ésimo bin complejo de la RFFT.
    % En MATLAB, para el bin k (k=1..N/2-1), X_matlab_sided(k+1) es el componente complejo.
    % Su potencia es abs(X_matlab_sided(k+1))^2.
    for k_stm = 1:(NUM_BINS_OUTPUT - 1) % k_stm es el índice del array de salida de potencia del STM32 (después de DC)
        matlab_fft_index = k_stm + 1; % Índice correspondiente en X_matlab_sided
        power_spectrum_segment(k_stm + 1) = abs(X_matlab_sided(matlab_fft_index))^2;
    end
    
    % ESCALADO IMPORTANTE PARA COMPARAR CON CMSIS-DSP:
    % La magnitud de salida de arm_rfft_fast_f32 es N veces la de una DFT estándar
    % (o N/2 veces la amplitud de la sinusoide para el bin del pico).
    % La salida de fft() de MATLAB, la magnitud es N/2 veces la amplitud de la sinusoide.
    % Si STM32 usa (float)int16_val, y MATLAB usa SINE_AMPLITUDE directamente,
    % y ambos FFTs (CMSIS y MATLAB) escalan la magnitud de un pico sinusoidal a A*N/2:
    % Entonces |X_cmsis_peak| ~ A_input_stm * N/2
    % Y |X_matlab_peak| ~ A_input_matlab * N/2
    % Las potencias serían |X_cmsis_peak|^2 y |X_matlab_peak|^2.
    % El código STM32 no aplica ninguna normalización adicional antes de la acumulación de potencia.
    % Para que sean comparables, si SINE_AMPLITUDE en MATLAB es igual al pico de la señal en STM32,
    % los valores de `power_spectrum_segment` deberían ser del mismo orden.
    % No se necesita escalado adicional aquí si solo queremos simular la operación del STM32.

    % e. Acumular Espectro de Potencia
    accumulated_psd_matlab = accumulated_psd_matlab + power_spectrum_segment;
    
end % Fin del bucle de segmentos

% --- 4. Promediar Espectro de Potencia Acumulado ---
average_psd_matlab = accumulated_psd_matlab / WELCH_NUM_AVERAGES;

% --- 5. Convertir a dB ---
psd_dB_matlab = zeros(NUM_BINS_OUTPUT, 1);
for k = 1:NUM_BINS_OUTPUT
    if average_psd_matlab(k) < EPSILON_POWER % Usar un epsilon para potencia
        psd_dB_matlab(k) = DB_FLOOR;
    else
        psd_dB_matlab(k) = 10.0 * log10(average_psd_matlab(k));
        if psd_dB_matlab(k) < DB_FLOOR
            psd_dB_matlab(k) = DB_FLOOR;
        end
    end
end

% --- 6. Graficar ---
frequencies_matlab = (0:NUM_BINS_OUTPUT-1) * (PCM_SAMPLING_FREQ / FFT_SIZE);

figure;
plot(frequencies_matlab, psd_dB_matlab);
title(['Periodograma de Welch Simulado en MATLAB (Fs=', num2str(PCM_SAMPLING_FREQ/1000), ...
       'kHz, N=', num2str(FFT_SIZE), ', Navg=', num2str(WELCH_NUM_AVERAGES), ')']);
xlabel('Frecuencia (Hz)');
ylabel('Potencia Estimada (dB)');
grid on;
xlim([0, PCM_SAMPLING_FREQ / 2]);
% ylim([DB_FLOOR - 10, max(psd_dB_matlab) + 10]); % Ajustar Ylim dinámicamente o fijarlo

disp('Simulación de Welch en MATLAB completada.');
% Para comparar con el pwelch de MATLAB (requiere Signal Processing Toolbox):
% figure;
% pwelch(current_segment_pcm, hann(FFT_SIZE), 0, FFT_SIZE, PCM_SAMPLING_FREQ, 'power');
% title('pwelch de MATLAB para un segmento (referencia)');
% (Nota: pwelch haría el promediado internamente si se le da una señal más larga)