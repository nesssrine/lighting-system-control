%% B5 - Parametres calibrables (cahier des charges, section 4.4)
Ts        = 0.01;   % periode d'execution [s]
F_BLINK   = 1.5;    % frequence des clignotants [Hz]           REQ-LSC-16
F_HYPER   = 3;      % frequence si lampe grillee [Hz]          REQ-LSC-23
T_SHORT   = 0.5;    % impulsion courte = mode autoroute [s]    REQ-LSC-17
N_COMFORT = 3;      % nombre de clignotements en mode autoroute
A_ESS_ON  = 6;      % deceleration d'activation ESS [m/s2]     REQ-LSC-20
A_ESS_OFF = 2.5;    % deceleration de fin ESS [m/s2]
V_ESS     = 50;     % vitesse minimale pour l'ESS [km/h]
F_ESS     = 4;      % frequence de clignotement des feux stop en ESS [Hz]
V_RESUME  = 10;     % vitesse d'extinction des detresses automatiques [km/h]  REQ-LSC-21
disp('Parametres B5 charges.')
