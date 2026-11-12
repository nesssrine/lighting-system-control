%% B6 - Parametres calibrables (cahier des charges : REQ-LSC-22, 23, 24)
Ts       = 0.01;                 % periode d'execution [s]
I_NOM    = [4.1; 4.1; 1.6; 1.6]; % courant nominal [A] : croisement 55 W, clignotant 21 W (13,5 V)
R_OPEN   = 0.2;                  % seuil lampe grillee : < 20 % du nominal
R_SHORT  = 1.5;                  % seuil court-circuit : > 150 % du nominal
T_INRUSH = 0.05;                 % masquage du pic d'allumage [s]
T_CONF   = 0.1;                  % confirmation d'un defaut [s]
T_HEAL   = 1.0;                  % mesures correctes avant de declarer le defaut gueri [s]
disp('Parametres B6 charges.')
