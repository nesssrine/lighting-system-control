%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  BLOC   : B3 - Feux de route automatiques (AHB - Auto High Beam)
%  Exigences couvertes : REQ-LSC-10 a REQ-LSC-15
%  Auteur : Amina Borcheni - MATLAB/Simulink R2022b
% ======================================================================
clear; clc; close all;

%% 1) Parametres calibrables (cahier des charges, section 4.3)
Ts        = 0.01;   % periode d'execution [s]
V_AHB_ON  = 40;     % vitesse d'activation [km/h]          REQ-LSC-10
V_AHB_OFF = 30;     % vitesse de desactivation [km/h]      REQ-LSC-13
LUX_AHB   = 50;     % luminosite max pour l'AHB [lux]      REQ-LSC-10
T_REARM   = 2;      % route libre confirmee avant feux de route [s]  REQ-LSC-12

%% 2) Construction du modele
mdl = 'B3_AHB';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts', 'StopTime','60');

ins = {'AutoMode','autoSig',true;  'AHB_Switch','switchSig',true;  'LowBeamOn','lowSig',true; ...
       'Speed','speedSig',false;   'Lux','luxSig',false;           'VehicleDetected','detSig',true; ...
       'CamOK','camSig',true;      'ManualOverride','manSig',true};
fcn = [mdl '/AHB_Logic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fcn, 'Position', [330 40 520 440]);
rt = sfroot;
ch = rt.find('-isa','Stateflow.EMChart','Path',fcn);
ch.Script = fileread(fullfile(pwd,'scripts','B3_logic.txt'));
for nm = {'Ts','V_AHB_ON','V_AHB_OFF','LUX_AHB','T_REARM'}
    d = ch.find('-isa','Stateflow.Data','Name',nm{1}); d.Scope = 'Parameter';
end
for k = 1:size(ins,1)
    b = [mdl '/' ins{k,1}];
    y = 40 + (k-1)*50;
    add_block('simulink/Sources/From Workspace', b, 'VariableName', ins{k,2}, 'SampleTime','Ts', ...
              'OutputAfterFinalValue','Holding final value', 'Position', [60 y 160 y+28]);
    if ins{k,3}, set_param(b,'Interpolate','off'); end
    add_line(mdl, [ins{k,1} '/1'], sprintf('AHB_Logic/%d',k), 'autorouting','on');
end
add_block('simulink/Sinks/To Workspace', [mdl '/HighBeamLog'], 'VariableName','highBeam', ...
          'SaveFormat','Timeseries', 'Position',[640 120 740 150]);
add_block('simulink/Sinks/To Workspace', [mdl '/StateLog'], 'VariableName','ahbState', ...
          'SaveFormat','Timeseries', 'Position',[640 320 740 350]);
add_block('simulink/Sinks/Out1', [mdl '/HighBeamReq'], 'Position',[640 200 670 216]);
add_block('simulink/Sinks/Out1', [mdl '/AHB_State'],   'Position',[640 400 670 416]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts','3', 'Position',[820 200 860 300]);
add_line(mdl,'AHB_Logic/1','HighBeamLog/1','autorouting','on');
add_line(mdl,'AHB_Logic/1','HighBeamReq/1','autorouting','on');
add_line(mdl,'AHB_Logic/1','Scope/2','autorouting','on');
add_line(mdl,'AHB_Logic/2','StateLog/1','autorouting','on');
add_line(mdl,'AHB_Logic/2','AHB_State/1','autorouting','on');
add_line(mdl,'AHB_Logic/2','Scope/3','autorouting','on');
add_line(mdl,'Speed/1','Scope/1','autorouting','on');
save_system(mdl);
fprintf('Modele %s.slx cree.\n\n', mdl);

%% 3) SCENARIO 1 : route de nuit, vehicule en face, detections intermittentes, ralentissement
t = (0:Ts:60)';  on = true(size(t));
spd = 80*ones(size(t));
spd(t < 10) = 8*t(t < 10);                                  % acceleration 0 -> 80 km/h (40 km/h a 5 s)
spd(t >= 45 & t < 55) = 80 - 6*(t(t >= 45 & t < 55) - 45);  % ralentissement 80 -> 20 km/h
spd(t >= 55) = 20;
det = false(size(t));
det(t >= 20 & t < 25) = true;                               % vehicule venant en face 20-25 s
for tp = 30:1.5:39, det(t >= tp & t < tp + 0.2) = true; end % detections intermittentes 30-39,2 s
autoSig = timeseries(on,t); switchSig = timeseries(on,t); lowSig = timeseries(on,t);
speedSig = timeseries(spd,t); luxSig = timeseries(10*ones(size(t)),t);
detSig = timeseries(det,t); camSig = timeseries(on,t); manSig = timeseries(~on,t);
out1 = sim(mdl);
hb1 = logical(squeeze(out1.highBeam.Data)); tt1 = out1.highBeam.Time;
st1 = double(squeeze(out1.ahbState.Data));
t1 = t; spd1 = spd; det1 = det;   % memorise le scenario 1 pour les courbes

fprintf('===== SCENARIO 1 : route de nuit =====\n');
t40 = t(find(spd >= 40, 1));
check('REQ-LSC-10 activation (40 km/h + 2 s route libre)', firstT(hb1, tt1, 0) - t40, 2.00, 2.05);
check('REQ-LSC-11 coupure apres detection <= 300 ms', firstT(~hb1, tt1, 20) - 20, 0, 0.30);
check('REQ-LSC-12 reactivation 2 s apres fin detection', firstT(hb1, tt1, 25) - 25, 2.00, 2.05);
nOn = sum(diff(double(hb1(tt1 >= 30 & tt1 <= 41.1))) > 0);
check('REQ-LSC-12 aucun rallumage pendant detections intermittentes', nOn, 0, 0);
check('REQ-LSC-12 reactivation apres la derniere detection (39,2 s)', firstT(hb1, tt1, 39.2) - 39.2, 2.00, 2.05);
t30 = t(find(spd < 30 & t > 45, 1));
check('REQ-LSC-13 maintien entre 40 et 30 km/h (t = 52 s)', double(hb1(find(tt1 >= 52, 1))), 1, 1);
check('REQ-LSC-13 coupure sous 30 km/h', firstT(~hb1, tt1, 45) - t30, 0, 0.02);

%% 4) SCENARIO 2 : defaut camera, action manuelle, retour du jour
t = (0:Ts:40)';  on = true(size(t));
cam = on;  cam(t >= 10 & t < 15) = false;                  % camera en defaut 10-15 s
man = ~on; man(t >= 25 & t < 27) = true;                   % appel de phares 25-27 s
lx  = 10*ones(size(t)); lx(t >= 33) = 5000;                % le jour revient a 33 s
autoSig = timeseries(on,t); switchSig = timeseries(on,t); lowSig = timeseries(on,t);
speedSig = timeseries(80*ones(size(t)),t); luxSig = timeseries(lx,t);
detSig = timeseries(~on,t); camSig = timeseries(cam,t); manSig = timeseries(man,t);
out2 = sim(mdl);
hb2 = logical(squeeze(out2.highBeam.Data)); tt2 = out2.highBeam.Time;
st2 = double(squeeze(out2.ahbState.Data));

