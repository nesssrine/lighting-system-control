%% B6 - Verification du scenario 1 (a lancer apres Run)
tt = out.faultAct.Time; fa = squeeze(out.faultAct.Data); if size(fa,1) ~= numel(tt), fa = fa.'; end
dtc = double(squeeze(out.dtcStored.Data)); dg = double(squeeze(out.degradedMode.Data));
fprintf('Fausses detections avant 5 s          : %d      (attendu 0)\n', any(any(fa(tt < 4.99,:))));
fprintf('Croisement D grille detecte apres     : %.2f s (attendu <= 0,20)\n', tt(find(fa(:,2) & tt >= 5, 1)) - 5);
fprintf('Court-circuit croisement G apres      : %.2f s (attendu <= 0,20)\n', tt(find(fa(:,1) & tt >= 12, 1)) - 12);
fprintf('Mode degrade a 13 s                   : %d      (attendu 3)\n', dg(find(tt >= 13, 1)));
fprintf('Guerison croisement D apres 15 s      : %.2f s (attendu 1,00)\n', tt(find(~fa(:,2) & tt >= 15, 1)) - 15);
fprintf('DTC memorises a 17 s / apres effacement : %d / %d (attendu 22 / 20)\n', dtc(find(tt >= 17,1)), dtc(find(tt >= 19,1)));
