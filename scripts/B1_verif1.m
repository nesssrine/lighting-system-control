%% B1 - Verification du scenario 1 (a lancer apres Run)
yf = squeeze(out.luxFilt.Data); v = logical(squeeze(out.luxValid.Data)); tt = out.luxFilt.Time;
w = tt >= 6 & tt <= 11;
fprintf('Bruit : ecart-type filtre / brut       : %.2f   (attendu < 0,30)\n', std(yf(w))/std(lux(w)));
fprintf('Defaut hors plage apres 12 s          : %.2f s (attendu 0,00)\n', tt(find(~v & tt >= 12,1)) - 12);
fprintf('Retour a la normale apres 12,5 s      : %.2f s (attendu 1,00)\n', tt(find(v & tt >= 12.5,1)) - 12.5);
fprintf('Absence courte 18-18,3 s toleree      : %d      (attendu 1)\n', min(v(tt >= 17.9 & tt <= 19.5)));
fprintf('Defaut absence apres 22 s             : %.2f s (attendu 0,50)\n', tt(find(~v & tt >= 22,1)) - 22);
fprintf('Retour apres 23 s                     : %.2f s (attendu 1,00)\n', tt(find(v & tt >= 23,1)) - 23);
