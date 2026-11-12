%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  BLOC   : B4 - Lighting Manager (arbitrage) + B8 - Follow-me-home
%  Exigences : REQ-LSC-01 a 05, 15, 24 (B4) ; REQ-LSC-25, 27 a 32 (B8)
%  Auteur : Amina Borcheni - MATLAB/Simulink R2022b
% ======================================================================
clear; clc; close all;
addpath(fullfile(pwd,'scripts'));
B4_params;

%% 1) Construction du modele
mdl = 'B4_LightingMgr';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts', 'StopTime','40');
fcn = [mdl '/B4_Logic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fcn, 'Position', [330 40 560 680]);
rt = sfroot; ch = rt.find('-isa','Stateflow.EMChart','Path',fcn);
ch.Script = fileread(fullfile(pwd,'scripts','B4_logic.txt'));
for nm = {'Ts','LUX_ON','T_FMH','T_ARM','T_FMH_STEP','T_FMH_MAX','U_BAT_MIN'}
    d = ch.find('-isa','Stateflow.Data','Name',nm{1}); d.Scope = 'Parameter';
end
ins = {'Ignition','ignSig',true; 'LightSwitchPos','swSig',true; 'FlashReq','flSig',true; 'HighBeamToggle','hbSig',true; ...
       'FogSwitch','fogSig',true; 'AutoLowReq_B2','alSig',true; 'AHB_Req_B3','ahbSig',true; 'AmbientLux','luxSig',false; ...
       'BatteryVoltage','batSig',false; 'DoorsClosed','doorSig',true; 'DegradedMode_B6','degSig',true};
for k = 1:size(ins,1)
    b = [mdl '/' ins{k,1}]; y = 45 + (k-1)*57;
    add_block('simulink/Sources/From Workspace', b, 'VariableName', ins{k,2}, 'SampleTime','Ts', ...
              'OutputAfterFinalValue','Holding final value', 'Position', [60 y 160 y+26]);
    if ins{k,3}, set_param(b,'Interpolate','off'); end
    add_line(mdl, [ins{k,1} '/1'], sprintf('B4_Logic/%d',k), 'autorouting','on');
end
outs = {'lowL','LowBeamLeft'; 'lowR','LowBeamRight'; 'highB','HighBeam'; 'posL','PositionLamps'; ...
        'drlO','DRL'; 'fogO','RearFog'; 'fmhO','FMH_Active'; 'stateO','LightState'};
for k = 1:size(outs,1)
    y = 45 + (k-1)*80;
    add_block('simulink/Sinks/To Workspace', [mdl '/' outs{k,1} 'Log'], 'VariableName', outs{k,1}, ...
              'SaveFormat','Timeseries', 'Position', [680 y 780 y+26]);
    add_block('simulink/Sinks/Out1', [mdl '/' outs{k,2}], 'Position', [680 y+38 710 y+52]);
    add_line(mdl, sprintf('B4_Logic/%d',k), [outs{k,1} 'Log/1'], 'autorouting','on');
    add_line(mdl, sprintf('B4_Logic/%d',k), [outs{k,2} '/1'], 'autorouting','on');
end
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts','4', 'Position', [900 200 950 400]);
add_line(mdl,'LightSwitchPos/1','Scope/1','autorouting','on');
add_line(mdl,'B4_Logic/1','Scope/2','autorouting','on');
add_line(mdl,'B4_Logic/3','Scope/3','autorouting','on');
add_line(mdl,'B4_Logic/8','Scope/4','autorouting','on');
c = get_param([mdl '/Scope'],'ScopeConfiguration'); c.LayoutDimensions = [4 1];
save_system(mdl);
fprintf('Modele %s.slx cree.\n\n', mdl);

%% 2) SCENARIO 1 : conduite normale
B4_scenario1; close(gcf);
o = sim(mdl); R = res(o); at = @(x, tq) x(find(R.t >= tq - 1e-9, 1));
fprintf('===== SCENARIO 1 : conduite normale (B4) =====\n');
check('REQ-LSC-05 DRL au contact (<= 200 ms)', firstT(R.drl, R.t, 1) - 1, 0, 0.20);
check('REQ-LSC-01 POSITION : veilleuses seules', double(at(R.pos,4) && ~at(R.lowL,4) && ~at(R.drl,4)), 1, 1);
check('REQ-LSC-04 antibrouillard refuse sans croisement', double(at(R.fog, 5.5)), 0, 0);
check('REQ-LSC-01 CROISEMENT (<= 100 ms)', firstT(R.lowL, R.t, 6) - 6, 0, 0.10);
check('REQ-LSC-02 commutation route ON puis OFF', double(at(R.high,9) && ~at(R.high,10.5)), 1, 1);
check('REQ-LSC-03 appel de phares (route pendant l''appui)', double(at(R.high,12.2) && ~at(R.high,12.6)), 1, 1);
check('REQ-LSC-04 antibrouillard accepte avec croisement', double(at(R.fog, 14.5)), 1, 1);
check('REQ-LSC-04/05 AUTO de jour : croisement + antibrouillard OFF, DRL ON', double(~at(R.lowL,16.1) && ~at(R.fog,16.1) && at(R.drl,16.1)), 1, 1);
check('REQ-LSC-06 AUTO de nuit : demande de B2 appliquee', firstT(R.lowL, R.t, 16.5) - 18, 0, 0.02);
check('REQ-LSC-10 demande AHB de B3 appliquee (22-26 s)', double(at(R.high,23) && ~at(R.high,26.5)), 1, 1);
check('REQ-LSC-24 mode degrade : croisement D coupe, G + veilleuses ON', double(at(R.lowL,31) && ~at(R.lowR,31) && at(R.pos,31)), 1, 1);
R1 = R; t1 = t; sw1 = sw;

