close all
clear
clc

fid = fopen('samples.txt','r');
formatSpec = '%d';
data = fscanf(fid, formatSpec);
fclose(fid);

Vref = 3.12;
v = Vref*(data./4095);
fs = 200;
t = (0:length(v)-1)/(fs);
figure('Color',[1,1,1]);
plot(t,v);
title('Output samples from Microblaze');
xlabel('Time (s)');
ylabel('Signal Amplitude (V)');
