function [lux_filt, lux_valid, sw_pos, flash_req] = B1_Acquisition(lux_raw, msg_ok, sw_raw, flash_raw, Ts, TAU_LUX, LUX_MAX, T_ABSENT, T_RECOVER, T_DEB)
%#codegen
% B1 - Acquisition et filtrage des entrees
%   lux_raw   : mesure brute du capteur de luminosite [lux]
%   msg_ok    : 1 si le message du capteur est recu a ce pas (bus CAN)
%   sw_raw    : position brute du commodo (0 OFF, 1 AUTO, 2 POSITION, 3 CROISEMENT)
%   flash_raw : contact brut du levier d'appel de phares
persistent init yf valid absent_cnt good_cnt sw_last sw_cnt sw_out fl_last fl_cnt fl_out
if isempty(init)
    init = true; yf = lux_raw; valid = true; absent_cnt = 0; good_cnt = 0;
    sw_last = sw_raw; sw_cnt = 0; sw_out = sw_raw;
    fl_last = flash_raw; fl_cnt = 0; fl_out = flash_raw;
end

% ---------- 1) Diagnostic du capteur de luminosite (REQ-LSC-09)
in_range = (lux_raw >= 0) && (lux_raw <= LUX_MAX);
if msg_ok
    absent_cnt = 0;
else
    absent_cnt = min(absent_cnt + Ts, 100);
end
absent = absent_cnt > T_ABSENT + Ts/2;          % message absent depuis plus de 500 ms
if ~in_range || absent
    valid = false; good_cnt = 0;                % defaut detecte immediatement
elseif msg_ok
    good_cnt = min(good_cnt + Ts, 100);
    if good_cnt > T_RECOVER + Ts/2              % retour a la normale apres 1 s de mesures correctes
        valid = true;
    end
end

% ---------- 2) Filtre passe-bas du 1er ordre (NFR-04), fige si mesure non fiable
if in_range && msg_ok
    if lux_raw < 0.2 * yf                       % chute brutale > 80 % (entree de tunnel) :
        yf = lux_raw;                           % suivi immediat, sinon le filtre retarde B2 (REQ-LSC-08)
    else
        a = Ts / (TAU_LUX + Ts);
        yf = yf + a * (lux_raw - yf);
    end
end

% ---------- 3) Anti-rebond du commodo (NFR-04 / REQ-LSC-02)
if sw_raw ~= sw_last
    sw_last = sw_raw; sw_cnt = 0;               % la position bouge : on recommence
else
    sw_cnt = min(sw_cnt + Ts, 100);
    if sw_cnt > T_DEB - Ts/2
        sw_out = sw_raw;                        % stable depuis 50 ms : on valide
    end
end

% ---------- 4) Anti-rebond de l'appel de phares
if flash_raw ~= fl_last
    fl_last = flash_raw; fl_cnt = 0;
else
    fl_cnt = min(fl_cnt + Ts, 100);
    if fl_cnt > T_DEB - Ts/2
        fl_out = flash_raw;
    end
end

lux_filt  = yf;
lux_valid = valid;
sw_pos    = sw_out;
flash_req = fl_out;
