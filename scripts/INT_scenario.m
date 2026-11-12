%% INTEGRATION - Scenario de bout en bout : un trajet complet (130 s)
t = (0:Ts:130)';  N = numel(t);  F = false(N,1);
% --- conducteur et vehicule
ignition = (t >= 2 & t < 92);                               % contact de 2 s a 92 s
sw_raw   = ones(N,1);                                       % commodo laisse sur AUTO
flash_raw = F;  hb_toggle = F;  fog_sw = F;  hazard_sw = F;  clear_dtc = F;
ahb_switch = true(N,1);                                     % fonction AHB activee
turn_left = (t >= 8 & t < 10);  turn_right = F;             % changement de direction a 8 s
spd = zeros(N,1);
i = t >= 5  & t < 15;  spd(i) = 5*(t(i) - 5);               % 0 -> 50 km/h
spd(t >= 15 & t < 30) = 50;
i = t >= 30 & t < 35;  spd(i) = 50 + 6*(t(i) - 30);         % 50 -> 80 km/h
spd(t >= 35 & t < 65) = 80;
i = t >= 65;           spd(i) = max(80 - 28.8*(t(i) - 65), 0);   % freinage d'urgence 8 m/s2
i = t >= 78 & t < 82;  spd(i) = 7.5*(t(i) - 78);            % redemarrage 0 -> 30 km/h
spd(t >= 82 & t < 84) = 30;
i = t >= 84 & t < 90;  spd(i) = 30 - 5*(t(i) - 84);         % arrivee a la maison
decel = zeros(N,1);  decel(t >= 65 & t < 65 + 80/28.8) = 8;  decel(t >= 84 & t < 90) = 1.39;
brake_pedal = (t >= 65 & t < 76) | (t >= 84 & t < 92);
door_closed = ~(t >= 93 & t < 95);                          % le conducteur sort a 93 s
vbat = 12.6*ones(N,1);  vbat(ignition) = 14.2;              % alternateur quand le moteur tourne
% --- environnement
lux_raw = 20000*ones(N,1);
i = t >= 20 & t < 32;  lux_raw(i) = 20000 - (20000 - 10)*(t(i) - 20)/12;   % crepuscule
lux_raw(t >= 32) = 10;                                      % nuit, route non eclairee
msg_ok = true(N,1);
vehicle_detected = (t >= 45 & t < 50);  cam_ok = true(N,1); % vehicule venant en face
lamp_fail = ones(N,4);  lamp_fail(t >= 55, 2) = 0;          % ampoule du croisement droit grillee a 55 s
names = {'ignition','sw_raw','flash_raw','hb_toggle','fog_sw','ahb_switch','turn_left','turn_right', ...
         'hazard_sw','brake_pedal','lux_raw','msg_ok','speed','decel','vehicle_detected','cam_ok', ...
         'door_closed','vbat','clear_dtc','lamp_fail'};
vals = {ignition, sw_raw, flash_raw, hb_toggle, fog_sw, ahb_switch, turn_left, turn_right, hazard_sw, ...
        brake_pedal, lux_raw, msg_ok, spd, decel, vehicle_detected, cam_ok, door_closed, vbat, clear_dtc, lamp_fail};
for k = 1:numel(names), assignin('base', ['in_' names{k}], timeseries(vals{k}, t)); end
disp('Scenario d''integration pret : 20 signaux in_* dans le Workspace.')
