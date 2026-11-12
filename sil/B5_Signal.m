function [blink_L, blink_R, brake_light, hazard_active, ess_active] = B5_Signal(ignition, turn_left, turn_right, hazard_sw, brake_pedal, speed, decel, fault_L, fault_R, Ts, F_BLINK, F_HYPER, T_SHORT, N_COMFORT, A_ESS_ON, A_ESS_OFF, V_ESS, F_ESS, V_RESUME)
%#codegen
% B5 - Clignotants, feux de detresse, feux stop et signal de freinage d'urgence (ESS)
% decel : deceleration longitudinale [m/s2], positive quand le vehicule freine
persistent init tside comfort press_t prevL prevR prev_req ph cyc ess ph_ess ess_seen auto_haz
if isempty(init)
    init = true; tside = 0; comfort = false; press_t = 0; prevL = false; prevR = false;
    prev_req = 0; ph = 0; cyc = 0; ess = false; ph_ess = 0; ess_seen = false; auto_haz = false;
end

% ---------- 1) Signal de freinage d'urgence ESS (REQ-LSC-20)
if ~ess && brake_pedal && decel > A_ESS_ON && speed > V_ESS
    ess = true; ph_ess = 0; ess_seen = true;          % freinage d'urgence detecte
elseif ess && (decel < A_ESS_OFF || ~brake_pedal)
    ess = false;                                       % fin du freinage d'urgence
end

% ---------- 2) Feux de detresse automatiques apres arret d'urgence (REQ-LSC-21)
if ess_seen && speed < 0.5
    auto_haz = true; ess_seen = false;
end
if auto_haz && speed > V_RESUME
    auto_haz = false;                                  % le vehicule repart
end
hazard = hazard_sw || auto_haz;

% ---------- 3) Demande de clignotement : 0 aucun, 1 gauche, 2 droite, 3 detresse
if hazard
    req = 3;                                           % detresse prioritaire, meme contact coupe (REQ-LSC-18)
    tside = 0; comfort = false;
elseif ignition
    if turn_left && ~prevL                             % debut d'appui a gauche
        tside = 1; press_t = 0; comfort = false;
    elseif turn_right && ~prevR                        % debut d'appui a droite
        tside = 2; press_t = 0; comfort = false;
    end
    if (tside == 1 && turn_left) || (tside == 2 && turn_right)
        press_t = press_t + Ts;                        % duree d'appui
    end
    if (tside == 1 && ~turn_left && prevL) || (tside == 2 && ~turn_right && prevR)
        if press_t < T_SHORT
            comfort = true;                            % impulsion courte : mode autoroute (REQ-LSC-17)
        else
            tside = 0;                                 % levier relache : arret
        end
    end
    if comfort && cyc >= N_COMFORT
        tside = 0; comfort = false;                    % 3 cycles effectues
    end
    req = tside;
else
    req = 0; tside = 0; comfort = false;
end
prevL = turn_left; prevR = turn_right;

% ---------- 4) Generateur de clignotement (REQ-LSC-16, hyper-clignotement REQ-LSC-23)
if (req == 1 && fault_L) || (req == 2 && fault_R) || (req == 3 && (fault_L || fault_R))
    period = 1 / F_HYPER;                              % lampe grillee : frequence doublee
else
    period = 1 / F_BLINK;
end
if req ~= prev_req
    ph = 0; cyc = 0;                                   % nouvelle demande : on repart d'un flash allume
end
prev_req = req;
on = false;
if req > 0
    on = ph < period / 2;                              % rapport cyclique 50 %
    ph = ph + Ts;
    if ph >= period - 1e-9
        ph = ph - period; cyc = cyc + 1;               % un cycle complet
    end
end
blink_L = on && (req == 1 || req == 3);
blink_R = on && (req == 2 || req == 3);

% ---------- 5) Feux stop (REQ-LSC-19) et clignotement ESS
if ess
    brake_light = ph_ess < 0.5 / F_ESS;
    ph_ess = ph_ess + Ts;
    if ph_ess >= 1 / F_ESS - 1e-9, ph_ess = ph_ess - 1 / F_ESS; end
else
    brake_light = brake_pedal;                         % allumage direct a l'appui
end
hazard_active = hazard;
ess_active = ess;
