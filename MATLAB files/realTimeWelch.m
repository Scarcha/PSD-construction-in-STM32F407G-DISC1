% -------------------------------------------------------------------------
% Script de MATLAB para Graficar FFT en Tiempo Real desde UART (N=1024)
% -------------------------------------------------------------------------
clear; clc; close all;

% --- Parámetros de Configuración (AJUSTA ESTOS VALORES) ---
comPort = 'COM3';                % << REEMPLAZA 'COMX' con tu puerto COM
baudRate = 2000000;               % << DEBE COINCIDIR CON STM32

PCM_SAMPLING_FREQ = 32000;       % Frecuencia de muestreo PCM en STM32 (Hz)
FFT_SIZE = 1024;                 % Tamaño de la FFT usado en STM32
DB_FLOOR = -80;
NUM_BINS = FFT_SIZE / 2;         % Número de magnitudes únicas de RFFT (512)

% --- Advertencia de Rendimiento (Revisada para 921600bps) ---
estimated_chars_per_bin = 10; % Ej: "-XX.YY\r\n" (puede ser más corto si los dB son más pequeños)
total_chars_per_frame = NUM_BINS * estimated_chars_per_bin;
time_to_send_one_frame_ascii_seconds = (total_chars_per_frame * 10) / baudRate; % 10 bits por char (aprox)
stm32_fft_frame_interval_seconds = FFT_SIZE / PCM_SAMPLING_FREQ; % 1024 / 32000 = 0.032 s = 32 ms

fprintf('INFORMACIÓN DE RENDIMIENTO:\n');
fprintf('  Tiempo de generación de frame FFT en STM32: %.3f ms\n', stm32_fft_frame_interval_seconds * 1000);
fprintf('  Tiempo estimado para enviar un frame FFT (%d bins) como ASCII a %d bps: %.3f ms\n', NUM_BINS, baudRate, time_to_send_one_frame_ascii_seconds * 1000);
if time_to_send_one_frame_ascii_seconds > stm32_fft_frame_interval_seconds
    fprintf('  ADVERTENCIA: El envío UART podría ser un cuello de botella (%.1fms envío vs %.1fms generación).\n', time_to_send_one_frame_ascii_seconds*1000, stm32_fft_frame_interval_seconds*1000);
    fprintf('  Esto puede causar que MATLAB no muestre todos los frames o que haya lag.\n');
else
    fprintf('  El envío UART parece ser lo suficientemente rápido (%.1fms envío vs %.1fms generación).\n', time_to_send_one_frame_ascii_seconds*1000, stm32_fft_frame_interval_seconds*1000);
end
fprintf('-------------------------------------------------\n');


% --- Configuración del Puerto Serial ---
% (Misma lógica que antes para limpiar y crear/configurar 'device')
existingPorts = serialportlist("available");
if ismember(comPort, existingPorts)
    if ~isempty(instrfind('Port', comPort, 'Status', 'open'))
        disp(['Cerrando puerto serial existente: ' comPort]);
        old_ports = instrfind('Port', comPort); % instrfind devuelve objetos seriales antiguos si existen
        fclose(old_ports);
        delete(old_ports);
    end
else
    disp(['Puerto ' comPort ' no encontrado. Puertos disponibles:']);
    disp(existingPorts);
    if isempty(existingPorts)
        disp('No hay puertos seriales disponibles.');
    end
    return;
end

try
    device = serialport(comPort, baudRate);
    configureTerminator(device, "CR/LF");
    device.Timeout = 2; % Timeout para lecturas (segundos). Si es muy corto y hay lag, puede fallar.
                        % Si un frame tarda ~50ms en enviar, un timeout de 1-2s debería ser seguro.
    disp(['Puerto serial ' comPort ' configurado a ' num2str(baudRate) ' bps.']);
catch e
    disp(['Error configurando el puerto serial: ' e.message]);
    return;
end

% --- Preparación de la Figura para Graficar ---
figureHandle = figure('Name', ['Periodograma de Welch (N=' num2str(FFT_SIZE) ')'], 'NumberTitle', 'off'); % Título de ventana actualizado
hold on;

frequencies = (0:NUM_BINS-1) * (PCM_SAMPLING_FREQ / FFT_SIZE);
initial_dB_values = ones(1, NUM_BINS) * DB_FLOOR; % Usar el DB_FLOOR definido en STM32
plotHandle = plot(frequencies, initial_dB_values);

title(['Periodograma de Welch (N=' num2str(FFT_SIZE) ', Fs=' num2str(PCM_SAMPLING_FREQ/1000) 'kHz)']); % Título del gráfico actualizado
xlabel('Frecuencia (Hz)');
ylabel('Potencia Estimada (dB)');
ylim([-10, 100]); % Ajusta el límite superior si tus señales son más fuertes
xlim([0, PCM_SAMPLING_FREQ / 2]);
grid on;

