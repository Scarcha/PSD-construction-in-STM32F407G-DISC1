%% Arreglo de unos
N = 32;          % Número de muestras
signal = ones(1,N);
fft_output = fft(signal);

%% Delta de Dirac
N = 32;          % Número de muestras
signal = zeros(1,N);
signal(6) = 1;
fft_output = fft(signal);

%% Sinusoidal
f = 10;          % Frecuencia (Hz)
A = 10;          % Amplitud
N = 32;          % Número de muestras
fs = N * f;      % Frecuencia de muestreo (320 Hz)

% Vector de tiempo discreto
n = 0:N-1;       % Índices de muestras (0 a 31)
t = n / fs;      % Tiempo correspondiente a cada muestra

% Senoidal discreta
signal = A * sin(2 * pi * f * t);

fft_output = fft(signal);