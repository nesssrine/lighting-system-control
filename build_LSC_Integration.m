%% =====================================================================
%  PROJET : Lighting System Control (AUTOSAR / ADAS)
%  INTEGRATION : les 8 blocs relies dans un seul modele (ECU d'eclairage complet)
%  Auteur : Amina Borcheni - MATLAB/Simulink R2022b
% ======================================================================
clear; clc; close all;
addpath(fullfile(pwd,'scripts'));
B1_params; B2_params; B3_params; B4_params; B5_params; B6_params; B7_params;
S = fullfile(pwd,'scripts');

%% 1) Modele et sous-systemes
mdl = 'LSC_Integration';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts', 'StopTime','130');

B1 = mkSub(mdl, 'B1_Acquisition', fullfile(S,'B1_logic.txt'), {'Ts','TAU_LUX','LUX_MAX','T_ABSENT','T_RECOVER','T_DEB'}, [330 60 480 200]);
B2 = mkSub(mdl, 'B2_AutoHeadlamp', fullfile(S,'B2_logic.txt'), {'Ts','LUX_ON','LUX_OFF','T_ON','T_OFF','T_TUNNEL'}, [640 40 790 130]);
B3 = mkSub(mdl, 'B3_AHB', fullfile(S,'B3_logic.txt'), {'Ts','V_AHB_ON','V_AHB_OFF','LUX_AHB','T_REARM'}, [640 170 790 330]);
B4 = mkSub(mdl, 'B4_B8_LightingMgr', fullfile(S,'B4_logic.txt'), {'Ts','LUX_ON','T_FMH','T_ARM','T_FMH_STEP','T_FMH_MAX','U_BAT_MIN'}, [960 40 1130 330]);
B5 = mkSub(mdl, 'B5_Signalisation', fullfile(S,'B5_logic.txt'), {'Ts','F_BLINK','F_HYPER','T_SHORT','N_COMFORT','A_ESS_ON','A_ESS_OFF','V_ESS','F_ESS','V_RESUME'}, [960 400 1130 640]);
B6 = mkSub(mdl, 'B6_Diagnostic', fullfile(S,'B6_logic.txt'), {'Ts','I_NOM','R_OPEN','R_SHORT','T_INRUSH','T_CONF','T_HEAL'}, [1600 400 1750 520]);
B7 = mkSub(mdl, 'B7_Pilotage', fullfile(S,'B7_logic.txt'), {'Ts','V_EFF','T_SOFT','POS_DIM','TAIL_DIM'}, [1300 40 1450 400]);
PL = mkSub(mdl, 'Plant_Lampes', fullfile(S,'Plant_logic.txt'), {'I_NOM'}, [1600 120 1750 230]);
set_param([mdl '/Plant_Lampes'], 'BackgroundColor', 'lightBlue');
% Types et tailles des sorties declares explicitement (necessaire pour les boucles de retroaction)
setOut(B4, {'low_L','low_R','high','position','drl','fog','fmh_active'}, 'boolean', '1'); setOut(B4, {'light_state'}, 'uint8', '1');
setOut(B5, {'blink_L','blink_R','brake_light','hazard_active','ess_active'}, 'boolean', '1');
setOut(B7, {'duty'}, 'uint8', '[8 1]'); setOut(B7, {'veff_low'}, 'double', '1'); setOut(B7, {'diag_cmd'}, 'boolean', '[4 1]');
setOut(PL, {'lamp_cur'}, 'double', '[4 1]');
setOut(B6, {'fault_act'}, 'boolean', '[4 1]'); setOut(B6, {'dtc_stored'}, 'uint16', '1');
setOut(B6, {'degraded'}, 'uint8', '1'); setOut(B6, {'warning'}, 'boolean', '1');
setOut(B3, {'high_beam'}, 'boolean', '1'); setOut(B3, {'ahb_state'}, 'uint8', '1');

%% 2) Entrees vehicule / conducteur / environnement
ins = {'ignition',1;'sw_raw',1;'flash_raw',1;'hb_toggle',1;'fog_sw',1;'ahb_switch',1;'turn_left',1;'turn_right',1; ...
       'hazard_sw',1;'brake_pedal',1;'lux_raw',0;'msg_ok',1;'speed',0;'decel',0;'vehicle_detected',1;'cam_ok',1; ...
       'door_closed',1;'vbat',0;'clear_dtc',1;'lamp_fail',1};
for k = 1:size(ins,1)
    b = [mdl '/IN_' ins{k,1}]; y = 20 + (k-1)*40;
    add_block('simulink/Sources/From Workspace', b, 'VariableName', ['in_' ins{k,1}], 'SampleTime','Ts', ...
              'OutputAfterFinalValue','Holding final value', 'Position', [20 y 130 y+24]);
    if ins{k,2}, set_param(b,'Interpolate','off'); end
