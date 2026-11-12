%% B7 - Verification (a lancer apres Run)
tt = out.dutyO.Time; D = double(squeeze(out.dutyO.Data)); if size(D,1) ~= numel(tt), D = D.'; end
ve = double(squeeze(out.veffO.Data)); at = @(x, tq) x(find(tt >= tq - 1e-9, 1), :);
fprintf('Croisement : PWM a 1,05 s / 2 s       : %d %% / %d %%  (attendu < 70 / 84)\n', at(D(:,1),1.05), at(D(:,1),2));
fprintf('Tension efficace a 14,4 V / 13,8 V     : %.2f V / %.2f V (attendu 13,2)\n', at(ve,2), at(ve,5.5));
fprintf('PWM a 12,5 V batterie                 : %d %%  (attendu 100)\n', at(D(:,1),4.5));
fprintf('LED avant : DRL / veilleuse            : %d %% / %d %% (attendu 100 / 30)\n', at(D(:,4),0.5), at(D(:,4),2));
fprintf('LED arriere : position / stop          : %d %% / %d %% (attendu 20 / 100)\n', at(D(:,7),5.9), at(D(:,7),6.5));
