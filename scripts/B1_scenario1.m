%% B1 - Scenario 1 : filtrage et diagnostic du capteur de luminosite (30 s)
t = (0:Ts:30)';
base = 5000*ones(size(t)); base(t >= 5) = 500;             % passage jour -> nuit a 5 s
rng(2);
lux = base .* (1 + 0.20*(2*rand(size(t))-1));              % bruit +/-20 %
lux(t >= 12 & t < 12.5) = 200000;                          % valeur aberrante (hors plage) 12-12,5 s
msg = true(size(t));
msg(t >= 18 & t < 18.3) = false;                           % absence courte 0,3 s (tolere)
msg(t >= 22 & t < 23)   = false;                           % absence longue 1 s (defaut)
sw = ones(size(t));  fl = false(size(t));                  % commodo en AUTO, pas d'appel de phares
luxRawSig = timeseries(lux, t);  msgSig = timeseries(msg, t);
swSig = timeseries(sw, t);       flashSig = timeseries(fl, t);
figure('Color','w');
subplot(2,1,1); plot(t, min(lux, 8000), 'Color', [0.5 0.5 0.5]); grid on; ylabel('Lux brut (ecrete a 8000)');
title('Scenario 1 - signaux de test');
subplot(2,1,2); stairs(t, double(msg), 'r', 'LineWidth', 1.2); ylim([-0.2 1.2]); grid on;
ylabel('Message recu'); xlabel('Temps [s]');
disp('Scenario 1 pret : luxRawSig, msgSig, swSig, flashSig dans le Workspace.')