end
IN = @(n) ['IN_' n '/1'];

%% 3) Blocs d'adaptation (comparaison, retards pour casser les boucles algebriques)
add_block('simulink/Logic and Bit Operations/Compare To Constant', [mdl '/is_AUTO'], 'const','1', 'relop','==', 'Position',[520 60 570 90]);
add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/low_ON'], 'Operator','OR', 'Position',[1180 470 1210 510]);
add_block('simulink/Discrete/Unit Delay', [mdl '/Z_low'], 'SampleTime','Ts', 'Position',[1240 475 1270 505]);
add_block('simulink/Discrete/Unit Delay', [mdl '/Z_fault'], 'SampleTime','Ts', 'Position',[1800 420 1830 450]);
add_block('simulink/Discrete/Unit Delay', [mdl '/Z_degraded'], 'SampleTime','Ts', 'Position',[1800 470 1830 500]);
add_block('simulink/Signal Routing/Demux', [mdl '/Demux_fault'], 'Outputs','4', 'Position',[1860 410 1865 470]);
add_block('simulink/Sinks/Terminator', [mdl '/T1'], 'Position',[1890 405 1900 415]);
add_block('simulink/Sinks/Terminator', [mdl '/T2'], 'Position',[1890 420 1900 430]);

%% 4) Connexions (noms des ports = noms des arguments des fonctions)
L = @(a, b) add_line(mdl, a, b, 'autorouting','on');
% B1
L(IN('lux_raw'), in(B1,'lux_raw'));  L(IN('msg_ok'), in(B1,'msg_ok'));
L(IN('sw_raw'), in(B1,'sw_raw'));    L(IN('flash_raw'), in(B1,'flash_raw'));
L(out(B1,'sw_pos'), 'is_AUTO/1');
% B2
L(out(B1,'lux_filt'), in(B2,'lux')); L('is_AUTO/1', in(B2,'auto_mode')); L(out(B1,'lux_valid'), in(B2,'lux_valid'));
% B3
L('is_AUTO/1', in(B3,'auto_mode'));  L(IN('ahb_switch'), in(B3,'ahb_switch')); L('Z_low/1', in(B3,'low_beam_on'));
L(IN('speed'), in(B3,'speed'));      L(out(B1,'lux_filt'), in(B3,'lux'));
L(IN('vehicle_detected'), in(B3,'vehicle_detected')); L(IN('cam_ok'), in(B3,'cam_ok'));
L(out(B1,'flash_req'), in(B3,'manual_override'));
% B4 / B8
L(IN('ignition'), in(B4,'ignition')); L(out(B1,'sw_pos'), in(B4,'sw_pos')); L(out(B1,'flash_req'), in(B4,'flash'));
L(IN('hb_toggle'), in(B4,'hb_toggle')); L(IN('fog_sw'), in(B4,'fog_sw')); L(out(B2,'low_beam'), in(B4,'auto_low'));
L(out(B3,'high_beam'), in(B4,'ahb_req')); L(out(B1,'lux_filt'), in(B4,'lux')); L(IN('vbat'), in(B4,'vbat'));
L(IN('door_closed'), in(B4,'door_closed')); L('Z_degraded/1', in(B4,'degraded'));
L(out(B4,'low_L'), 'low_ON/1'); L(out(B4,'low_R'), 'low_ON/2'); L('low_ON/1', 'Z_low/1');
% B5
L(IN('ignition'), in(B5,'ignition')); L(IN('turn_left'), in(B5,'turn_left')); L(IN('turn_right'), in(B5,'turn_right'));
L(IN('hazard_sw'), in(B5,'hazard_sw')); L(IN('brake_pedal'), in(B5,'brake_pedal')); L(IN('speed'), in(B5,'speed'));
L(IN('decel'), in(B5,'decel')); L('Demux_fault/3', in(B5,'fault_L')); L('Demux_fault/4', in(B5,'fault_R'));
L('Demux_fault/1','T1/1'); L('Demux_fault/2','T2/1');
% B7
for n = {'low_L','low_R','high','position','drl','fog'}, L(out(B4,n{1}), in(B7,n{1})); end
L(out(B5,'blink_L'), in(B7,'blink_L')); L(out(B5,'blink_R'), in(B7,'blink_R'));
L(out(B5,'brake_light'), in(B7,'brake')); L(IN('vbat'), in(B7,'vbat'));
% Modele des lampes + B6
L(out(B7,'duty'), in(PL,'duty')); L(IN('vbat'), in(PL,'vbat')); L(IN('lamp_fail'), in(PL,'lamp_fail'));
L(out(B7,'diag_cmd'), in(B6,'lamp_cmd')); L(out(PL,'lamp_cur'), in(B6,'lamp_cur')); L(IN('clear_dtc'), in(B6,'clear_dtc'));
L(out(B6,'fault_act'), 'Z_fault/1'); L('Z_fault/1', 'Demux_fault/1'); L(out(B6,'degraded'), 'Z_degraded/1');

