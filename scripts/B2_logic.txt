function low_beam = AutoHeadlampLogic(lux, auto_mode, lux_valid, Ts, LUX_ON, LUX_OFF, T_ON, T_OFF, T_TUNNEL)
%#codegen
% B2 - Auto Headlamp : allumage/extinction automatique avec hysteresis
persistent st cnt buf idx          % memoire conservee d'un pas a l'autre
N = 50;                            % 50 x 10 ms = 0,5 s d'historique
if isempty(st)                     % initialisation au 1er pas
    st = false; cnt = 0; buf = 10000*ones(1, N); idx = 1;
end
% --- Detection tunnel : chute > 80 % en 0,5 s
lux_past = buf(idx);
buf(idx) = lux;
idx = mod(idx, N) + 1;
tunnel = (lux < 0.2*lux_past) && (lux < LUX_ON);

% --- Logique principale
if ~auto_mode
    st = false; cnt = 0;           % pas en AUTO : B2 ne demande rien
elseif ~lux_valid
    st = true;  cnt = 0;           % capteur en defaut : etat sur
elseif ~st                         % feux eteints
    if lux < LUX_ON
        cnt = cnt + Ts;
        if (cnt > T_ON + Ts/2) || (tunnel && cnt > T_TUNNEL + Ts/2)
            st = true; cnt = 0;
        end
    else
        cnt = 0;                   % condition interrompue -> on recommence
    end
else                               % feux allumes
    if lux > LUX_OFF
        cnt = cnt + Ts;
        if cnt > T_OFF + Ts/2
            st = false; cnt = 0;
        end
    else
        cnt = 0;
    end
end
low_beam = st;
