%% B1 - Parametres calibrables (cahier des charges : NFR-04, REQ-LSC-09, REQ-LSC-02)
Ts        = 0.01;     % periode d'execution [s]
TAU_LUX   = 0.2;      % constante de temps du filtre de luminosite [s]
LUX_MAX   = 100000;   % valeur maximale plausible du capteur [lux]
T_ABSENT  = 0.5;      % absence de message avant defaut [s]
T_RECOVER = 1.0;      % mesures correctes avant retour a la normale [s]
T_DEB     = 0.05;     % anti-rebond des commandes conducteur [s]
disp('Parametres B1 charges.')
