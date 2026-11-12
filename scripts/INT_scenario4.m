%% INTEGRATION - Scenario 4 : batterie faible pendant le follow-me-home (60 s)
t = (0:Ts:60)'; INT_defaults;
lux_raw(:) = 10;                                              % nuit
ignition = t < 10;                                            % contact coupe a 10 s
spd(t < 8) = 50; i = t >= 8 & t < 10; spd(i) = 50 - 25*(t(i) - 8);   % arrivee
door_closed = ~(t >= 11 & t < 12);                            % le conducteur sort
vbat(t >= 10) = 12.6; i = t >= 10 & t < 25; vbat(i) = 12.6 - 1.1*(t(i) - 10)/15;  % la batterie se decharge
vbat(t >= 25) = 11.5;
INT_mk; disp('Scenario 4 pret : contact coupe a 10 s, batterie qui descend sous 11,8 V.')
