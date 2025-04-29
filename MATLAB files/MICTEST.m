clear; clc; close all;
fs = 16000; % O 48000 si estás intentando esa tasa (y relojes son precisos)
targetBaudRate = 115200; 

captureAudioSeconds = 10; 
bytesPerSample = 2;     
targetDataType = 'uint16'; 
endianness = 'l';

targetNumSamples = fs * captureAudioSeconds;
targetNumBytes = targetNumSamples * bytesPerSample;

bytesPerSecond_UART_Approx = targetBaudRate / 10; 
estimatedTransferTime = targetNumBytes / bytesPerSecond_UART_Approx;

maxCaptureDurationSeconds = estimatedTransferTime * 2 + 10; 
maxCaptureDurationSeconds = max(maxCaptureDurationSeconds, captureAudioSeconds * 5); 

fprintf('CONFIGURACIÓN:\n');
fprintf(' Fs Esperada        : %d Hz\n', fs);
fprintf(' Baud Rate          : %d bps\n', targetBaudRate);
fprintf(' Audio a Capturar   : %d s\n', captureAudioSeconds);
fprintf(' Bytes Objetivo     : %d\n', targetNumBytes);
fprintf(' Tiempo Transferencia (Estimado): %.1f s\n', estimatedTransferTime);
fprintf(' Timeout Captura    : %.1f s\n', maxCaptureDurationSeconds);
disp('-------------------------------------------');

% --- Encontrar y Seleccionar Puerto Serie ---
availablePorts = serialportlist("available");
disp("Puertos Serie Disponibles en MATLAB:");
if isempty(availablePorts)
    error('No se detectaron puertos serie. Verifica drivers y conexión del conversor UART-USB.');
end
disp(availablePorts);
fprintf('NOTA: Asegúrate de seleccionar el puerto COM correspondiente a tu conversor UART-USB externo.\n');
selectedPort = input('Introduce el identificador del puerto serie a usar (ej: "COM3" o "/dev/ttyACM0"): ', 's');

% --- Conectar y Capturar Datos ---
allDataBytes = []; % Buffer para acumular bytes recibidos
sp = [];           % Objeto serialport

try
    % Crear y configurar el objeto serialport
    fprintf('Conectando a %s a %d bps...\n', selectedPort, targetBaudRate);
    sp = serialport(selectedPort, targetBaudRate, "Timeout", 0.1); % Timeout corto para no bloquear mucho en read()
    % No es necesario configureTerminator para lectura binaria por tamaño/disponibilidad
    
    flush(sp); % Limpiar buffers del puerto serie (entrada y salida)

    fprintf('Iniciando captura. Esperando hasta %d bytes o %.1f segundos...\n', targetNumBytes, maxCaptureDurationSeconds);
    
    startTime = tic; % Iniciar temporizador general
    lastUpdate = tic; % Temporizador para mostrar progreso
    
    % Bucle principal de captura
    while length(allDataBytes) < targetNumBytes && toc(startTime) < maxCaptureDurationSeconds
        bytesAvailable = sp.NumBytesAvailable; % Consultar cuántos bytes han llegado

        if bytesAvailable > 0
            data = read(sp, bytesAvailable, "uint8");
            % --- LÍNEA MODIFICADA ---
            allDataBytes = [allDataBytes; data(:)]; % Asegura que 'data' sea tratado como columna
            % ------------------------
        end

        
        % Mostrar progreso aproximadamente cada segundo
        if toc(lastUpdate) > 1.0
            percentComplete = (length(allDataBytes) / targetNumBytes) * 100;
            elapsedTime = toc(startTime);
            fprintf('Progreso: %.1f%% (%d / %d bytes) - Tiempo: %.1f s\n', ...
                    percentComplete, length(allDataBytes), targetNumBytes, elapsedTime);
            lastUpdate = tic; % Resetear timer de progreso
        end
        
        pause(0.05); % Pausa MUY corta para ceder CPU y no saturar
    end % Fin del while

    elapsedTime = toc(startTime); % Tiempo total de captura
    finalBytes = length(allDataBytes);

    % Informar resultado de la captura
    fprintf('\n-------------------------------------------\n');
    if finalBytes >= targetNumBytes
        fprintf('Captura completada: %d bytes recibidos en %.1f segundos.\n', finalBytes, elapsedTime);
        % Truncar si se recibieron bytes de más (poco probable con este loop)
        if finalBytes > targetNumBytes
             fprintf('Truncando a %d bytes.\n', targetNumBytes);
             allDataBytes = allDataBytes(1:targetNumBytes);
             finalBytes = targetNumBytes;
        end
    elseif elapsedTime >= maxCaptureDurationSeconds
         fprintf('Captura detenida por TIMEOUT (%d bytes recibidos en %.1f segundos).\n', finalBytes, elapsedTime);
         warning('No se recibieron todos los bytes esperados. Causas posibles: Baud rate bajo, STM32 dejó de enviar, desconexión.');
    else
         fprintf('Captura interrumpida (%d bytes recibidos).\n', finalBytes);
    end

