%% B4 - Scenario 1 : conduite normale, commandes manuelles, AUTO, AHB, mode degrade (40 s)
t = (0:Ts:40)';  F = false(size(t));  T = true(size(t));
ign = t >= 1;                                           % contact a 1 s
sw = zeros(size(t)); sw(t >= 3) = 2; sw(t >= 6) = 3; sw(t >= 16) = 1;   % OFF, POSITION, CROISEMENT, AUTO
hb = F; hb(t >= 8 & t < 8.1) = true; hb(t >= 10 & t < 10.1) = true;     % commutation route
fl = F; fl(t >= 12 & t < 12.5) = true;                  % appel de phares
fg = F; fg(t >= 5 & t < 5.1) = true; fg(t >= 14 & t < 14.1) = true;     % bouton antibrouillard
al = t >= 18;                                           % B2 demande le croisement (nuit) des 18 s
ah = t >= 22 & t < 26;                                  % B3 demande les feux de route 22-26 s
lx = 5000*ones(size(t)); vb = 13.5*ones(size(t)); dc = T;
dg = zeros(size(t)); dg(t >= 30) = 2;                   % B6 : croisement droit en defaut a 30 s
B4_mk;
figure('Color','w');
subplot(2,1,1); stairs(t, sw, 'b', 'LineWidth', 1.4); yticks(0:3); yticklabels({'OFF','AUTO','POSITION','CROISEMENT'});
ylim([-0.3 3.3]); grid on; title('Scenario 1 - position du commodo');
subplot(2,1,2); stairs(t, double([ign hb+1.2 fl+2.4 fg+3.6 al+4.8 ah+6]), 'LineWidth', 1.1);
yticks(0.5:1.2:6.5); yticklabels({'Contact','Commut. route','Appel phares','Antibrouillard','B2 auto','B3 AHB'});
grid on; xlabel('Temps [s]');
disp('Scenario 1 pret : 11 signaux dans le Workspace.')
