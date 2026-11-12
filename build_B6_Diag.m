%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  BLOC   : B6 - Diagnostic des lampes (mesure du courant, DTC, mode degrade)
%  Exigences couvertes : REQ-LSC-22, REQ-LSC-23 (information vers B5), REQ-LSC-24
%  Auteur : Amina Borcheni - MATLAB/Simulink R2022b
% ======================================================================
clear; clc; close all;
addpath(fullfile(pwd,'scripts'));
B6_params;

%% 1) Construction du modele
mdl = 'B6_Diag';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts', 'StopTime','20');
fcn = [mdl '/B6_Logic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fcn, 'Position', [330 60 540 330]);
rt = sfroot; ch = rt.find('-isa','Stateflow.EMChart','Path',fcn);
ch.Script = fileread(fullfile(pwd,'scripts','B6_logic.txt'));
for nm = {'Ts','I_NOM','R_OPEN','R_SHORT','T_INRUSH','T_CONF','T_HEAL'}
    d = ch.find('-isa','Stateflow.Data','Name',nm{1}); d.Scope = 'Parameter';
end
ins = {'LampCmd','cmdSig',true; 'LampCurrent','curSig',false; 'ClearDTC','clrSig',true};
for k = 1:3
    b = [mdl '/' ins{k,1}]; y = 80 + (k-1)*90;
    add_block('simulink/Sources/From Workspace', b, 'VariableName', ins{k,2}, 'SampleTime','Ts', ...
              'OutputAfterFinalValue','Holding final value', 'Position', [60 y 170 y+28]);
    if ins{k,3}, set_param(b,'Interpolate','off'); end
    add_line(mdl, [ins{k,1} '/1'], sprintf('B6_Logic/%d',k), 'autorouting','on');
end
outs = {'faultAct','LampFault'; 'dtcStored','DTC_Status'; 'degradedMode','DegradedMode'; 'warningLamp','WarningLamp'};
for k = 1:4
    y = 50 + (k-1)*80;
    add_block('simulink/Sinks/To Workspace', [mdl '/' outs{k,1} 'Log'], 'VariableName', outs{k,1}, ...
              'SaveFormat','Timeseries', 'Position', [650 y 750 y+28]);
    add_block('simulink/Sinks/Out1', [mdl '/' outs{k,2}], 'Position', [650 y+40 680 y+54]);
    add_line(mdl, sprintf('B6_Logic/%d',k), [outs{k,1} 'Log/1'], 'autorouting','on');
    add_line(mdl, sprintf('B6_Logic/%d',k), [outs{k,2} '/1'], 'autorouting','on');
end
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts','4', 'Position', [880 120 930 300]);
add_line(mdl,'LampCurrent/1','Scope/1','autorouting','on');
add_line(mdl,'B6_Logic/1','Scope/2','autorouting','on');
add_line(mdl,'B6_Logic/3','Scope/3','autorouting','on');
add_line(mdl,'B6_Logic/2','Scope/4','autorouting','on');
c = get_param([mdl '/Scope'],'ScopeConfiguration'); c.LayoutDimensions = [4 1];
save_system(mdl);
fprintf('Modele %s.slx cree.\n\n', mdl);

%% 2) SCENARIO 1
B6_scenario1; close(gcf);
out = sim(mdl);
[fa, tt] = vec(out.faultAct); fa = logical(fa);
dtc = vec(out.dtcStored); dg = vec(out.degradedMode); wl = logical(vec(out.warningLamp));
at = @(x, tq) x(find(tt >= tq - 1e-9, 1), :);
fprintf('===== SCENARIO 1 : pannes de lampes =====\n');
check('Aucune fausse detection 0-5 s (pics d''allumage, micro-coupure)', double(any(any(fa(tt < 4.99,:)))), 0, 0);
check('REQ-LSC-22 croisement D grille : detection <= 200 ms', firstT(fa(:,2), tt, 5) - 5, 0, 0.20);
check('REQ-LSC-24 mode degrade = 2 (croisement D)', at(dg, 5.5), 2, 2);
check('Temoin defaut allume', double(at(wl, 5.5)), 1, 1);
tr = t(find(cmd(:,3) & ~[false; cmd(1:end-1,3)] & t >= 9, 1));
check('REQ-LSC-22 clignotant G grille : <= 200 ms apres allumage', firstT(fa(:,3), tt, 9) - tr, 0, 0.20);
check('REQ-LSC-23 information lampe grillee vers B5 (fault_L)', double(at(fa(:,3), 10)), 1, 1);
check('REQ-LSC-22 court-circuit croisement G : <= 200 ms', firstT(fa(:,1), tt, 12) - 12, 0, 0.20);
check('REQ-LSC-24 mode degrade = 3 (les deux croisements)', at(dg, 13), 3, 3);
check('Guerison croisement D repare : 1 s apres', firstT(~fa(:,2), tt, 15) - 15, 1.00, 1.03);
check('DTC memorise malgre la guerison (bits 1+2+4 = 22)', at(dtc, 17), 22, 22);
check('Effacement DTC : ne garde que les defauts actifs (20)', at(dtc, 19), 20, 20);

%% 3) Courbes
figure('Name','B6 - Scenario 1','Color','w','Position',[100 60 950 760]);
subplot(4,1,1); plot(t, cur, 'LineWidth', 1); ylim([0 10]); grid on; ylabel('Courant [A]');
legend('Croisement G','Croisement D','Clignotant G','Clignotant D','Location','eastoutside','AutoUpdate','off');
title('B6 - Scenario 1 : diagnostic des lampes');
subplot(4,1,2); stairs(tt, double(fa) + [0 1.2 2.4 3.6], 'LineWidth', 1.4); grid on; ylim([-0.2 4.8]);
yticks([0.5 1.7 2.9 4.1]); yticklabels({'Crois. G','Crois. D','Clign. G','Clign. D'}); ylabel('Defaut actif');
subplot(4,1,3); stairs(tt, dg, 'k', 'LineWidth', 1.4); ylim([-0.3 3.3]); yticks(0:3);
yticklabels({'aucun','crois. G','crois. D','les deux'}); grid on; ylabel('Mode degrade');
subplot(4,1,4); stairs(tt, dtc, 'Color', [0.7 0 0.5], 'LineWidth', 1.4); grid on; ylabel('DTC memorises'); xlabel('Temps [s]');
for k = 1:4, subplot(4,1,k); xline([3 5 9 12 15 18], ':'); end
saveas(gcf, 'B6_scenario1.png');
fprintf('\nFigure enregistree : B6_scenario1.png\n');

%% ---- fonctions locales
function [v, tt] = vec(ts)
    v = double(squeeze(ts.Data)); tt = ts.Time;
    if size(v,1) ~= numel(tt), v = v.'; end
end
function tf = firstT(cond, tt, tmin)
    i = find(cond & tt >= tmin - 1e-9, 1);
    if isempty(i), tf = NaN; else, tf = tt(i); end
end
function check(nom, val, vmin, vmax)
    if ~isnan(val) && val >= vmin - 1e-9 && val <= vmax + 1e-9
        fprintf('  [PASS] %-62s mesure = %.3f\n', nom, val);
    else
        fprintf('  [FAIL] %-62s mesure = %.3f (attendu %.3f..%.3f)\n', nom, val, vmin, vmax);
    end
end