fprintf('\n===== SCENARIO 2 : defauts et priorites =====\n');
check('REQ-LSC-14 coupure sur defaut camera <= 500 ms', firstT(~hb2, tt2, 10) - 10, 0, 0.50);
check('REQ-LSC-14 etat FAULT signale (t = 12 s)', st2(find(tt2 >= 12, 1)), 4, 4);
check('REQ-LSC-15 action manuelle prioritaire <= 100 ms', firstT(~hb2, tt2, 25) - 25, 0, 0.10);
check('REQ-LSC-15 etat PAUSE pendant l''action (t = 26 s)', st2(find(tt2 >= 26, 1)), 3, 3);
check('REQ-LSC-10 desactivation quand il fait jour', firstT(~hb2, tt2, 33) - 33, 0, 0.02);

%% 5) Courbes pour le rapport
figure('Name','B3 - Scenario 1','Color','w','Position',[100 100 900 700]);
subplot(4,1,1); plot(t1, spd1, 'b','LineWidth',1.2); hold on;
yline(V_AHB_ON,'r--','40 km/h'); yline(V_AHB_OFF,'m--','30 km/h');
ylabel('Vitesse [km/h]'); grid on; title('B3 AHB - Scenario 1 : route de nuit');
subplot(4,1,2); stairs(t1, double(det1), 'r','LineWidth',1.2);
ylim([-0.2 1.2]); yticks([0 1]); yticklabels({'non','oui'}); ylabel('Vehicule'); grid on;
subplot(4,1,3); stairs(tt1, double(hb1), 'k','LineWidth',1.5);
ylim([-0.2 1.2]); yticks([0 1]); yticklabels({'Croisement','Route'}); ylabel('Feux'); grid on;
subplot(4,1,4); stairs(tt1, st1, 'Color',[0 .5 0],'LineWidth',1.2); ylim([-0.5 4.5]);
yticks(0:4); yticklabels({'OFF','READY','ACTIVE','PAUSE','FAULT'}); ylabel('Etat AHB'); xlabel('Temps [s]'); grid on;
saveas(gcf, 'B3_scenario1.png');

figure('Name','B3 - Scenario 2','Color','w','Position',[150 100 900 600]);
subplot(3,1,1); stairs(t, double(~cam),'r','LineWidth',1.2); hold on; stairs(t, double(man)+0.02,'b','LineWidth',1.2);
stairs(t, double(lx>1000)-0.02,'Color',[0.9 0.6 0],'LineWidth',1.2); ylim([-0.2 1.2]); grid on;
legend('Defaut camera','Appel de phares','Jour','Location','eastoutside'); title('B3 AHB - Scenario 2 : defauts et priorites');
subplot(3,1,2); stairs(tt2, double(hb2),'k','LineWidth',1.5); ylim([-0.2 1.2]);
yticks([0 1]); yticklabels({'Croisement','Route'}); ylabel('Feux'); grid on;
subplot(3,1,3); stairs(tt2, st2,'Color',[0 .5 0],'LineWidth',1.2); ylim([-0.5 4.5]);
yticks(0:4); yticklabels({'OFF','READY','ACTIVE','PAUSE','FAULT'}); ylabel('Etat AHB'); xlabel('Temps [s]'); grid on;
set(findall(gcf,'type','axes'),'XLim',[0 40]);
saveas(gcf, 'B3_scenario2.png');
fprintf('\nFigures enregistrees : B3_scenario1.png, B3_scenario2.png\n');

%% ---- fonctions locales
function tf = firstT(cond, tt, tmin)
    i = find(cond & tt > tmin, 1);
    if isempty(i), tf = NaN; else, tf = tt(i); end
end
function check(nom, val, vmin, vmax)
    if ~isnan(val) && val >= vmin - 1e-9 && val <= vmax + 1e-9
        fprintf('  [PASS] %-60s mesure = %.2f\n', nom, val);
    else
        fprintf('  [FAIL] %-60s mesure = %.2f (attendu %.2f..%.2f)\n', nom, val, vmin, vmax);
    end
end