disp(['Puerto ' comPort ' abierto. Esperando marcador SOF del STM32...']);
disp('Cierra la ventana de la figura para detener el script.');

% --- Bucle Principal ---
keepRunning = true;
figureHandle.UserData = struct('keepRunning', true);
set(figureHandle, 'CloseRequestFcn', 'f = gcf; f.UserData.keepRunning = false; closereq;');

magnitudes_dB = initial_dB_values; % Buffer para almacenar un frame FFT en dB

try
    while figureHandle.UserData.keepRunning && ishandle(figureHandle)
        tic;
        % 1. Buscar el Marcador de Inicio de Trama (SOF)
        sofMarker = "SOF";
        isFrameSynced = false;
        syncAttempts = 0;
        maxSyncAttemptsLoop = NUM_BINS * 2; % Intentar leer algunas líneas para encontrar SOF

        while ~isFrameSynced && figureHandle.UserData.keepRunning && syncAttempts < maxSyncAttemptsLoop
            if device.NumBytesAvailable > 0
                try
                    line = strtrim(readline(device));
                    if strcmpi(line, sofMarker)
                        isFrameSynced = true;
                        % disp('SOF Encontrado!'); % Descomentar para depurar sincronización
                    % else % Descomentar para ver qué se recibe si no es SOF
                        % disp(['Sync Read (buscando SOF): "', line, '"']);
                    end
                catch sync_err
                    disp(['Error en readline durante sincronización: ', sync_err.message]);
                    pause(0.01); 
                end
            else
                pause(0.005); % Esperar un poco más si no hay bytes
            end
            syncAttempts = syncAttempts + 1;
            if ~ishandle(figureHandle); break; end % Salir si la figura se cerró
        end

        if ~isFrameSynced 
            if ishandle(figureHandle) % Solo mostrar si la figura sigue abierta
                 % disp('SOF no encontrado, reintentando ciclo principal de sincronización...');
            end
            pause(0.05); 
            continue;   
        end

        % 2. Si SOF fue encontrado, leer los NUM_BINS valores de magnitud
        dataCompleteThisFrame = true;
        temp_magnitudes = NaN(1, NUM_BINS); 

        for i = 1:NUM_BINS
            if device.NumBytesAvailable > 0
                try
                    data_line_str = readline(device);
                    if isempty(data_line_str) || strlength(strtrim(data_line_str)) == 0
                        % temp_magnitudes(i) ya es NaN
                        % disp(['Bin ', num2str(i-1), ': Línea vacía recibida.']);
                        continue; 
                    end
                    
                    val = str2double(data_line_str);
                    if ~isnan(val)
                        temp_magnitudes(i) = val;
                    % else % Descomentar para depurar parseo
                        % disp(['Bin ', num2str(i-1), ': str2double devolvió NaN para "', data_line_str, '"']);
                    end
                catch read_error
                    disp(['Error leyendo/parseando datos para bin ', num2str(i-1), ': ', read_error.message]);
                    temp_magnitudes(i) = NaN;
                    dataCompleteThisFrame = false; 
                    break; 
                end
            else
                % disp(['Timeout esperando datos para bin ', num2str(i-1)]);
                dataCompleteThisFrame = false;
                break; 
            end
            if ~ishandle(figureHandle); dataCompleteThisFrame = false; break; end % Salir si la figura se cerró
        end
        readParseTime = toc; 
        % 3. Actualizar el gráfico
        if dataCompleteThisFrame && ishandle(figureHandle)
            nan_indices = isnan(temp_magnitudes);
            temp_magnitudes(nan_indices) = magnitudes_dB(nan_indices); 
            
            magnitudes_dB = temp_magnitudes; 
            
            if ~all(isnan(magnitudes_dB)) 
                set(plotHandle, 'YData', magnitudes_dB);
                drawnow limitrate; 
            % else % Descomentar para depurar
                % disp('Frame FFT contenía solo NaNs, no se actualiza el gráfico.');
            end
        elseif ishandle(figureHandle) % Solo mostrar si la figura sigue abierta
            % disp('Frame FFT incompleto o con errores, no se actualiza el gráfico. Re-sincronizando...');
        end
        totalFrameTime = toc; % Tiempo total del frame en MATLAB
        fprintf('Tiempo de parseo: %.3f ms, Tiempo total del frame MATLAB: %.3f ms, Bytes en buffer: %d\n', ...
                readParseTime*1000, totalFrameTime*1000, device.NumBytesAvailable);
        
        
    end 
catch e
    disp(['Error durante el bucle de graficación: ' e.message]);
    fprintf('Error en la línea %d del script MATLAB.\n', e.stack(1).line);
end

% --- Limpieza ---
disp('Cerrando el puerto serial...');
clear device;
disp('Puerto cerrado y script finalizado.');

if ishandle(figureHandle)
    disp('Cierra la ventana de la figura manualmente si no se cerró.');
else
    disp('La ventana de la figura ya fue cerrada.');
end