%% B7 - Scenario 1 : commandes recues de B4/B5 et tension batterie variable (10 s)
t = (0:Ts:10)';  F = false(size(t));
drl = t < 1;                                       % DRL avant le croisement
lowL = t >= 1 & t < 9;  lowR = lowL;               % croisement 1-9 s
pos = t >= 1;                                      % veilleuses avec le croisement
hi = t >= 3 & t < 3.5;                             % feux de route brefs
fg = t >= 8 & t < 9;                               % antibrouillard
P = 1/1.5; bl = (t >= 7) & (mod(t - 7 + 1e-9, P) < P/2);   % clignotant G a partir de 7 s
br = t >= 6 & t < 7;                               % freinage 6-7 s
vb = 14.4*ones(size(t)); vb(t >= 4 & t < 5) = 12.5; vb(t >= 5) = 13.8;   % alternateur / batterie
lLSig = timeseries(lowL,t); lRSig = timeseries(lowR,t); hiSig = timeseries(hi,t); posSig = timeseries(pos,t);
drlSig = timeseries(drl,t); fgSig = timeseries(fg,t); bLSig = timeseries(bl,t); bRSig = timeseries(F,t);
brSig = timeseries(br,t); vbSig = timeseries(vb,t);
figure('Color','w');
subplot(2,1,1); stairs(t, double([drl lowL+1.2 pos+2.4 hi+3.6 fg+4.8 bl+6 br+7.2]), 'LineWidth', 1.1);
yticks(0.5:1.2:7.7); yticklabels({'DRL','Croisement','Veilleuses','Route','Antibrouill.','Clignot. G','Stop'}); grid on;
title('Scenario 1 - commandes recues de B4 et B5');
subplot(2,1,2); plot(t, vb, 'r', 'LineWidth', 1.4); ylim([11 15]); grid on; ylabel('Vbat [V]'); xlabel('Temps [s]');
disp('Scenario 1 pret : 10 signaux dans le Workspace.')
