%% B3 - Verification du scenario 1 (a lancer apres Run)
hb = logical(squeeze(out.highBeam.Data));  tt = out.highBeam.Time;
t40 = t(find(spd >= 40, 1));
t30 = t(find(spd < 30 & t > 45, 1));
fprintf('Activation apres 40 km/h        : %.2f s (attendu 2,00)\n', tt(find(hb,1)) - t40);
fprintf('Coupure apres detection (20 s)  : %.2f s (attendu <= 0,30)\n', tt(find(~hb & tt > 20,1)) - 20);
fprintf('Reactivation apres 25 s         : %.2f s (attendu 2,00)\n', tt(find(hb & tt > 25,1)) - 25);
fprintf('Rallumages entre 30 et 41,1 s   : %d   (attendu 0)\n', sum(diff(double(hb(tt>=30 & tt<=41.1)))>0));
fprintf('Feux de route a 52 s (35 km/h)  : %d   (attendu 1)\n', hb(find(tt>=52,1)));
fprintf('Coupure sous 30 km/h            : %.2f s (attendu 0,00)\n', tt(find(~hb & tt > 45,1)) - t30);
