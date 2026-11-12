%% =====================================================================
%  SIL - Software-In-the-Loop du calculateur d'eclairage complet (8 blocs)
%  1) Le code MATLAB des blocs (scripts\Bx_logic.txt, deja valide en MIL) est
%     regroupe en 2 runnables : LSC_cmd (B1,B2,B3,B4/B8,B5,B7) et LSC_diag (B6)
%  2) Verification : la boucle MATLAB reproduit exactement le modele Simulink
%  3) Generation du code C (Embedded Coder via MATLAB Coder)
%  4) Export des 4 scenarios (entrees + sorties MIL) pour le test back-to-back
% ======================================================================
clear; clc; close all; clear functions; bdclose all;
root = pwd; S = fullfile(root,'scripts'); addpath(S);
silDir = fullfile(root,'sil'); if ~exist(silDir,'dir'), mkdir(silDir); end
diary(fullfile(root,'results','sil_all.txt'));
B1_params; B2_params; B3_params; B4_params; B5_params; B6_params; B7_params;

% --- 1) fichiers .m des blocs (meme code que les sous-systemes Simulink)
src = {'B1_logic','B1_Acquisition'; 'B2_logic','AutoHeadlampLogic'; 'B3_logic','AHB_Logic'; 'B4_logic','B4_Manager'; ...
       'B5_logic','B5_Signal'; 'B6_logic','B6_Diag'; 'B7_logic','B7_Driver'; 'Plant_logic','Plant_Lamps'};
for k = 1:size(src,1), copyfile(fullfile(S,[src{k,1} '.txt']), fullfile(silDir,[src{k,2} '.m'])); end
copyfile(fullfile(root,'LSC_cmd.m'), silDir); copyfile(fullfile(root,'LSC_diag.m'), silDir);
% parametres de calibration figes dans le code (constantes)
pn = {'Ts','TAU_LUX','LUX_MAX','T_ABSENT','T_RECOVER','T_DEB','LUX_ON','LUX_OFF','T_ON','T_OFF','T_TUNNEL', ...
      'V_AHB_ON','V_AHB_OFF','LUX_AHB','T_REARM','T_FMH','T_ARM','T_FMH_STEP','T_FMH_MAX','U_BAT_MIN', ...
      'F_BLINK','F_HYPER','T_SHORT','N_COMFORT','A_ESS_ON','A_ESS_OFF','V_ESS','F_ESS','V_RESUME', ...
      'I_NOM','R_OPEN','R_SHORT','T_INRUSH','T_CONF','T_HEAL','V_EFF','T_SOFT','POS_DIM','TAIL_DIM'};
fid = fopen(fullfile(silDir,'LSC_params_const.m'),'w');
fprintf(fid,'function P = LSC_params_const()\n%%#codegen\n%% Parametres de calibration (copie de scripts\\Bx_params.m)\n');
for k = 1:numel(pn)
    v = eval(pn{k});
    fprintf(fid,'P.%s = %s;\n', pn{k}, mat2str(v,17));
end
fclose(fid);
cd(silDir); addpath(silDir);
P = LSC_params_const();

