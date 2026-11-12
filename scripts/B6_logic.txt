function [fault_act, dtc_stored, degraded, warning] = B6_Diag(lamp_cmd, lamp_cur, clear_dtc, Ts, I_NOM, R_OPEN, R_SHORT, T_INRUSH, T_CONF, T_HEAL)
%#codegen
% B6 - Diagnostic des lampes par mesure du courant
% Lampes : 1 croisement G, 2 croisement D, 3 clignotant G, 4 clignotant D
% dtc_stored : bits 0-3 = circuit ouvert (lampe grillee), bits 4-7 = court-circuit
persistent ton tbo tbs tgood fo fs stored
if isempty(ton)
    ton = zeros(4,1); tbo = zeros(4,1); tbs = zeros(4,1); tgood = zeros(4,1);
    fo = false(4,1); fs = false(4,1); stored = uint16(0);
end
cmd = logical(lamp_cmd(:));  cur = lamp_cur(:);
for i = 1:4
    if cmd(i)
        ton(i) = min(ton(i) + Ts, 100);           % temps depuis l'allumage
    else
        ton(i) = 0;
    end
    if cmd(i) && ton(i) > T_INRUSH + Ts/2         % on ne juge qu'apres le pic d'allumage
        r = cur(i) / I_NOM(i);                    % courant mesure / courant nominal
        bad_open  = r < R_OPEN;                   % < 20 % : lampe grillee (REQ-LSC-22)
        bad_short = r > R_SHORT;                  % > 150 % : court-circuit (REQ-LSC-22)
        if bad_open,  tbo(i) = tbo(i) + Ts; else, tbo(i) = 0; end
        if bad_short, tbs(i) = tbs(i) + Ts; else, tbs(i) = 0; end
        if tbo(i) > T_CONF + Ts/2                 % confirmation 100 ms
            fo(i) = true; stored = bitor(stored, bitshift(uint16(1), i-1));
        end
        if tbs(i) > T_CONF + Ts/2
            fs(i) = true; stored = bitor(stored, bitshift(uint16(1), i+3));
        end
        if ~bad_open && ~bad_short                % mesure correcte : guerison
            tgood(i) = min(tgood(i) + Ts, 100);
            if tgood(i) > T_HEAL + Ts/2
                fo(i) = false; fs(i) = false;     % defaut plus actif (le DTC reste memorise)
            end
        else
            tgood(i) = 0;
        end
    else
        tbo(i) = 0; tbs(i) = 0;                   % lampe eteinte : on ne peut pas juger
    end
end
act = fo | fs;
if clear_dtc                                      % effacement par l'outil de diagnostic
    stored = uint16(0);
    for i = 1:4
        if fo(i), stored = bitor(stored, bitshift(uint16(1), i-1)); end
        if fs(i), stored = bitor(stored, bitshift(uint16(1), i+3)); end
    end
end
fault_act  = act;
dtc_stored = stored;
degraded   = uint8(act(1)) + 2*uint8(act(2));     % 0 aucun, 1 croisement G, 2 croisement D, 3 les deux (REQ-LSC-24)
warning    = any(act);                            % temoin defaut au tableau de bord
