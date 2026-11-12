%% INTEGRATION - valeurs par defaut de tous les signaux (a appeler apres avoir defini t)
N = numel(t); F = false(N,1); T = true(N,1);
ignition = T; sw_raw = ones(N,1); flash_raw = F; hb_toggle = F; fog_sw = F; ahb_switch = T;
turn_left = F; turn_right = F; hazard_sw = F; brake_pedal = F; lux_raw = 20000*ones(N,1); msg_ok = T;
spd = zeros(N,1); decel = zeros(N,1); vehicle_detected = F; cam_ok = T; door_closed = T;
vbat = 14.2*ones(N,1); clear_dtc = F; lamp_fail = ones(N,4);
