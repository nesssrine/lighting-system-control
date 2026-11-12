%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  BLOC   : B1 - Acquisition et filtrage des entrees
%  Exigences couvertes : REQ-LSC-09 (diagnostic capteur), NFR-04 (filtrage, anti-rebond), REQ-LSC-02
%  Auteur : Amina Borcheni - MATLAB/Simulink R2022b
% ======================================================================
clear; clc; close all;
addpath(fullfile(pwd,'scripts'));
B1_params;                                   % Ts, TAU_LUX, LUX_MAX, T_ABSENT, T_RECOVER, T_DEB

%% 1) Construction du modele
mdl = 'B1_Acquisition';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts', 'StopTime','30');

fcn = [mdl '/B1_Logic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fcn, 'Position', [330 60 530 300]);
rt = sfroot; ch = rt.find('-isa','Stateflow.EMChart','Path',fcn);
ch.Script = fileread(fullfile(pwd,'scripts','B1_logic.txt'));
for nm = {'Ts','TAU_LUX','LUX_MAX','T_ABSENT','T_RECOVER','T_DEB'}
    d = ch.find('-isa','Stateflow.Data','Name',nm{1}); d.Scope = 'Parameter';
end
ins = {'LuxRaw','luxRawSig',false; 'MsgOK','msgSig',true; 'SwitchRaw','swSig',true; 'FlashRaw','flashSig',true};
for k = 1:4
    b = [mdl '/' ins{k,1}]; y = 70 + (k-1)*60;
    add_block('simulink/Sources/From Workspace', b, 'VariableName', ins{k,2}, 'SampleTime','Ts', ...
              'OutputAfterFinalValue','Holding final value', 'Position', [60 y 170 y+28]);
    if ins{k,3}, set_param(b,'Interpolate','off'); end
    add_line(mdl, [ins{k,1} '/1'], sprintf('B1_Logic/%d',k), 'autorouting','on');
end
outs = {'luxFilt','AmbientLux'; 'luxValid','LuxValid'; 'swPos','LightSwitchPos'; 'flashReq','FlashReq'};
for k = 1:4
    y = 50 + (k-1)*70;
    add_block('simulink/Sinks/To Workspace', [mdl '/' outs{k,1} 'Log'], 'VariableName', outs{k,1}, ...
              'SaveFormat','Timeseries', 'Position', [640 y 740 y+28]);
    add_block('simulink/Sinks/Out1', [mdl '/' outs{k,2}], 'Position', [640 y+36 670 y+50]);
    add_line(mdl, sprintf('B1_Logic/%d',k), [outs{k,1} 'Log/1'], 'autorouting','on');
    add_line(mdl, sprintf('B1_Logic/%d',k), [outs{k,2} '/1'], 'autorouting','on');
end
add_block('simulink/Signal Routing/Mux', [mdl '/Mux'], 'Inputs','2', 'Position', [800 40 805 100]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts','3', 'Position', [880 60 920 180]);
add_line(mdl,'LuxRaw/1','Mux/1','autorouting','on');
add_line(mdl,'B1_Logic/1','Mux/2','autorouting','on');
add_line(mdl,'Mux/1','Scope/1','autorouting','on');
add_line(mdl,'B1_Logic/2','Scope/2','autorouting','on');
add_line(mdl,'B1_Logic/3','Scope/3','autorouting','on');
c = get_param([mdl '/Scope'],'ScopeConfiguration'); c.LayoutDimensions = [3 1];
save_system(mdl);
fprintf('Modele %s.slx cree.\n\n', mdl);

%% 2) SCENARIO 1 : filtrage et diagnostic du capteur
B1_scenario1; close(gcf);
out1 = sim(mdl);
[yf, tt]  = sig(out1.luxFilt);   v1 = logical(sig(out1.luxValid));
raw = lux;
fprintf('===== SCENARIO 1 : filtrage et diagnostic =====\n');
w = tt >= 6 & tt <= 11;
check('NFR-04 reduction du bruit (ecart-type filtre / brut)', std(yf(w))/std(raw(w)), 0, 0.30);
check('REQ-LSC-09 valeur hors plage -> defaut immediat', firstT(~v1, tt, 12) - 12, 0, 0.01);
check('REQ-LSC-09 filtre fige pendant le defaut (lux max)', max(yf(tt >= 12 & tt < 12.5)), 0, 1000);
check('REQ-LSC-09 retour a la normale 1 s apres', firstT(v1, tt, 12.5) - 12.5, 1.00, 1.02);
check('REQ-LSC-09 absence courte (0,3 s) toleree', min(double(v1(tt >= 17.9 & tt <= 19.5))), 1, 1);
check('REQ-LSC-09 absence > 500 ms -> defaut', firstT(~v1, tt, 22) - 22, 0.50, 0.52);
check('REQ-LSC-09 retour 1 s apres le retour du message', firstT(v1, tt, 23) - 23, 1.00, 1.02);
t1 = t; raw1 = raw; yf1 = yf; tt1 = tt; vv1 = v1; msg1 = msg;

%% 3) SCENARIO 2 : anti-rebond et constante de temps
B1_scenario2;
out2 = sim(mdl, 'StopTime', '15');
[yf2, tt2] = sig(out2.luxFilt);  sp = sig(out2.swPos);  fr = logical(sig(out2.flashReq));
fprintf('\n===== SCENARIO 2 : anti-rebond et filtre =====\n');
check('NFR-04 constante de temps du filtre (63 %)', firstT(yf2 >= 1632, tt2, 1) - 1, 0.19, 0.23);
check('NFR-04 commodo valide 50 ms apres le dernier rebond', firstT(sp == 1, tt2, 1.9) - 2.02, 0.05, 0.06);
check('NFR-04 parasite de 20 ms ignore (commodo)', max(sp(tt2 >= 4.9 & tt2 <= 6)), 1, 1);
check('REQ-LSC-02 appel de phares valide apres 50 ms', firstT(fr, tt2, 7.9) - 8.02, 0.05, 0.06);
check('REQ-LSC-02 relachement valide apres 50 ms', firstT(~fr, tt2, 8.40) - 8.40, 0.05, 0.06);
check('NFR-04 parasite de 20 ms ignore (appel de phares)', double(max(fr(tt2 >= 9.9 & tt2 <= 11))), 0, 0);

