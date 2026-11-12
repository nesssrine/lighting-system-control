%% B3 - Scenario 1 : route de nuit (60 s)
t = (0:Ts:60)';  on = true(size(t));
spd = 80*ones(size(t));
spd(t < 10) = 8*t(t < 10);                                  % acceleration 0 -> 80 km/h
spd(t >= 45 & t < 55) = 80 - 6*(t(t >= 45 & t < 55) - 45);  % ralentissement 80 -> 20 km/h
spd(t >= 55) = 20;
det = false(size(t));
det(t >= 20 & t < 25) = true;                               % vehicule en face 20-25 s
for tp = 30:1.5:39, det(t >= tp & t < tp + 0.2) = true; end % detections intermittentes
autoSig  = timeseries(on,t);   switchSig = timeseries(on,t);  lowSig = timeseries(on,t);
speedSig = timeseries(spd,t);  luxSig = timeseries(10*ones(size(t)),t);
detSig   = timeseries(det,t);  camSig = timeseries(on,t);     manSig = timeseries(~on,t);
figure('Color','w');
subplot(2,1,1); plot(t, spd, 'b', 'LineWidth', 1.2); grid on; ylabel('Vitesse [km/h]');
title('Scenario 1 - signaux de test');
subplot(2,1,2); stairs(t, double(det), 'r', 'LineWidth', 1.2); grid on; ylim([-0.2 1.2]);
ylabel('Vehicule detecte'); xlabel('Temps [s]');
disp('Scenario 1 pret : 8 signaux dans le Workspace.')
