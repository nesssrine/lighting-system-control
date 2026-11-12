function [low_L, low_R, high, position, drl, fog, fmh_active, light_state] = B4_Manager(ignition, sw_pos, flash, hb_toggle, fog_sw, auto_low, ahb_req, lux, vbat, door_closed, degraded, Ts, LUX_ON, T_FMH, T_ARM, T_FMH_STEP, T_FMH_MAX, U_BAT_MIN)
%#codegen
% B4 - Lighting Manager (arbitrage des feux avant) + B8 - Follow-me-home
% sw_pos : 0 OFF, 1 AUTO, 2 POSITION, 3 CROISEMENT      degraded (B6) : 0 aucun, 1 G, 2 D, 3 les deux
persistent init fmh rem tot t_off hb_man fog_st p_ign p_flash p_hb p_fog p_sw
if isempty(init)
    init = true; fmh = false; rem = 0; tot = 0; t_off = 100; hb_man = false; fog_st = false;
    p_ign = ignition; p_flash = flash; p_hb = hb_toggle; p_fog = fog_sw; p_sw = sw_pos;
end
fl_rise = flash && ~p_flash;   hb_rise = hb_toggle && ~p_hb;   fog_rise = fog_sw && ~p_fog;
bat_ok  = vbat >= U_BAT_MIN;

% =============== B8 : FOLLOW-ME-HOME ===============
if p_ign && ~ignition                                   % le conducteur coupe le contact
    t_off = 0;
    if sw_pos == 1 && lux < LUX_ON && T_FMH > 0 && bat_ok   % activation automatique (REQ-LSC-25, 31)
        fmh = true; tot = T_FMH; rem = T_FMH;
    end
end
if ~ignition, t_off = min(t_off + Ts, 1000); end
if fl_rise && ~ignition && bat_ok && (t_off <= T_ARM || fmh)
    if ~fmh, fmh = true; tot = 0; rem = 0; end          % activation manuelle (REQ-LSC-27)
    tot = min(tot + T_FMH_STEP, T_FMH_MAX);             % prolongation (REQ-LSC-28)
    rem = min(rem + T_FMH_STEP, T_FMH_MAX);
end
if fmh
    if ~door_closed
        rem = tot;                                      % porte ouverte : le compteur repart (REQ-LSC-29)
    else
        rem = rem - Ts;
    end
    if rem <= -Ts/2, fmh = false; end                  % duree ecoulee (compteur passe sous 0) : extinction
end
if (ignition && ~p_ign) || (sw_pos ~= p_sw && (sw_pos == 0 || sw_pos == 2)) || ~bat_ok
    fmh = false;                                        % annulation (REQ-LSC-30)
end

% =============== B4 : ARBITRAGE ===============
if fmh                                                  % REQ-LSC-32 : croisement + position seulement
    low = true; hi = false; pos = true; d = false; hb_man = false; fog_st = false;
elseif ignition
    low = (sw_pos == 3) || (sw_pos == 1 && auto_low);   % manuel ou demande de B2 (REQ-LSC-01, 06)
    pos = low || sw_pos == 2;
    if ~low
        hb_man = false;
    elseif hb_rise
        hb_man = ~hb_man;                               % commutation croisement <-> route (REQ-LSC-02)
    end
    hi = (low && (hb_man || (sw_pos == 1 && ahb_req))) || flash;   % manuel > AHB ; appel de phares (REQ-LSC-03, 15)
    d = ~low && sw_pos ~= 2;                            % DRL (REQ-LSC-05)
else
    low = false; hi = false; d = false; hb_man = false;
    pos = sw_pos == 2;                                  % feux de stationnement contact coupe
end
if ~low
    fog_st = false;                                     % antibrouillard impossible sans croisement (REQ-LSC-04)
elseif fog_rise
    fog_st = ~fog_st;
end

low_L = low && ~(degraded == 1 || degraded == 3);       % lampe en defaut : on coupe sa commande (REQ-LSC-24)
low_R = low && ~(degraded == 2 || degraded == 3);
high = hi;  position = pos;  drl = d;  fog = fog_st && low;  fmh_active = fmh;
if fmh, st = 5; elseif hi, st = 4; elseif low, st = 3; elseif pos, st = 2; elseif d, st = 1; else, st = 0; end
light_state = uint8(st);                                % 0 OFF, 1 DRL, 2 POSITION, 3 CROISEMENT, 4 ROUTE, 5 FMH
p_ign = ignition; p_flash = flash; p_hb = hb_toggle; p_fog = fog_sw; p_sw = sw_pos;