%% 5) Enregistrement des sorties
logs = {out(B7,'duty'),'O_duty'; out(B4,'light_state'),'O_state'; out(B4,'fmh_active'),'O_fmh'; out(B3,'ahb_state'),'O_ahb'; ...
        out(B6,'dtc_stored'),'O_dtc'; out(B6,'warning'),'O_warn'; out(B5,'hazard_active'),'O_haz'; out(B5,'ess_active'),'O_ess'; ...
        out(B1,'lux_filt'),'O_lux'; out(B7,'veff_low'),'O_veff'};
for k = 1:size(logs,1)
    y = 600 + (k-1)*45;
    add_block('simulink/Sinks/To Workspace', [mdl '/' logs{k,2}], 'VariableName', logs{k,2}, 'SaveFormat','Timeseries', ...
              'Position', [1900 y 1990 y+24]);
    L(logs{k,1}, [logs{k,2} '/1']);
end
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts','4', 'Position', [2050 120 2100 300]);
L(out(B1,'lux_filt'),'Scope/1'); L(out(B4,'light_state'),'Scope/2'); L(out(B3,'ahb_state'),'Scope/3'); L(out(B5,'hazard_active'),'Scope/4');
c = get_param([mdl '/Scope'],'ScopeConfiguration'); c.LayoutDimensions = [4 1];
save_system(mdl);
fprintf('Modele %s.slx cree : 8 blocs + modele des lampes.\n\n', mdl);

%% 6) Simulation du trajet complet
INT_scenario;
o = sim(mdl);
tt = o.O_state.Time;
D = double(squeeze(o.O_duty.Data)); if size(D,1) ~= numel(tt), D = D.'; end
st = double(squeeze(o.O_state.Data)); fm = logical(squeeze(o.O_fmh.Data));
dtc = double(squeeze(o.O_dtc.Data)); wn = logical(squeeze(o.O_warn.Data)); hz = logical(squeeze(o.O_haz.Data));
es = logical(squeeze(o.O_ess.Data)); lx = double(squeeze(o.O_lux.Data));
at = @(x, tq) x(find(tt >= tq - 1e-9, 1), :);
fprintf('===== INTEGRATION : trajet complet de 130 s =====\n');
check('INT-01 Parking contact coupe : tout eteint', at(st, 1), 0, 0);
check('INT-02 Contact : DRL (B4 -> B7 LED avant 100 %)', firstT(st == 1, tt, 2) - 2, 0, 0.20);
check('INT-03 Clignotant G : 3 flashs en 2 s (B5 -> B7)', numel(re(D(:,5) > 0, tt, 8, 9.99)), 3, 3);
check('INT-04 Crepuscule : croisement allume (B1 -> B2 -> B4)', firstT(st >= 3, tt, 20), 31, 35);
check('INT-05 Aucun faux defaut lampe avant la panne (B6)', max(dtc(tt < 55)), 0, 0);
check('INT-06 Nuit, 80 km/h : feux de route AHB (B3 -> B4 -> B7)', double(at(D(:,3), 40) > 0), 1, 1);
check('INT-07 Regulation 14,2 V : croisement a 86 %', at(D(:,1), 40), 86, 86);
check('INT-08 Vehicule en face : route coupee <= 300 ms', firstT(D(:,3) == 0, tt, 45) - 45, 0, 0.30);
check('INT-09 Route libre 2 s : feux de route rallumes', firstT(D(:,3) > 0, tt, 46) - 50, 1.99, 2.05);
check('INT-10 Ampoule grillee : DTC + temoin <= 300 ms (B7 -> lampe -> B6)', firstT(wn, tt, 55) - 55, 0, 0.30);
check('INT-11 Mode degrade : croisement D coupe, G maintenu (B6 -> B4)', double(at(D(:,2),56) == 0 && at(D(:,1),56) > 0), 1, 1);
check('INT-12 Freinage d''urgence : ESS actif (B5)', firstT(es, tt, 64) - 65, 0, 0.02);
check('INT-13 ESS : feux stop clignotent (>= 8 flashs)', numel(re(D(:,7) == 100, tt, 65, 67.7)), 8, 20);
check('INT-14 Arret : detresse automatique', firstT(hz, tt, 66) - (65 + 80/28.8), -0.02, 0.05);
check('INT-15 Redemarrage > 10 km/h : detresse eteinte', firstT(~hz, tt, 70) - (78 + 10/7.5), 0, 0.05);
check('INT-16 Coupure contact de nuit : follow-me-home (B8)', double(at(fm, 92.05) && at(D(:,1), 92.05) > 0), 1, 1);
check('INT-17 Follow-me-home : extinction 30 s apres la porte (125 s)', firstT(~fm, tt, 93) - 125, 0, 0.05);
check('INT-18 Le DTC reste memorise en fin de trajet (bit 1 = 2)', at(dtc, 129), 2, 2);