catch ME % Capturar errores de comunicación serie
    fprintf('\nERROR durante la comunicación serie:\n');
    fprintf(' Mensaje: %s\n', ME.message);
     if ~isempty(ME.identifier)
        fprintf(' ID: %s\n', ME.identifier);
     end
     if ~isempty(ME.cause)
         fprintf(' Causa: %s\n', ME.cause{1}.message);
     end
     % Limpiar en caso de error
     if ~isempty(sp)
         clear sp;
     end
     error('Finalizando script debido a error serie.'); % Detener script
end

% --- Limpieza (Cerrar puerto) ---
if ~isempty(sp)
    clear sp; % Cierra y borra el objeto serialport
    fprintf('Puerto serie cerrado.\n');
end

% --- Procesar y Analizar Datos Capturados ---
if ~isempty(allDataBytes) && finalBytes > 0
    numBytes = finalBytes; % Usar los bytes realmente capturados
    fprintf('Procesando %d bytes capturados...\n', numBytes);
    
    % Asegurar número par de bytes para conversión a uint16
    if mod(numBytes, 2) ~= 0
        warning('Número impar de bytes recibido (%d), descartando el último byte.', numBytes);
        allDataBytes = allDataBytes(1:end-1);
        numBytes = length(allDataBytes);
    end
    numSamples = numBytes / bytesPerSample;
    
    % Convertir bytes a uint16 (Little-Endian)
    % typecast reinterpreta los bytes en memoria; el orden debe ser correcto
    try
        audioDataUint16 = typecast(uint8(allDataBytes), targetDataType);
    catch typecast_error
        fprintf('Error en typecast: %s\n', typecast_error.message);
        error('No se pudieron convertir los bytes. Verifica el tipo de dato y endianness.');
    end

    % Calcular duración real del audio capturado
    capturedAudioDuration = numSamples / fs;
    fprintf('Convertido a %d muestras (%s) representando %.2f segundos de audio.\n', ...
            numel(audioDataUint16), targetDataType, capturedAudioDuration);
    
    % --- Análisis ---
    % 1. Graficar Forma de Onda
    figure;
    timeVector = (0:numSamples-1) / fs; % Crear vector de tiempo
    plot(timeVector, audioDataUint16);
    title(sprintf('Forma de Onda Capturada (%.2f s)', capturedAudioDuration));
    xlabel('Tiempo (s)'); ylabel('Amplitud (uint16)'); grid on;

    % 2. Reproducir Audio (centrando y normalizando a -1 a 1)
    audioPlayable = (double(audioDataUint16) - 32768) / 32768; 
    if ~isempty(audioPlayable)
        fprintf('Reproduciendo audio capturado...\n');
        sound(audioPlayable, fs); 
    else
        fprintf('No hay datos suficientes para reproducir.\n');
    end

    % 3. Opcional: Espectro (FFT)
    figure;
    N = length(audioPlayable);
    Y = fft(audioPlayable);
    P2 = abs(Y/N);
    P1 = P2(1:floor(N/2)+1); % Usar floor para evitar problemas con longitud impar
    P1(2:end-1) = 2*P1(2:end-1);
    f = fs*(0:(N/2))/N; % Calcular eje de frecuencias
    plot(f, P1);
    title('Espectro de Frecuencia (Single-Sided)');
    xlabel('Frecuencia (Hz)'); ylabel('|Amplitud|'); grid on;
    xlim([0 fs/2]); % Mostrar hasta frecuencia de Nyquist

else
    fprintf('No se capturaron datos válidos para analizar.\n');
end

disp('Script finalizado.');