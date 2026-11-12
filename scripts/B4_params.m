%% B4 + B8 - Parametres calibrables (cahier des charges, sections 4.1, 4.2, 4.6)
Ts         = 0.01;   % periode d'execution [s]
LUX_ON     = 1000;   % il fait nuit sous ce seuil [lux]
T_FMH      = 30;     % duree du follow-me-home (0 = desactive) [s]   REQ-LSC-25
T_ARM      = 10;     % fenetre d'activation manuelle apres coupure [s] REQ-LSC-27
T_FMH_STEP = 30;     % ajout par appel de phares [s]                  REQ-LSC-28
T_FMH_MAX  = 120;    % duree maximale [s]
U_BAT_MIN  = 11.8;   % tension batterie minimale [V]                  REQ-LSC-30
disp('Parametres B4/B8 charges.')