%% 3) SCENARIO 2 : follow-me-home automatique
B4_scenario2;
o = sim(mdl, 'StopTime', '55'); R = res(o); at = @(x, tq) x(find(R.t >= tq - 1e-9, 1));
fprintf('\n===== SCENARIO 2 : follow-me-home automatique (B8) =====\n');
check('REQ-LSC-25 activation a la coupure du contact (sans trou)', double(min(R.lowL(R.t >= 4.9 & R.t <= 6)) && at(R.fmh,5.05)), 1, 1);
check('REQ-LSC-32 pas de feux de route pendant le FMH', double(max(R.high(R.t >= 5.05 & R.t <= 39))), 0, 0);
check('REQ-LSC-29 extinction 30 s apres fermeture de la porte (10 s)', firstT(~R.lowL, R.t, 5.5) - 40, 0, 0.05);
check('REQ-LSC-30 annulation par le commodo (46 s) -> veilleuses', double(~at(R.fmh,46.05) && at(R.pos,46.05)), 1, 1);
check('REQ-LSC-30 annulation batterie faible (52 s)', firstT(~R.fmh, R.t, 50) - 52, 0, 0.02);
R2 = R; t2 = t; ign2 = ign; dc2 = dc;

%% 4) SCENARIO 3 : follow-me-home manuel de jour
B4_scenario3;
o = sim(mdl, 'StopTime', '110'); R = res(o); at = @(x, tq) x(find(R.t >= tq - 1e-9, 1));
fprintf('\n===== SCENARIO 3 : follow-me-home manuel (B8) =====\n');
check('REQ-LSC-31 pas d''activation automatique de jour', double(at(R.lowL, 3)), 0, 0);
check('REQ-LSC-27 activation par appel de phares (<= 100 ms)', firstT(R.lowL, R.t, 3) - 4, 0, 0.10);
check('REQ-LSC-28 3 appels = 90 s (extinction a 94 s)', firstT(~R.lowL, R.t, 4.5) - 94, -0.05, 0.05);
check('REQ-LSC-27 appel trop tard (98 s apres coupure) refuse', double(at(R.lowL, 100.3)), 0, 0);
R3 = R; t3 = t; fl3 = fl;

%% 5) Courbes
figure('Name','B4 - Scenario 1','Color','w','Position',[80 60 950 760]);
subplot(3,1,1); stairs(t1, sw1, 'b', 'LineWidth', 1.4); yticks(0:3); yticklabels({'OFF','AUTO','POSITION','CROIS.'});
ylim([-0.3 3.3]); grid on; title('B4 - Scenario 1 : arbitrage en conduite normale'); ylabel('Commodo');
subplot(3,1,2); stairs(R1.t, double([R1.drl R1.pos+1.2 R1.lowL+2.4 R1.lowR+3.6 R1.high+4.8 R1.fog+6]), 'LineWidth', 1.3);
yticks(0.5:1.2:6.5); yticklabels({'DRL','Veilleuses','Crois. G','Crois. D','Route','Antibrouill.'}); grid on;
subplot(3,1,3); stairs(R1.t, R1.st, 'k', 'LineWidth', 1.4); yticks(0:5);
yticklabels({'OFF','DRL','POSITION','CROISEMENT','ROUTE','FMH'}); ylim([-0.3 5.3]); grid on; xlabel('Temps [s]'); ylabel('Etat');
for k = 1:3, subplot(3,1,k); xline([1 3 5 6 8 10 12 14 16 18 22 26 30], ':'); end
saveas(gcf, 'B4_scenario1.png');

figure('Name','B8 - Follow-me-home','Color','w','Position',[120 60 950 760]);
subplot(4,1,1); stairs(t2, double([ign2 dc2+1.2]), 'LineWidth', 1.3); ylim([-0.2 2.4]); xline([5 10 40 44 46 49 52], 'r:'); yticks([0.5 1.7]); yticklabels({'Contact','Portes fermees'});
grid on; title('B8 - Scenario 2 : follow-me-home automatique de nuit');
subplot(4,1,2); stairs(R2.t, double([R2.lowL R2.fmh+1.2 R2.high+2.4]), 'LineWidth', 1.3);
yticks([0.5 1.7 2.9]); yticklabels({'Croisement','FMH actif','Route'}); grid on;
xline([5 10 40 44 46 49 52], 'r:'); ylim([-0.2 3.6]);
subplot(4,1,3); stairs(t3, double(fl3), 'r', 'LineWidth', 1.3); ylim([-0.2 1.2]); grid on; ylabel('Appel phares');
title('B8 - Scenario 3 : follow-me-home manuel de jour');
subplot(4,1,4); stairs(R3.t, double([R3.lowL R3.fmh+1.2]), 'LineWidth', 1.3); yticks([0.5 1.7]); yticklabels({'Croisement','FMH actif'});
grid on; xlabel('Temps [s]'); xline([2 4 94 100], 'r:'); ylim([-0.2 2.4]);
saveas(gcf, 'B8_followmehome.png');
fprintf('\nFigures enregistrees : B4_scenario1.png, B8_followmehome.png\n');

%% ---- fonctions locales
function R = res(o)
    R.t = o.lowL.Time;  f = @(x) logical(squeeze(x.Data));
    R.lowL = f(o.lowL); R.lowR = f(o.lowR); R.high = f(o.highB); R.pos = f(o.posL);
    R.drl = f(o.drlO); R.fog = f(o.fogO); R.fmh = f(o.fmhO); R.st = double(squeeze(o.stateO.Data));
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
