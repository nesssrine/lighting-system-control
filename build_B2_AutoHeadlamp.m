%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  BLOC   : B2 - Allumage automatique des feux de croisement (Auto Headlamp)
%  Exigences couvertes : REQ-LSC-06, 07, 08, 09
%  Auteur : Amina Borcheni  -  MATLAB/Simulink R2022
%
%  Ce script :
%    1) definit les parametres calibrables
%    2) construit automatiquement le modele Simulink B2_AutoHeadlamp.slx
%    3) lance 2 scenarios de test (MIL) et verifie les exigences
%    4) trace les courbes de resultats (a mettre dans le rapport)
%
%  Utilisation : placer ce fichier dans le dossier du projet, puis taper
%                >> build_B2_AutoHeadlamp
% ======================================================================
clear; clc; close all;

%% 1) Parametres calibrables (cahier des charges, section 4.2)
Ts       = 0.01;    % periode d'execution du runnable [s]
LUX_ON   = 1000;    % seuil d'allumage [lux]           REQ-LSC-06
LUX_OFF  = 2000;    % seuil d'extinction [lux]         REQ-LSC-07
T_ON     = 2;       % temporisation d'allumage [s]     REQ-LSC-06
T_OFF    = 5;       % temporisation d'extinction [s]   REQ-LSC-07
T_TUNNEL = 0.3;     % temporisation tunnel [s]         REQ-LSC-08

%% 2) Construction du modele
mdl = 'B2_AutoHeadlamp';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
open_system(mdl);
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
               'FixedStep', 'Ts', 'StopTime', '45');

% --- Sources de test
add_block('simulink/Sources/From Workspace', [mdl '/Lux'], ...
          'VariableName', 'luxSig', 'SampleTime', 'Ts', 'OutputAfterFinalValue', 'Holding final value', 'Position', [40 40 140 70]);
add_block('simulink/Sources/Constant', [mdl '/AutoMode'], ...
          'Value', 'true', 'SampleTime', 'Ts', 'Position', [40 110 140 140]);
add_block('simulink/Sources/From Workspace', [mdl '/LuxValid'], ...
          'VariableName', 'validSig', 'SampleTime', 'Ts', 'Interpolate', 'off', 'OutputAfterFinalValue', 'Holding final value', 'Position', [40 180 140 210]);

% --- Bloc logique (MATLAB Function)
fcn = [mdl '/AutoHeadlampLogic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fcn, ...
          'Position', [230 40 400 210]);

code = sprintf([ ...
'function low_beam = AutoHeadlampLogic(lux, auto_mode, lux_valid, Ts, LUX_ON, LUX_OFF, T_ON, T_OFF, T_TUNNEL)\n' ...
'%%#codegen\n' ...
'%% B2 - Auto Headlamp : allumage/extinction automatique avec hysteresis\n' ...
'persistent st cnt buf idx\n' ...
'N = 50;                          %% 0,5 s d''historique (Ts = 10 ms)\n' ...
'if isempty(st)\n' ...
'    st = false; cnt = 0; buf = 10000*ones(1, N); idx = 1;\n' ...
'end\n' ...
'%% Detection tunnel : chute > 80 %% en moins de 0,5 s (REQ-LSC-08)\n' ...
'lux_past = buf(idx);\n' ...
'buf(idx) = lux;\n' ...
'idx = mod(idx, N) + 1;\n' ...
'tunnel = (lux < 0.2*lux_past) && (lux < LUX_ON);\n' ...
'\n' ...
'if ~auto_mode\n' ...
'    st = false; cnt = 0;\n' ...
'elseif ~lux_valid\n' ...
'    st = true;  cnt = 0;         %% etat sur : capteur en defaut (REQ-LSC-09)\n' ...
'elseif ~st\n' ...
'    if lux < LUX_ON\n' ...
'        cnt = cnt + Ts;\n' ...
'        if (cnt > T_ON + Ts/2) || (tunnel && cnt > T_TUNNEL + Ts/2)\n' ...
'            st = true; cnt = 0;\n' ...
'        end\n' ...
'    else\n' ...
'        cnt = 0;\n' ...
'    end\n' ...
'else\n' ...
'    if lux > LUX_OFF\n' ...
'        cnt = cnt + Ts;\n' ...
'        if cnt > T_OFF + Ts/2\n' ...
'            st = false; cnt = 0;\n' ...
'        end\n' ...
'    else\n' ...
'        cnt = 0;\n' ...
'    end\n' ...
'end\n' ...
'low_beam = st;\n']);

rt = sfroot;
ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', fcn);
ch.Script = code;
% Les seuils deviennent des parametres (lus dans le workspace -> calibrables)
params = {'Ts','LUX_ON','LUX_OFF','T_ON','T_OFF','T_TUNNEL'};
for k = 1:numel(params)
    d = ch.find('-isa', 'Stateflow.Data', 'Name', params{k});
    d.Scope = 'Parameter';
end

% --- Sorties : scope + enregistrement
add_block('simulink/Sinks/To Workspace', [mdl '/LowBeamLog'], ...
          'VariableName', 'lowBeam', 'SaveFormat', 'Timeseries', ...
          'Position', [500 110 600 140]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
          'NumInputPorts', '2', 'Position', [500 30 540 80]);
add_block('simulink/Sinks/Out1', [mdl '/LowBeamReq'], 'Position', [500 180 530 196]);