%% 4) Courbes pour le rapport
figure('Name','B1 - Scenario 1','Color','w','Position',[100 100 900 650]);
subplot(3,1,1); plot(t1, raw1, 'Color',[0.65 0.65 0.65]); hold on; plot(tt1, yf1, 'b','LineWidth',1.5);
ylim([0 8000]); grid on; ylabel('Luminosite [lux]'); legend('mesure brute','mesure filtree');
title('B1 - Scenario 1 : filtrage et diagnostic du capteur');
subplot(3,1,2); stairs(t1, double(msg1),'r','LineWidth',1.2); ylim([-0.2 1.2]); grid on;
yticks([0 1]); yticklabels({'absent','recu'}); ylabel('Message');
subplot(3,1,3); stairs(tt1, double(vv1),'k','LineWidth',1.5); ylim([-0.2 1.2]); grid on;
yticks([0 1]); yticklabels({'DEFAUT','valide'}); ylabel('LuxValid'); xlabel('Temps [s]');
saveas(gcf, 'B1_scenario1.png');

figure('Name','B1 - Scenario 2','Color','w','Position',[150 100 900 650]);
subplot(3,1,1); plot(t, lux,'Color',[0.6 0.6 0.6],'LineWidth',1.2); hold on; plot(tt2, yf2,'b','LineWidth',1.5);
yline(1632,'r--','63 %'); xlim([0.8 2]); grid on; ylabel('Lux'); legend('brut','filtre','Location','southeast');
title('B1 - Scenario 2 : filtre (tau = 0,2 s) et anti-rebond (50 ms)');
subplot(3,1,2); stairs(t, sw,'Color',[0.6 0.6 0.6],'LineWidth',1.2); hold on; stairs(tt2, sp,'b','LineWidth',1.5);
xlim([1.95 2.15]); ylim([-0.2 1.2]); grid on; ylabel('Commodo'); legend('brut (rebonds)','valide');
subplot(3,1,3); stairs(t, double(fl),'Color',[0.6 0.6 0.6],'LineWidth',1.2); hold on; stairs(tt2, double(fr),'b','LineWidth',1.5);
xlim([7.95 8.55]); ylim([-0.2 1.2]); grid on; ylabel('Appel phares'); xlabel('Temps [s]'); legend('brut','valide');
saveas(gcf, 'B1_scenario2.png');
fprintf('\nFigures enregistrees : B1_scenario1.png, B1_scenario2.png\n');

%% ---- fonctions locales
function [v, tt] = sig(ts)
    v = double(squeeze(ts.Data)); tt = ts.Time;
end
function tf = firstT(cond, tt, tmin)
    i = find(cond & tt >= tmin - 1e-9, 1);
    if isempty(i), tf = NaN; else, tf = tt(i); end
end
function check(nom, val, vmin, vmax)
    if ~isnan(val) && val >= vmin - 1e-9 && val <= vmax + 1e-9
        fprintf('  [PASS] %-58s mesure = %.3f\n', nom, val);
    else
        fprintf('  [FAIL] %-58s mesure = %.3f (attendu %.3f..%.3f)\n', nom, val, vmin, vmax);
    end
end
