%% B5 - Verification du scenario 1 (a lancer apres Run)
bL = logical(squeeze(out.blinkL.Data)); bR = logical(squeeze(out.blinkR.Data)); tt = out.blinkL.Time;
eL = tt(find(diff([false; bL]) > 0)); eR = tt(find(diff([false; bR]) > 0));
p1 = mean(diff(eL(eL >= 1 & eL <= 5)));  p2 = mean(diff(eL(eL >= 12 & eL <= 16)));
fprintf('Periode clignotant gauche 1-5 s   : %.3f s -> %.2f Hz (attendu 1,5 Hz)\n', p1, 1/p1);
fprintf('Rapport cyclique                  : %.2f       (attendu 0,50)\n', mean(bL(tt >= 1 & tt < 4.99)));
fprintf('Flashs a droite (impulsion 0,2 s) : %d          (attendu 3)\n', sum(eR >= 6.9 & eR <= 10));
fprintf('Periode avec lampe grillee        : %.3f s -> %.2f Hz (attendu 3 Hz)\n', p2, 1/p2);
fprintf('Detresse : gauche = droite        : %d          (attendu 1)\n', all(bL(tt >= 17) == bR(tt >= 17)));
