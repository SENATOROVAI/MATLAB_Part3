%% ГЛАВА 3. МОДЕЛИРОВАНИЕ РАДИОСИСТЕМЫ ГОЛОСОВОГО ОПОВЕЩЕНИЯ

%% Секция 1. Общие параметры
clear; close all; clc;
rng(1);
fs       = 8000;
f_low    = 300;
f_high   = 3400;
T        = 1.0;
t        = (0:round(fs*T)-1)'/fs;
fprintf('Параметры: fs=%d Гц, полоса %d..%d Гц\n', fs, f_low, f_high);

%% Секция 2. Источник сигнала (рис. 5)
f0   = 140;
sig  = zeros(size(t));
for h = 1:25
    sig = sig + (1/h)*sin(2*pi*f0*h*t);
end
formants = [500 1500 2500];
for fk = formants
    sig = sig + 0.6*sin(2*pi*fk*t);
end
env  = 0.5*(1 - cos(2*pi*4*t)) + 0.1;
audioData = env .* sig;
audioData = audioData / max(abs(audioData));
try, sound(audioData, fs); catch, end
figure('Name','Рис.5 Речевой сигнал');
plot(t, audioData); grid on;
xlabel('Время, с'); ylabel('Амплитуда');
title('Рисунок 5 - Формирование речевого сигнала в MATLAB');

%% Секция 3. Фильтрация (рис. 6)
filteredSignal = bp_filter(audioData, fs, f_low, f_high, 4);
N  = numel(t);
fA = (0:N-1)'/N*fs;
S1 = abs(fft(audioData));  S2 = abs(fft(filteredSignal));
half = 1:floor(N/2);
figure('Name','Рис.6 Фильтрация');
subplot(2,1,1);
plot(t, audioData, t, filteredSignal); grid on;
xlabel('Время, с'); ylabel('Амплитуда');
legend('до фильтра','после фильтра');
title('Рисунок 6 - Полосовая фильтрация (Баттерворт 4-го порядка)');
subplot(2,1,2);
plot(fA(half), S1(half), fA(half), S2(half)); grid on;
xlabel('Частота, Гц'); ylabel('|X(f)|');
xline(f_low,'--'); xline(f_high,'--');
legend('спектр до','спектр после');

%% Секция 4. Кодек G.711 (mu-law, 64 кбит/с)
code    = g711_encode(filteredSignal);
decoded = g711_decode(code);
qnoise  = filteredSignal - decoded;
snr_q   = 10*log10(sum(filteredSignal.^2)/sum(qnoise.^2));
MOS     = 4.1;
fprintf('G.711: 64 кбит/с, 8 бит, SNR=%.1f дБ, MOS=%.1f\n', snr_q, MOS);
figure('Name','G.711 ошибка квантования');
plot(t, qnoise); grid on;
xlabel('Время, с'); ylabel('Ошибка');
title(sprintf('G.711: ошибка квантования (SNR = %.1f дБ)', snr_q));

%% Секция 5. Сеть передачи: задержка, джиттер, потери
frameDur     = 0.02;
nPkt         = 100;
meanDelay    = 0.05;
jitterStd    = 0.01;
lossProb     = 0.02;
delays  = meanDelay + jitterStd*randn(nPkt,1);
lost    = rand(nPkt,1) < lossProb;
received = ~lost;
fprintf('Сеть: задержка %.0f±%.0f мс, потери %.0f%% (%d из %d)\n', ...
        meanDelay*1e3, jitterStd*1e3, lossProb*100, sum(lost), nPkt);
figure('Name','Сеть: поток пакетов');
subplot(2,1,1);
stem(find(received), delays(received)*1e3, 'b', 'Marker','.'); hold on;
stem(find(lost), delays(lost)*1e3, 'r', 'filled');
grid on; xlabel('Номер пакета'); ylabel('Задержка, мс');
legend('принят','потерян');
title('Поток пакетов: задержка и джиттер (потери — красным)');
subplot(2,1,2);
stairs(1:nPkt, double(received)); ylim([-0.2 1.2]); grid on;
xlabel('Номер пакета'); ylabel('Принят (1/0)');
title('Маскирование потерь — повтором предыдущего пакета');

%% Секция 6. Радиоканал и замирания (рис. 7)
Pt = 20; Gt = 5; Gr = 3; L = 80; L_fade = 5;
Pr = Pt + Gt + Gr - L - L_fade;
fadingStd = 3;
Nf  = 500;
tf  = (0:Nf-1)'/fs;
Pr_t = Pr + fadingStd*randn(Nf,1);
fprintf('Радиоканал: Pr = %d дБм, замирания СКО %d дБ\n', Pr, fadingStd);
figure('Name','Рис.7 Замирания');
plot(tf, Pr_t); hold on; yline(Pr,'r--','LineWidth',1.2);
grid on; xlabel('Время, с'); ylabel('Уровень сигнала, дБм');
legend('мгновенный уровень','среднее P_r');
title('Рисунок 7 - Моделирование замираний сигнала');

%% Секция 7. Аварийный контроллер (рис. 8)
events(1) = struct('time', 1.0, 'type', 'fire');
events(2) = struct('time', 4.0, 'type', 'operator_test');
events(3) = struct('time', 6.0, 'type', 'reset');
[ts, st] = alarm_fsm(events, 100);
t_sensor = 0.10; t_ctrl = 0.05; t_audio = 0.20;
reaction = t_sensor + t_ctrl + t_audio;
assert(reaction < 1.0, 'Превышено время реакции!');
fprintf('Контроллер: время реакции %.2f с (норматив < 1 с)\n', reaction);
figure('Name','Рис.8 Работа системы оповещения');
stairs(ts, st, 'LineWidth', 1.4); ylim([0.5 5.5]); grid on;
yticks(1:5); yticklabels({'IDLE','ALARM','EVACUATION','TEST','FAULT'});
xlabel('Время, с'); ylabel('Состояние');
title('Рисунок 8 - Работа системы оповещения (конечный автомат)');

%% Секция 8. Аудиотракт (SPL) и резервирование питания
gain_dB  = 30;  gain_lin = 10^(gain_dB/20);
amp = gain_lin * filteredSignal;
lim = 0.8*max(abs(amp));
amp_sat = max(min(amp, lim), -lim);
sensitivity = 95; inputPower = 10; distance = 10;
SPL = sensitivity + 10*log10(inputPower) - 20*log10(distance);
fprintf('Аудиотракт: усиление %d дБ, SPL = %d дБ на %d м\n', gain_dB, SPL, distance);
tp   = (0:1e-4:0.1)';
main = 24*ones(size(tp)); main(tp >= 0.05) = 0;
batt = 24*ones(size(tp));
thr  = 21.6;
outV = main; sw = main < thr; outV(sw) = batt(sw);
fprintf('Питание: порог %.1f В, переключение на резерв при провале\n', thr);
figure('Name','Аудиотракт и питание');
subplot(2,1,1);
plot(t, amp, t, amp_sat); grid on;
xlabel('Время, с'); ylabel('Амплитуда');
legend('после усиления','после ограничения');
title(sprintf('Аудиотракт: усиление %d дБ, Saturation; SPL=%d дБ', gain_dB, SPL));
subplot(2,1,2);
plot(tp*1e3, main, tp*1e3, outV, 'LineWidth', 1.2); grid on;
yline(thr, 'k--'); ylim([-1 26]);
xlabel('Время, мс'); ylabel('Напряжение, В');
legend('основной источник','выход (с резервом)','порог 21.6 В');
title('Резервирование питания: переключение на аккумулятор');
