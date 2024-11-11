close all
clear
clc

fs = 10e+06;
Ts = 1/fs;
n = 0:999;
t = n*Ts;
x = 1.65 + 1*sin(2*pi*50000*t) + 0.1*sin(2*pi*2000000*t);

figure('Color',[1 1 1]);
h = plot(t,x);
title('x(t) Sampled at fs = 10 MHz');
ylabel('Signal');
xlabel('Time (s)');

% quantize x
Vref = 3.3;
bits = 16; % precision of ADC
xq = (x./Vref)*((2^(bits-1))-1);
xq_int = cast(xq,"int16");

fid = fopen('50kHz_sine_wave_with_noise.txt','w');
fprintf(fid,"%d\n",xq_int);
fclose(fid);

figure('Color',[1 1 1]);
h = plot(t,xq_int,'.');
title('x(t) Quantized to 16-bit Integer: Sampled at fs = 10 MHz');
ylabel('Signal');
xlabel('Time (s)');

%% generate filter coefficents
% LP elliptical filter cutoff @ 60 kHz 
% should elimate 200 kHz noise and pass 50 kHz component
fc = 60e+3;
Wc = fc/(fs/2);
[B,A] = ellip(2,0.5,40,Wc);

figure('Color',[1 1 1]);
freqz(B,A,2^10,fs);
figure('Color',[1 1 1]);
zplane(B,A);

%% playing with embedding gain

% MATLAB SAYS NOT RECCOMENDED FOR DIRECT-FORM II, okay for Direct-form I
[sos_embedded_gain] = tf2sos(B,A) 

% proper way for DF2
[sos,g] = tf2sos(B,A)

%% multiply coefficients to get fixed point

Afixed = fix(A*(2^14))
Bfixed = fix(B*(2^14))

%% check stability of fixed point coefficients
figure('Color',[1 1 1]);
zplane((Bfixed./2^14), (Afixed./2^14));
hold on;
title("Pole-Zero Plot After Fixed Point Conversion");

%% 
step_smpls = 1000*ones(1,1000);
hn_fixed = filter(Bfixed,Afixed,step_smpls);
figure('Color',[1 1 1]);
plot(hn_fixed,'r');
hold on;
hn = filter(B,A,step_smpls);
plot(hn,'b');
title("Step response fixed-point vs floating point coefficients");
legend({'Fixed-point','Floating-point'});

%% perform the filter
yq = filter(Bfixed,Afixed,xq_int);
figure('Color',[1 1 1]);
plot(yq);

