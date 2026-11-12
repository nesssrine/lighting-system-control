%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  BLOC   : B5 - Clignotants, feux de detresse, feux stop et ESS
%  Exigences couvertes : REQ-LSC-16 a REQ-LSC-21, REQ-LSC-23
%  Auteur : Amina Borcheni - MATLAB/Simulink R2022b
% ======================================================================
clear; clc; close all;
addpath(fullfile(pwd,'scripts'));
B5_params;

%% 1) Construction du modele
mdl = 'B5_Signal';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts', 'StopTime','20');
fcn = [mdl '/B5_Logic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fcn, 'Position', [330 40 540 560]);
rt = sfroot; ch = rt.find('-isa','Stateflow.EMChart','Path',fcn);
ch.Script = fileread(fullfile(pwd,'scripts','B5_logic.txt'));
for nm = {'Ts','F_BLINK','F_HYPER','T_SHORT','N_COMFORT','A_ESS_ON','A_ESS_OFF','V_ESS','F_ESS','V_RESUME'}
    d = ch.find('-isa','Stateflow.Data','Name',nm{1}); d.Scope = 'Parameter';
end
ins = {'Ignition','ignSig',true; 'TurnLeft','tlSig',true; 'TurnRight','trSig',true; 'HazardSwitch','hzSig',true; ...
       'BrakePedal','brSig',true; 'Speed','spdSig',false; 'Decel','decSig',false; 'FaultLeft','fLSig',true; 'FaultRight','fRSig',true};
for k = 1:size(ins,1)
    b = [mdl '/' ins{k,1}]; y = 45 + (k-1)*56;
    add_block('simulink/Sources/From Workspace', b, 'VariableName', ins{k,2}, 'SampleTime','Ts', ...
              'OutputAfterFinalValue','Holding final value', 'Position', [60 y 160 y+26]);
    if ins{k,3}, set_param(b,'Interpolate','off'); end
    add_line(mdl, [ins{k,1} '/1'], sprintf('B5_Logic/%d',k), 'autorouting','on');
end
outs = {'blinkL','TurnLampLeft'; 'blinkR','TurnLampRight'; 'brakeLight','BrakeLamp'; 'hazardActive','HazardState'; 'essActive','ESS_State'};
for k = 1:size(outs,1)
    y = 50 + (k-1)*100;
    add_block('simulink/Sinks/To Workspace', [mdl '/' outs{k,1} 'Log'], 'VariableName', outs{k,1}, ...
              'SaveFormat','Timeseries', 'Position', [650 y 750 y+26]);
    add_block('simulink/Sinks/Out1', [mdl '/' outs{k,2}], 'Position', [650 y+40 680 y+54]);
    add_line(mdl, sprintf('B5_Logic/%d',k), [outs{k,1} 'Log/1'], 'autorouting','on');
    add_line(mdl, sprintf('B5_Logic/%d',k), [outs{k,2} '/1'], 'autorouting','on');
end
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts','4', 'Position', [880 150 930 330]);
for k = 1:4, add_line(mdl, sprintf('B5_Logic/%d',k), sprintf('Scope/%d',k), 'autorouting','on'); end
c = get_param([mdl '/Scope'],'ScopeConfiguration'); c.LayoutDimensions = [4 1];
save_system(mdl);
fprintf('Modele %s.slx cree.\n\n', mdl);

%% 2) SCENARIO 1 : clignotants
B5_scenario1; close(gcf);
out1 = sim(mdl);
[bL, tt] = sig(out1.blinkL); bR = sig(out1.blinkR); bL = logical(bL); bR = logical(bR);
fprintf('===== SCENARIO 1 : clignotants et detresse =====\n');
e = re(bL, tt, 1, 5);
check('REQ-LSC-16 periode de clignotement (1,5 Hz)', mean(diff(e)), 0.63, 0.71);
w = tt >= 1 & tt < 4.99;
check('REQ-LSC-16 rapport cyclique', mean(bL(w)), 0.45, 0.55);
check('REQ-LSC-16 1er flash des l''appui', firstT(bL, tt, 1) - 1, 0, 0.01);
check('Arret au relachement du levier (5 s)', double(max(bL(tt >= 5 & tt <= 6.9))), 0, 0);
check('REQ-LSC-17 mode autoroute : 3 clignotements', numel(re(bR, tt, 6.9, 10)), 3, 3);
e = re(bL, tt, 12, 16);
check('REQ-LSC-23 hyper-clignotement (lampe grillee)', mean(diff(e)), 0.30, 0.36);
w = tt >= 17 & tt <= 20;
check('REQ-LSC-18 detresse : gauche et droite en phase', double(all(bL(w) == bR(w))), 1, 1);
check('REQ-LSC-18 detresse active contact coupe', numel(re(bL, tt, 17, 20)), 4, 6);
t1 = t; tl1 = tl; tr1 = tr; hz1 = hz; fL1 = fL; bL1 = bL; bR1 = bR; tt1 = tt;