% --- 2) boucle MIL en MATLAB pour les 4 scenarios + export CSV
scen = {'INT_scenario',130; 'INT_scenario2',40; 'INT_scenario3',40; 'INT_scenario4',60};
for s = 1:4
    clear functions; P = LSC_params_const();
    run(fullfile(S,[scen{s,1} '.m']));
    N = numel(t);
    U = [double(ignition(:)) double(sw_raw(:)) double(flash_raw(:)) double(hb_toggle(:)) double(fog_sw(:)) double(ahb_switch(:)) ...
         double(turn_left(:)) double(turn_right(:)) double(hazard_sw(:)) double(brake_pedal(:)) double(lux_raw(:)) double(msg_ok(:)) ...
         double(spd(:)) double(decel(:)) double(vehicle_detected(:)) double(cam_ok(:)) double(door_closed(:)) double(vbat(:)) ...
         double(clear_dtc(:)) double(lamp_fail)];
    Y = zeros(N, 22);
    fp = false(4,1); dp = uint8(0);
    for k = 1:N
        u = U(k,:);
        [duty, veff, dcmd, lst, fmh, ahb, haz, ess, lux] = LSC_cmd(u(1)~=0, u(2), u(3)~=0, u(4)~=0, u(5)~=0, u(6)~=0, ...
            u(7)~=0, u(8)~=0, u(9)~=0, u(10)~=0, u(11), u(12)~=0, u(13), u(14), u(15)~=0, u(16)~=0, u(17)~=0, u(18), fp, dp);
        cur = Plant_Lamps(duty, u(18), u(20:23).', P.I_NOM);
        [fa, dtc, deg, wn] = LSC_diag(logical(dcmd(:)), cur(:), u(19)~=0);
        fp = logical(fa(:)); dp = uint8(deg);
        Y(k,:) = [double(duty(:)).' double(lst) double(fmh) double(ahb) double(haz) double(ess) lux veff ...
                  double(fa(:)).' double(dtc) double(deg) double(wn)];
    end
    writeCsv(fullfile(silDir, sprintf('S%d_in.csv', s)), [t(:) U]);
    writeCsv(fullfile(silDir, sprintf('S%d_mil.csv', s)), Y);
    fprintf('Scenario %d : %d pas exportes.\n', s, N);
    if s == 1, Y1 = Y; end
end

% --- 3) la boucle MATLAB = le modele Simulink ? (scenario 1)
cd(root); clear functions; run(fullfile(S,'INT_scenario.m'));
load_system('LSC_Integration'); o = sim('LSC_Integration');
D = double(squeeze(o.O_duty.Data)); if size(D,1) ~= size(Y1,1), D = D.'; end
cmp = @(a,b) max(abs(double(a(:)) - double(b(:))));
e = [cmp(D, Y1(:,1:8)) cmp(squeeze(o.O_state.Data), Y1(:,9)) cmp(squeeze(o.O_ahb.Data), Y1(:,11)) ...
     cmp(squeeze(o.O_dtc.Data), Y1(:,20)) cmp(squeeze(o.O_lux.Data), Y1(:,14))];
fprintf('Equivalence MATLAB / Simulink (scenario 1) : ecart max duty=%g etat=%g ahb=%g dtc=%g lux=%g\n', e);
if all(e < 1e-9), disp('[PASS] SIL-00 La boucle des runnables reproduit le modele LSC_Integration'); else, disp('[FAIL] SIL-00'); end
cd(silDir);

% --- 4) generation du code C
cfg = coder.config('lib','ecoder',true);
cfg.GenCodeOnly = true; cfg.GenerateReport = true; cfg.TargetLang = 'C';
try, cfg.InlineBetweenUserFunctions = 'Readability'; catch, end
try, cfg.InlineThreshold = 0; catch, end
B = false; D0 = 0;
argsC = {B, D0, B, B, B, B, B, B, B, B, D0, B, D0, D0, B, B, B, D0, false(4,1), uint8(0)};
argsD = {false(4,1), zeros(4,1), B};
argsP = {zeros(8,1,'uint8'), D0, zeros(4,1), coder.Constant(P.I_NOM)};
try
    codegen('-config', cfg, 'LSC_cmd', '-args', argsC, 'LSC_diag', '-args', argsD, ...
            'Plant_Lamps', '-args', argsP, '-o', 'LSC_ECU', '-d', fullfile(silDir,'codegen','lib','LSC_ECU'));
    disp('CODEGEN_OK');
catch err
    disp(['CODEGEN_ERR: ' err.message]);
end
copyfile(fullfile(matlabroot,'extern','include','tmwtypes.h'), silDir);
cd(root); diary off

function writeCsv(f, M)
    fid = fopen(f,'w'); fmt = [repmat('%.17g,',1,size(M,2)-1) '%.17g\n'];
    fprintf(fid, fmt, M.'); fclose(fid);
end
