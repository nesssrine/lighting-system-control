%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  BLOC   : B7 - Pilotage des sorties (PWM, soft-start, regulation de tension, LED a 2 niveaux)
%  Exigences couvertes : NFR (pilotage), REQ-LSC-05 (DRL / veilleuse), REQ-LSC-16 et 19 (signalisation)
%  Auteur : Amina Borcheni - MATLAB/Simulink R2022b
% ======================================================================
clear; clc; close all;
addpath(fullfile(pwd,'scripts'));
B7_params;
mdl = 'B7_Driver';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts', 'StopTime','10');
fcn = [mdl '/B7_Logic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fcn, 'Position', [330 40 540 620]);
rt = sfroot; ch = rt.find('-isa','Stateflow.EMChart','Path',fcn);
ch.Script = fileread(fullfile(pwd,'scripts','B7_logic.txt'));
for nm = {'Ts','V_EFF','T_SOFT','POS_DIM','TAIL_DIM'}
    d = ch.find('-isa','Stateflow.Data','Name',nm{1}); d.Scope = 'Parameter';
end
ins = {'LowBeamLeft','lLSig',true; 'LowBeamRight','lRSig',true; 'HighBeam','hiSig',true; 'PositionLamps','posSig',true; ...
       'DRL','drlSig',true; 'RearFog','fgSig',true; 'TurnLampLeft','bLSig',true; 'TurnLampRight','bRSig',true; ...
       'BrakeLamp','brSig',true; 'BatteryVoltage','vbSig',false};
for k = 1:size(ins,1)
    b = [mdl '/' ins{k,1}]; y = 45 + (k-1)*57;
    add_block('simulink/Sources/From Workspace', b, 'VariableName', ins{k,2}, 'SampleTime','Ts', ...
              'OutputAfterFinalValue','Holding final value', 'Position', [60 y 160 y+26]);
    if ins{k,3}, set_param(b,'Interpolate','off'); end
    add_line(mdl, [ins{k,1} '/1'], sprintf('B7_Logic/%d',k), 'autorouting','on');
end
outs = {'dutyO','PWM_Duty'; 'veffO','Veff_LowBeam'; 'diagO','LampCmd_B6'};
for k = 1:3
    y = 100 + (k-1)*160;
    add_block('simulink/Sinks/To Workspace', [mdl '/' outs{k,1} 'Log'], 'VariableName', outs{k,1}, ...
              'SaveFormat','Timeseries', 'Position', [660 y 760 y+28]);
    add_block('simulink/Sinks/Out1', [mdl '/' outs{k,2}], 'Position', [660 y+45 690 y+59]);
    add_line(mdl, sprintf('B7_Logic/%d',k), [outs{k,1} 'Log/1'], 'autorouting','on');
    add_line(mdl, sprintf('B7_Logic/%d',k), [outs{k,2} '/1'], 'autorouting','on');
end
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts','3', 'Position', [880 200 930 360]);
add_line(mdl,'B7_Logic/1','Scope/1','autorouting','on');
add_line(mdl,'B7_Logic/2','Scope/2','autorouting','on');
add_line(mdl,'BatteryVoltage/1','Scope/3','autorouting','on');
c = get_param([mdl '/Scope'],'ScopeConfiguration'); c.LayoutDimensions = [3 1];
save_system(mdl);
fprintf('Modele %s.slx cree.\n\n', mdl);

B7_scenario1; close(gcf);
o = sim(mdl);
tt = o.dutyO.Time; D = double(squeeze(o.dutyO.Data)); if size(D,1) ~= numel(tt), D = D.'; end
ve = double(squeeze(o.veffO.Data)); dg = logical(squeeze(o.diagO.Data)); if size(dg,1) ~= numel(tt), dg = dg.'; end
at = @(x, tq) x(find(tt >= tq - 1e-9, 1), :);
fprintf('===== SCENARIO 1 : pilotage des sorties =====\n');
check('Soft-start : croisement progressif (a 1,05 s < 70 %)', at(D(:,1), 1.05), 1, 69);
check('Soft-start : plein regime atteint en 0,1 s', firstT(D(:,1) >= 84, tt, 1) - 1, 0.09, 0.11);
check('Regulation : rapport cyclique a 14,4 V = 84 %', at(D(:,1), 2), 84, 84);
check('Regulation : tension efficace = 13,2 V (14,4 V batterie)', at(ve, 2), 13.1, 13.3);
check('Batterie faible 12,5 V : 100 % (pas de surtension possible)', at(D(:,1), 4.5), 100, 100);
check('Regulation : tension efficace = 13,2 V (13,8 V batterie)', at(ve, 5.5), 13.1, 13.3);
check('REQ-LSC-05 LED avant : DRL 100 % puis veilleuse 30 %', double(at(D(:,4),0.5) == 100 && at(D(:,4),2) == 30), 1, 1);
check('LED arriere : position 20 %, stop 100 % (REQ-LSC-19)', double(at(D(:,7),5.9) == 20 && at(D(:,7),6.0) == 100 && at(D(:,7),7.05) == 20), 1, 1);
check('REQ-LSC-16 clignotant : plein regime des le 1er pas', at(D(:,5), 7.0), 91, 91);
check('Extinction immediate du croisement (9 s)', at(D(:,1), 9.0), 0, 0);
check('Commandes vers B6 coherentes (croisement G)', double(all(dg(:,1) == (D(:,1) > 0))), 1, 1);

figure('Name','B7 - Scenario 1','Color','w','Position',[100 60 950 760]);
subplot(4,1,1); plot(tt, D(:,1), 'b', 'LineWidth', 1.4); hold on; plot(tt, D(:,3), 'm', 'LineWidth', 1.1); plot(tt, D(:,8), 'Color',[0 .6 0], 'LineWidth', 1.1);
ylim([-5 105]); grid on; ylabel('PWM [%]'); legend('Croisement','Route','Antibrouillard','Location','eastoutside');
title('B7 - Scenario 1 : pilotage des sorties');
subplot(4,1,2); plot(tt, D(:,4), 'Color',[0.9 0.6 0], 'LineWidth', 1.4); hold on; plot(tt, D(:,7), 'r', 'LineWidth', 1.4);
ylim([-5 105]); grid on; ylabel('PWM [%]'); legend('LED avant DRL/veilleuse','LED arriere stop/position','Location','eastoutside');
subplot(4,1,3); plot(tt, ve, 'b', 'LineWidth', 1.4); hold on; plot(t, vb, 'r--', 'LineWidth', 1.1); yline(13.2, 'k:');
ylim([11 15]); grid on; ylabel('Tension [V]'); legend('Veff croisement','Vbat','Location','eastoutside');
subplot(4,1,4); plot(tt, D(:,1), 'b', 'LineWidth', 1.4); xlim([0.95 1.2]); ylim([-5 105]); grid on;
ylabel('PWM [%]'); xlabel('Temps [s]'); title('Zoom : demarrage progressif (0 -> 84 % en 0,1 s)');
saveas(gcf, 'B7_scenario1.png');
fprintf('\nFigure enregistree : B7_scenario1.png\n');

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