%% 3) SCENARIO 2 : feux stop, ESS, detresse automatique
B5_scenario2;
out2 = sim(mdl, 'StopTime', '30');
[bk, tt2] = sig(out2.brakeLight); bk = logical(bk);
es = logical(sig(out2.essActive)); hz2 = logical(sig(out2.hazardActive));
fprintf('\n===== SCENARIO 2 : feux stop et freinage d''urgence =====\n');
check('REQ-LSC-19 feux stop a l''appui (<= 50 ms)', firstT(bk, tt2, 1.9) - 2, 0, 0.05);
check('Pas d''ESS a 40 km/h (freinage fort)', double(max(es(tt2 >= 5 & tt2 < 6))), 0, 0);
check('REQ-LSC-20 ESS active au freinage d''urgence', firstT(es, tt2, 9.9) - 10, 0, 0.02);
e = re(bk, tt2, 10.05, 13);
check('REQ-LSC-20 feux stop clignotent a 4 Hz (periode)', mean(diff(e)), 0.20, 0.34);
check('REQ-LSC-20 fin ESS sous 2,5 m/s2', firstT(~es, tt2, 10.5) - 13.125, 0, 0.02);
check('Feux stop fixes apres l''ESS (pedale appuyee)', double(min(bk(tt2 >= 13.2 & tt2 < 19.9))), 1, 1);
check('REQ-LSC-21 detresse automatique a l''arret', firstT(hz2, tt2, 10) - 13.125, -0.02, 0.02);
check('REQ-LSC-21 extinction au redemarrage (> 10 km/h)', firstT(~hz2, tt2, 14) - (22 + 10/7.5), 0, 0.02);

%% 4) Courbes pour le rapport
figure('Name','B5 - Scenario 1','Color','w','Position',[100 80 950 700]);
subplot(4,1,1); stairs(t1, double(tl1)+1.2,'b','LineWidth',1.2); hold on; stairs(t1, double(tr1),'r','LineWidth',1.2);
yticks([0.5 1.7]); yticklabels({'Levier D','Levier G'}); grid on; title('B5 - Scenario 1 : clignotants et detresse');
subplot(4,1,2); stairs(tt1, double(bL1),'b','LineWidth',1.2); ylim([-0.2 1.2]); grid on; ylabel('Clignotant G');
subplot(4,1,3); stairs(tt1, double(bR1),'r','LineWidth',1.2); ylim([-0.2 1.2]); grid on; ylabel('Clignotant D');
subplot(4,1,4); stairs(t1, double(hz1)+1.2,'Color',[0.9 0.5 0],'LineWidth',1.2); hold on; stairs(t1, double(fL1),'k','LineWidth',1.2);
yticks([0.5 1.7]); yticklabels({'Lampe G grillee','Detresse'}); grid on; xlabel('Temps [s]');
for k = 1:4, subplot(4,1,k); xline([1 5 7 12 16 17],':'); end
saveas(gcf, 'B5_scenario1.png');

figure('Name','B5 - Scenario 2','Color','w','Position',[150 80 950 700]);
subplot(4,1,1); yyaxis left; plot(t, spd,'b','LineWidth',1.3); ylabel('Vitesse [km/h]');
yyaxis right; plot(t, dec,'r','LineWidth',1.1); ylabel('Deceleration [m/s^2]'); grid on;
title('B5 - Scenario 2 : feux stop, freinage d''urgence (ESS), detresse automatique');
subplot(4,1,2); stairs(t, double(br),'k','LineWidth',1.2); ylim([-0.2 1.2]); grid on; ylabel('Pedale frein');
subplot(4,1,3); stairs(tt2, double(bk),'r','LineWidth',1.1); ylim([-0.2 1.2]); grid on; ylabel('Feux stop');
subplot(4,1,4); stairs(tt2, double(hz2),'Color',[0.9 0.5 0],'LineWidth',1.4); ylim([-0.2 1.2]); grid on;
ylabel('Detresse auto'); xlabel('Temps [s]');
saveas(gcf, 'B5_scenario2.png');
fprintf('\nFigures enregistrees : B5_scenario1.png, B5_scenario2.png\n');

%% ---- fonctions locales
function [v, tt] = sig(ts)
    v = double(squeeze(ts.Data)); tt = ts.Time;
end
function e = re(y, tt, t0, t1)
    i = find(diff([false; y(:)]) > 0); e = tt(i); e = e(e >= t0 - 1e-9 & e <= t1 + 1e-9);
end
function tf = firstT(cond, tt, tmin)
    i = find(cond & tt >= tmin - 1e-9, 1);
    if isempty(i), tf = NaN; else, tf = tt(i); end
end
function check(nom, val, vmin, vmax)
    if ~isnan(val) && val >= vmin - 1e-9 && val <= vmax + 1e-9
        fprintf('  [PASS] %-56s mesure = %.3f\n', nom, val);
    else
        fprintf('  [FAIL] %-56s mesure = %.3f (attendu %.3f..%.3f)\n', nom, val, vmin, vmax);
    end
end
