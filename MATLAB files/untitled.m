% --- Configuración ---
clear; clc; close all;

% Parámetros del STM32 (ajusta según tu configuración)
comPort = 'COM3';         % << REEMPLAZA 'COMX' con tu puerto COM (ej. 'COM3' en Windows)
baudRate = 115200;        % Debe coincidir con el baudrate de tu STM32
PCM_SAMPLING_FREQ = 32000;% Frecuencia de muestreo PCM en el STM32 (Hz)
FFT_SIZE = 512;           % Tamaño de la FFT usado en el STM32

NUM_FFT_BINS = FFT_SIZE / 2; % Número de magnitudes únicas de la RFFT

% --- Configuración del Puerto Serial ---
% Eliminar cualquier instancia previa del puerto serial si existe
if ~isempty(instrfind('Port', comPort, 'Status', 'open'))
    fclose(instrfind('Port', comPort));
    delete(instrfind('Port', comPort));
end

% Crear y configurar el objeto serialport (para MATLAB R2019b y newer)
% Para versiones antiguas de MATLAB, usarías: device = serial(comPort, 'BaudRate', baudRate);
try
    device = serialport(comPort, baudRate);
    configureTerminator(device, "CR/LF"); % Asume que STM32 envía \r\n
    device.Timeout = 10; % Timeout para lecturas (en segundos)
    disp(['Puerto serial ' comPort ' configurado.']);
catch e
    disp(['Error configurando el puerto serial: ' e.message]);
    disp('Asegúrate que el puerto COM es correcto y no está en uso.');
    return;
end

% --- Preparación de la Figura para Graficar ---
figureHandle = figure;
hold on; % Mantener el gráfico para actualizaciones

% Calcular el vector de frecuencias para el eje X
frequencies = (0:NUM_FFT_BINS-1) * (PCM_SAMPLING_FREQ / FFT_SIZE);

% Inicializar el gráfico con datos vacíos o ceros
currentMagnitudes = zeros(1, NUM_FFT_BINS);
plotHandle = plot(frequencies, currentMagnitudes);

title('Espectro FFT en Tiempo Real desde STM32');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud');
% Puedes ajustar los límites del eje Y si conoces el rango esperado de tus magnitudes
% ylim([min_expected_magnitude max_expected_magnitude]);
grid on;
axis tight; % Ajusta los ejes al rango de datos inicial

disp('Intentando abrir el puerto serial...');
try
    fopen(device); % Abrir el puerto serial (en versiones antiguas de MATLAB)
                   % Para serialport, la conexión se establece al crear el objeto
                   % y se usa flush() o readline() para empezar.
    disp(['Puerto ' comPort ' abierto. Esperando datos del STM32...']);
catch e
    disp(['Error abriendo el puerto serial: ' e.message]);
    delete(device);
    return;
end

% --- Bucle Principal de Adquisición y Graficación ---
keepRunning = true;
figureHandle.UserData = struct('keepRunning', true); % Para detener desde la figura
set(figureHandle, 'CloseRequestFcn', 'f = gcf; f.UserData.keepRunning = false; closereq;');


magnitudes_buffer = zeros(1, NUM_FFT_BINS); % Buffer para almacenar un frame FFT

try
    while figureHandle.UserData.keepRunning
        for i = 1:NUM_FFT_BINS
            if(device.NumBytesAvailable > 0)
                try
                    data_line_str = readline(device); % Lee una línea terminada por CR/LF
                    magnitudes_buffer(i) = str2double(data_line_str);
                catch read_error
                    disp(['Error leyendo/parseando línea: ' read_error.message]);
                    % Podrías poner NaN o el valor anterior para este bin
                    magnitudes_buffer(i) = NaN; % O 0, o el valor anterior
                end
            else
                % No hay suficientes datos para un frame completo, esperar un poco
                % Esto puede pasar si MATLAB lee más rápido de lo que STM32 envía
                % O si la comunicación se interrumpe.
                % pause(0.01); % Pausa corta
                % disp('Esperando más datos...');
                % break; % Salir del bucle for si no hay datos suficientes para un frame
            end
        end
        
        % Solo actualizar si se leyó un frame razonable (ej. no demasiados NaNs)
        if ~all(isnan(magnitudes_buffer))
             % Actualizar los datos del gráfico
            set(plotHandle, 'YData', magnitudes_buffer);
            drawnow; % Forza la actualización del gráfico
        end
        
        % Pequeña pausa para permitir que MATLAB maneje eventos y no saturar la CPU.
        % También controla la tasa de refresco del gráfico.
        pause(0.01); % Ajusta este valor según sea necesario (ej. 0.01 para ~100 FPS max, 0.05 para ~20 FPS)
    end
catch e
    disp(['Error durante el bucle de graficación: ' e.message]);
end

% --- Limpieza ---
disp('Cerrando el puerto serial...');
% fclose(device); % Para el antiguo objeto 'serial'
clear device;  % Para el nuevo objeto 'serialport', simplemente limpiarlo lo cierra.
disp('Puerto cerrado y script finalizado.');