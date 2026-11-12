%% INTEGRATION - Scenario 3 : panne de camera et appel de phares, de nuit (40 s)
t = (0:Ts:40)'; INT_defaults;
lux_raw(:) = 10; spd(:) = 80;                                 % nuit, route non eclairee, 80 km/h
cam_ok(t >= 10 & t < 20) = false;                             % camera en panne 10-20 s
flash_raw(t >= 26 & t < 26.5) = true;                         % appel de phares 26-26,5 s
INT_mk; disp('Scenario 3 pret : camera en panne 10-20 s, appel de phares a 26 s.')
