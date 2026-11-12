function [high_beam, ahb_state] = AHB_Logic(auto_mode, ahb_switch, low_beam_on, speed, lux, vehicle_detected, cam_ok, manual_override, Ts, V_AHB_ON, V_AHB_OFF, LUX_AHB, T_REARM)
%#codegen
% B3 - Auto High Beam (AHB) : feux de route automatiques
% ahb_state : 0 = OFF (non disponible), 1 = READY (disponible, route non libre)
%             2 = ACTIVE (feux de route), 3 = PAUSE (action manuelle), 4 = FAULT (camera)
persistent spd_ok clear_cnt hb
if isempty(spd_ok)
    spd_ok = false; clear_cnt = 0; hb = false;
end
% --- Hysteresis de vitesse (REQ-LSC-13) : ON a 40 km/h, OFF sous 30 km/h
if speed >= V_AHB_ON
    spd_ok = true;
elseif speed < V_AHB_OFF
    spd_ok = false;
end
% --- Conditions de disponibilite (REQ-LSC-10)
avail = auto_mode && ahb_switch && low_beam_on && spd_ok && (lux < LUX_AHB);

if ~cam_ok                          % camera en defaut -> etat sur (REQ-LSC-14)
    hb = false; clear_cnt = 0; st = 4;
elseif manual_override              % le conducteur est prioritaire (REQ-LSC-15)
    hb = false; clear_cnt = 0; st = 3;
elseif ~avail                       % conditions non reunies
    hb = false; clear_cnt = 0; st = 0;
elseif vehicle_detected             % usager detecte -> croisement immediat (REQ-LSC-11)
    hb = false; clear_cnt = 0; st = 1;
else                                % route libre : confirmation pendant T_REARM (REQ-LSC-12)
    clear_cnt = min(clear_cnt + Ts, 100);
    if clear_cnt > T_REARM + Ts/2
        hb = true;
    end
    if hb
        st = 2;
    else
        st = 1;
    end
end
high_beam = hb;
ahb_state = uint8(st);
