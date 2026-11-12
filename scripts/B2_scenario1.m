%% B2 - Scenario 1 : jour -> nuit -> jour -> tunnel (45 s)
t = (0:Ts:45)';
base = 5000*ones(size(t));
base(t>=5  & t<10)    = 5000 - 4500*(t(t>=5 & t<10)-5)/5;          % crepuscule
base(t>=10 & t<20)    = 500;                                       % nuit
base(t>=20 & t<25)    = 500 + 2500*(t(t>=20 & t<25)-20)/5;         % aube
base(t>=25 & t<32)    = 3000;                                      % jour
base(t>=32 & t<32.1)  = 3000 - 2900*(t(t>=32 & t<32.1)-32)/0.1;    % entree tunnel
base(t>=32.1 & t<38)  = 100;                                       % tunnel
base(t>=38)           = 5000;                                      % sortie
rng(1);
lux = base .* (1 + 0.10*(2*rand(size(t))-1));                      % bruit +/-10 %
luxSig   = timeseries(lux, t);
validSig = timeseries(true(size(t)), t);
plot(t, lux); grid on; xlabel('Temps [s]'); ylabel('Luminosite [lux]');
title('Scenario 1 - signal de test');
disp('Scenario 1 pret : luxSig et validSig sont dans le Workspace.')
