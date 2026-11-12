%% B8 - Verification du scenario 2 (a lancer apres Run avec Stop time = 55)
tt = out.lowL.Time; lo = logical(squeeze(out.lowL.Data)); fm = logical(squeeze(out.fmhO.Data)); hi = logical(squeeze(out.highB.Data));
fprintf('Croisement maintenu a la coupure (4,9-6 s) : %d      (attendu 1)\n', min(lo(tt >= 4.9 & tt <= 6)));
fprintf('Feux de route pendant le FMH              : %d      (attendu 0)\n', max(hi(tt >= 5.05 & tt <= 39)));
fprintf('Extinction apres fermeture porte (10 s)   : %.2f s (attendu 30,00)\n', tt(find(~lo & tt >= 5.5, 1)) - 10);
fprintf('FMH annule par le commodo a 46 s          : %d      (attendu 1)\n', ~fm(find(tt >= 46.05, 1)));
fprintf('FMH annule par la batterie a 52 s apres   : %.2f s (attendu 0,00)\n', tt(find(~fm & tt >= 50, 1)) - 52);