% --- Connexions
add_line(mdl, 'Lux/1',      'AutoHeadlampLogic/1', 'autorouting', 'on');
add_line(mdl, 'AutoMode/1', 'AutoHeadlampLogic/2', 'autorouting', 'on');
add_line(mdl, 'LuxValid/1', 'AutoHeadlampLogic/3', 'autorouting', 'on');
add_line(mdl, 'AutoHeadlampLogic/1', 'LowBeamLog/1', 'autorouting', 'on');
add_line(mdl, 'AutoHeadlampLogic/1', 'Scope/2',      'autorouting', 'on');
add_line(mdl, 'AutoHeadlampLogic/1', 'LowBeamReq/1', 'autorouting', 'on');
add_line(mdl, 'Lux/1',               'Scope/1',      'autorouting', 'on');
save_system(mdl);
fprintf('Modele %s.slx cree.\n\n', mdl);

%% 3) SCENARIO 1 : jour -> nuit -> jour -> tunnel (TC-02, TC-03)
t = (0:Ts:45)';
base = 5000*ones(size(t));
base(t>=5  & t<10) = 5000 - 4500*(t(t>=5 & t<10)-5)/5;     % crepuscule
base(t>=10 & t<20) = 500;                                  % nuit
base(t>=20 & t<25) = 500 + 2500*(t(t>=20 & t<25)-20)/5;    % aube
base(t>=25 & t<32) = 3000;                                 % jour
base(t>=32 & t<32.1) = 3000 - 2900*(t(t>=32 & t<32.1)-32)/0.1; % entree tunnel
base(t>=32.1 & t<38) = 100;                                % tunnel
base(t>=38) = 5000;                                        % sortie tunnel
rng(1);
lux = base .* (1 + 0.10*(2*rand(size(t))-1));              % bruit +/-10 %
luxSig   = timeseries(lux, t);
validSig = timeseries(true(size(t)), t);

out1 = sim(mdl);
lb1  = out1.lowBeam;
y1   = logical(squeeze(lb1.Data));  tt1 = lb1.Time;

% --- Verifications automatiques
fprintf('===== SCENARIO 1 =====\n');
iOn  = find(lux >= LUX_ON  & t < 15, 1, 'last') + 1;   t_cross_on  = t(iOn);
iOff = find(lux <= LUX_OFF & t < 30, 1, 'last') + 1;   t_cross_off = t(iOff);
t_on1  = tt1(find(y1 & tt1 > 5,  1));
t_off1 = tt1(find(~y1 & tt1 > t_on1, 1));
t_on2  = tt1(find(y1 & tt1 > 30, 1));
check('REQ-LSC-06 allumage apres 2 s', t_on1 - t_cross_on, 2.0, 2.1);
check('REQ-LSC-07 extinction apres 5 s', t_off1 - t_cross_off, 5.0, 5.1);
check('REQ-LSC-08 tunnel <= 0,4 s', t_on2 - 32, 0, 0.4);
nFronts = sum(diff(double(y1)) ~= 0);
check('REQ-LSC-07 pas d''oscillation (4 fronts attendus)', nFronts, 4, 4);

%% 4) SCENARIO 2 : defaut capteur en plein jour (TC-04)
luxSig   = timeseries(5000*ones(size(t)), t);
v = true(size(t));  v(t >= 10 & t < 15) = false;
validSig = timeseries(v, t);
out2 = sim(mdl);
y2 = logical(squeeze(out2.lowBeam.Data));  tt2 = out2.lowBeam.Time;
fprintf('\n===== SCENARIO 2 =====\n');
check('REQ-LSC-09 croisement ON sur defaut capteur', tt2(find(y2,1)) - 10, 0, 0.1);

%% 5) Courbes pour le rapport
figure('Name','B2 - Scenario 1','Color','w');
subplot(2,1,1);
plot(t, lux, 'Color', [0.6 0.6 0.6]); hold on;
plot(t, base, 'b', 'LineWidth', 1.2);
yline(LUX_ON,  'r--', 'SEUIL\_ON = 1000 lux');
yline(LUX_OFF, 'm--', 'SEUIL\_OFF = 2000 lux');
ylabel('Luminosite [lux]'); grid on; ylim([0 6000]);
legend('mesure bruitee','luminosite reelle','Location','northeast');
title('B2 Auto Headlamp - luminosite ambiante');
subplot(2,1,2);
stairs(tt1, double(y1), 'k', 'LineWidth', 1.5); ylim([-0.2 1.2]);
yticks([0 1]); yticklabels({'OFF','ON'}); grid on;
xlabel('Temps [s]'); ylabel('Feux de croisement');
title('Commande des feux de croisement');
saveas(gcf, 'B2_scenario1.png');

figure('Name','B2 - Scenario 2','Color','w');
subplot(2,1,1); stairs(t, double(v), 'b', 'LineWidth', 1.5);
ylim([-0.2 1.2]); grid on; ylabel('LuxValid'); title('Defaut capteur (10 s a 15 s)');
subplot(2,1,2); stairs(tt2, double(y2), 'k', 'LineWidth', 1.5);
ylim([-0.2 1.2]); grid on; xlabel('Temps [s]'); ylabel('Feux de croisement');
saveas(gcf, 'B2_scenario2.png');
fprintf('\nFigures enregistrees : B2_scenario1.png, B2_scenario2.png\n');

%% ---- fonction locale de verification
function check(nom, val, vmin, vmax)
    if val >= vmin - 1e-9 && val <= vmax + 1e-9
        fprintf('  [PASS] %-45s mesure = %.2f\n', nom, val);
    else
        fprintf('  [FAIL] %-45s mesure = %.2f (attendu %.2f..%.2f)\n', nom, val, vmin, vmax);
    end
end
