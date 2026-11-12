%% =====================================================================
%  INTEGRATION - Scenarios 2, 3 et 4 (a lancer apres run_int, qui construit le modele)
%  S2 tunnel en plein jour | S3 panne de camera + appel de phares | S4 batterie faible en follow-me-home
% ======================================================================
clc; close all;
addpath(fullfile(pwd,'scripts'));
B1_params; B2_params; B3_params; B4_params; B5_params; B6_params; B7_params;
mdl = 'LSC_Integration';
load_system(mdl);
diary('results\run_INT_scenarios_v2.txt');

%% ---------- SCENARIO 2 : TUNNEL ----------
INT_scenario2;
R = res(sim(mdl, 'StopTime', '40'));
fprintf('\n===== SCENARIO 2 : traversee d''un tunnel en plein jour =====\n');
check('S2-01 Plein jour avant le tunnel : DRL seuls', at(R, R.st, 9), 1, 1);
check('S2-02 REQ-LSC-08 entree de tunnel : croisement <= 0,4 s', firstT(R.st >= 3, R.t, 10) - 10, 0, 0.40);
check('S2-03 Pas de feux de route dans le tunnel (150 lux)', max(R.D(R.t >= 10 & R.t < 20, 3)), 0, 0);
check('S2-04 REQ-LSC-07 sortie : extinction 5 s apres', firstT(R.st < 3, R.t, 20) - 20, 5.0, 5.3);
check('S2-05 Aucun faux defaut lampe', max(R.dtc), 0, 0);
fig(R, t, lux_raw, 'Scenario 2 : traversee d''un tunnel (10-20 s)', [10 20], 'INT_S2_tunnel.png');

%% ---------- SCENARIO 3 : PANNE DE CAMERA ----------
INT_scenario3;
R = res(sim(mdl, 'StopTime', '40'));
fprintf('\n===== SCENARIO 3 : panne de camera et appel de phares =====\n');
check('S3-01 Nuit, 80 km/h : feux de route AHB avant la panne', double(at(R, R.D(:,3), 9) > 0), 1, 1);
check('S3-02 REQ-LSC-14 camera en panne : route coupee <= 0,5 s', firstT(R.D(:,3) == 0, R.t, 10) - 10, 0, 0.50);
check('S3-03 REQ-LSC-14/26 temoin AHB en defaut (etat FAULT = 4)', at(R, R.ah, 12), 4, 4);
check('S3-04 Croisement maintenu pendant la panne', double(at(R, R.D(:,1), 15) > 0), 1, 1);
check('S3-05 Camera revenue : route 2 s apres (REQ-LSC-12)', firstT(R.D(:,3) > 0, R.t, 20) - 20, 1.99, 2.05);
check('S3-06 REQ-LSC-15 appel de phares : route ON, AHB en PAUSE (3)', double(at(R, R.D(:,3), 26.2) > 0 && at(R, R.ah, 26.2) == 3), 1, 1);
check('S3-07 Apres l''appel : AHB reprend 2 s apres le relachement', double(at(R, R.D(:,3), 27) == 0 && at(R, R.D(:,3), 29) > 0), 1, 1);
fig(R, t, lux_raw, 'Scenario 3 : panne de camera (10-20 s) et appel de phares (26 s)', [10 20 26], 'INT_S3_camera.png');

%% ---------- SCENARIO 4 : BATTERIE FAIBLE ----------
INT_scenario4;
R = res(sim(mdl, 'StopTime', '60'));
tc = t(find(vbat < 11.8, 1));
fprintf('\n===== SCENARIO 4 : batterie faible pendant le follow-me-home =====\n');
check('S4-01 Coupure du contact de nuit : follow-me-home actif', double(at(R, R.fm, 10.5)), 1, 1);
check('S4-02 Batterie a 12,6 V : croisement a 100 % (pas de regulation)', at(R, R.D(:,1), 12), 100, 100);
check('S4-03 REQ-LSC-30 annulation quand Vbat < 11,8 V', firstT(~R.fm, R.t, 10.5) - tc, 0, 0.05);
check('S4-04 Tout eteint apres l''annulation', at(R, R.st, 30), 0, 0);
check('S4-05 Pas de reactivation (batterie toujours faible)', double(max(R.fm(R.t >= tc + 0.1))), 0, 0);
check('S4-06 Aucun faux defaut lampe malgre la tension basse', max(R.dtc), 0, 0);
fig(R, t, lux_raw, 'Scenario 4 : batterie faible pendant le follow-me-home', [10 12 tc], 'INT_S4_batterie.png');
subplot(4,1,4); hold on; yyaxis right; plot(t, vbat, 'r', 'LineWidth', 1.3); ylabel('Vbat [V]'); ylim([11 15]);
saveas(gcf, 'INT_S4_batterie.png');
diary off
fprintf('\nFigures : INT_S2_tunnel.png, INT_S3_camera.png, INT_S4_batterie.png\n');

%% ======== fonctions locales ========
function R = res(o)
    R.t = o.O_state.Time;
    R.D = double(squeeze(o.O_duty.Data)); if size(R.D,1) ~= numel(R.t), R.D = R.D.'; end
    R.st = double(squeeze(o.O_state.Data)); R.fm = logical(squeeze(o.O_fmh.Data));
    R.ah = double(squeeze(o.O_ahb.Data)); R.dtc = double(squeeze(o.O_dtc.Data));
    R.lx = double(squeeze(o.O_lux.Data));
end
function v = at(R, x, tq)
    v = x(find(R.t >= tq - 1e-9, 1));
end
function fig(R, t, lux, ttl, marks, fname)
    figure('Color','w','Position',[80 60 950 700]);
    subplot(4,1,1); semilogy(t, max(lux,1), 'Color',[0.6 0.6 0.6], 'LineWidth', 1.1); hold on;
    semilogy(R.t, max(R.lx,1), 'b', 'LineWidth', 1.4); grid on; ylabel('Lux'); legend('brut','filtre (B1)','Location','eastoutside','AutoUpdate','off');
    title(['INTEGRATION - ' ttl]);
    subplot(4,1,2); stairs(R.t, R.st, 'k', 'LineWidth', 1.4); yticks(0:5);
    yticklabels({'OFF','DRL','POSITION','CROIS.','ROUTE','FMH'}); ylim([-0.3 5.3]); grid on;
    subplot(4,1,3); plot(R.t, R.D(:,1), 'b', R.t, R.D(:,3), 'm', 'LineWidth', 1.3); ylim([-5 105]); grid on; ylabel('PWM [%]');
    legend('Croisement','Route','Location','eastoutside','AutoUpdate','off');
    subplot(4,1,4); stairs(R.t, R.ah, 'Color',[0 .5 0], 'LineWidth', 1.3); yticks(0:4);
    yticklabels({'OFF','READY','ACTIVE','PAUSE','FAULT'}); ylim([-0.3 4.3]); grid on; ylabel('Etat AHB'); xlabel('Temps [s]');
    for k = 1:4, subplot(4,1,k); xline(marks, 'r:'); end
    saveas(gcf, fname);
end
function tf = firstT(cond, tt, tmin)
    i = find(cond & tt >= tmin - 1e-9, 1);
    if isempty(i), tf = NaN; else, tf = tt(i); end
end
function check(nom, val, vmin, vmax)
    if ~isnan(val) && val >= vmin - 1e-9 && val <= vmax + 1e-9
        fprintf('  [PASS] %-66s mesure = %.3f\n', nom, val);
    else
        fprintf('  [FAIL] %-66s mesure = %.3f (attendu %.3f..%.3f)\n', nom, val, vmin, vmax);
    end
end