%% 7) Figure du rapport
figure('Name','Integration','Color','w','Position',[60 40 1000 820]);
subplot(5,1,1); yyaxis left; plot(tt, lx, 'LineWidth', 1.3); ylabel('Lux filtre'); set(gca,'YScale','log'); ylim([5 3e4]);
yyaxis right; plot(t, spd, 'LineWidth', 1.3); ylabel('km/h'); grid on; title('INTEGRATION - trajet complet : jour, crepuscule, route, urgence, arrivee');
subplot(5,1,2); stairs(tt, st, 'k', 'LineWidth', 1.4); yticks(0:5); yticklabels({'OFF','DRL','POSITION','CROIS.','ROUTE','FMH'}); ylim([-0.3 5.3]); grid on;
subplot(5,1,3); plot(tt, D(:,1), 'b', tt, D(:,2), 'c--', tt, D(:,3), 'm', 'LineWidth', 1.2); ylim([-5 105]); grid on; ylabel('PWM [%]');
legend('Crois. G','Crois. D','Route','Location','eastoutside','AutoUpdate','off');
subplot(5,1,4); plot(tt, D(:,5), 'Color',[0.9 0.6 0]); hold on; plot(tt, D(:,7), 'r'); ylim([-5 105]); grid on; ylabel('PWM [%]');
legend('Clignot. G','Stop/position AR','Location','eastoutside','AutoUpdate','off');
subplot(5,1,5); stairs(tt, double([wn hz+1.2 es+2.4 fm+3.6]), 'LineWidth', 1.3); yticks([0.5 1.7 2.9 4.1]);
yticklabels({'Temoin defaut','Detresse','ESS','FMH'}); grid on; xlabel('Temps [s]');
for k = 1:5, subplot(5,1,k); xline([2 8 20 32 45 50 55 65 78 92 95 125], ':'); xlim([0 130]); end
saveas(gcf, 'INT_trajet.png');
fprintf('\nFigure enregistree : INT_trajet.png\n');

%% ======== fonctions locales ========
function M = mkSub(top, name, file, params, pos)
    sub = [top '/' name];
    add_block('simulink/Ports & Subsystems/Subsystem', sub, 'Position', pos);
    delete_line(sub, 'In1/1', 'Out1/1'); delete_block([sub '/In1']); delete_block([sub '/Out1']);
    fcn = [sub '/Logic'];
    add_block('simulink/User-Defined Functions/MATLAB Function', fcn, 'Position', [250 40 450 400]);
    rt = sfroot; ch = rt.find('-isa','Stateflow.EMChart','Path',fcn);
    ch.Script = fileread(file);
    for k = 1:numel(params)
        d = ch.find('-isa','Stateflow.Data','Name',params{k}); d.Scope = 'Parameter';
    end
    M.name = name; M.in = {}; M.out = {}; M.ch = ch;
    di = ch.find('-isa','Stateflow.Data','Scope','Input');  [~, o] = sort(arrayfun(@(x) x.Port, di)); di = di(o);
    for k = 1:numel(di)
        add_block('simulink/Sources/In1', [sub '/' di(k).Name], 'Port', num2str(k), 'Position', [60 30+k*35 90 44+k*35]);
        add_line(sub, [di(k).Name '/1'], sprintf('Logic/%d', k), 'autorouting','on');
        M.in{k} = di(k).Name;
    end
    do = ch.find('-isa','Stateflow.Data','Scope','Output'); [~, o] = sort(arrayfun(@(x) x.Port, do)); do = do(o);
    for k = 1:numel(do)
        add_block('simulink/Sinks/Out1', [sub '/' do(k).Name], 'Port', num2str(k), 'Position', [560 30+k*45 590 44+k*45]);
        add_line(sub, sprintf('Logic/%d', k), [do(k).Name '/1'], 'autorouting','on');
        M.out{k} = do(k).Name;
    end
end
function setOut(M, names, typ, sz)
    for k = 1:numel(names)
        d = M.ch.find('-isa','Stateflow.Data','Name',names{k});
        d.DataType = typ; d.Props.Array.Size = sz;
    end
end
function p = in(M, n)
    p = sprintf('%s/%d', M.name, find(strcmp(M.in, n)));
end
function p = out(M, n)
    p = sprintf('%s/%d', M.name, find(strcmp(M.out, n)));
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
        fprintf('  [PASS] %-64s mesure = %.3f\n', nom, val);
    else
        fprintf('  [FAIL] %-64s mesure = %.3f (attendu %.3f..%.3f)\n', nom, val, vmin, vmax);
    end
end
