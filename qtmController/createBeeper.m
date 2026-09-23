function [signal, fs] = createBeeper()
fs = 8192;
toneduration = 0.1;
spaceduration = 0.02;
tonefreq = 300;
nbeeps = 15;
t = linspace(0,toneduration,round(toneduration*fs));
y = 0.8*sin(2*pi*tonefreq*t); % tone
ys = zeros(1,round(spaceduration*fs)); % space
signal = [repmat([y ys],[1 nbeeps-1]) y]; % the whole signal

end