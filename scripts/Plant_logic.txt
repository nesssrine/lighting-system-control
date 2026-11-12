function lamp_cur = Plant_Lamps(duty, vbat, lamp_fail, I_NOM)
%#codegen
% MODELE DE L'ENVIRONNEMENT (pas du logiciel embarque) : courant moyen consomme par 4 lampes
% lampes surveillees : voie 1 croisement G, 2 croisement D, 5 clignotant G, 6 clignotant D
% lamp_fail : 1 lampe normale, 0 lampe grillee, 2 court-circuit partiel
d = double(duty(:)) / 100;
idx = [1; 2; 5; 6];
lamp_cur = I_NOM(:) .* d(idx) * (vbat / 13.5) .* lamp_fail(:);
