%% INTEGRATION - Scenario 2 : traversee d'un tunnel en plein jour (40 s)
t = (0:Ts:40)'; INT_defaults;
spd(:) = 90;                                                  % autoroute, 90 km/h
lux_raw(:) = 30000;                                           % plein soleil
i = t >= 10 & t < 10.1; lux_raw(i) = 30000 - 29850*(t(i) - 10)/0.1;   % entree du tunnel
lux_raw(t >= 10.1 & t < 20) = 150;                            % eclairage du tunnel
i = t >= 20 & t < 20.1; lux_raw(i) = 150 + 29850*(t(i) - 20)/0.1;     % sortie
INT_mk; disp('Scenario 2 pret : tunnel de 10 s a 20 s.')
