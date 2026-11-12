%% SIL B2 - Generation du code C (Embedded Coder via MATLAB Coder) et test back-to-back MIL vs SIL
clc; close all; clear functions;
root = pwd; addpath(fullfile(root,'scripts'));
diary(fullfile(root,'results','sil_B2.txt'));
B2_params;
silDir = fullfile(root,'sil'); if ~exist(silDir,'dir'), mkdir(silDir); end
copyfile(fullfile(root,'scripts','B2_logic.txt'), fullfile(silDir,'AutoHeadlampLogic.m'));
addpath(silDir); cd(silDir);

% ---- compilateur C disponible ?
cc = mex.getCompilerConfigurations('C','Selected');
if isempty(cc), disp('COMPILER: aucun'); else, fprintf('COMPILER: %s\n', cc.Name); end

% ---- signaux de test (45 s) : jour, nuit, jour, tunnel, defaut capteur
t = (0:Ts:45)'; n = numel(t);
lux = 5000*ones(n,1);
lux(t>=5 & t<15) = 300;                 % nuit
lux(t>=25 & t<30) = 150;                % tunnel
valid = true(n,1); valid(t>=35 & t<40) = false;   % defaut capteur
autoM = true(n,1);

% ---- MIL : le code MATLAB execute directement
clear AutoHeadlampLogic
yM = false(n,1);
for k = 1:n
    yM(k) = AutoHeadlampLogic(lux(k), autoM(k), valid(k), Ts, LUX_ON, LUX_OFF, T_ON, T_OFF, T_TUNNEL);
end

% ---- generation du code C
cfg = coder.config('lib','ecoder',true);
cfg.GenerateReport = true; cfg.GenCodeOnly = isempty(cc);
cfg.TargetLang = 'C';
args = {0, false, false, coder.Constant(Ts), coder.Constant(LUX_ON), coder.Constant(LUX_OFF), ...
        coder.Constant(T_ON), coder.Constant(T_OFF), coder.Constant(T_TUNNEL)};
try
    codegen('-config', cfg, 'AutoHeadlampLogic', '-args', args);
    disp('CODEGEN_OK');
catch e
    disp(['CODEGEN_ERR: ' e.message]); diary off; cd(root); return
end

% ---- SIL : le code C compile, execute pas a pas
if ~isempty(cc)
    try
        cfg.GenCodeOnly = false; cfg.VerificationMode = 'SIL';
        codegen('-config', cfg, 'AutoHeadlampLogic', '-args', args);
        yS = false(n,1);
        for k = 1:n
            yS(k) = AutoHeadlampLogic_sil(lux(k), autoM(k), valid(k), Ts, LUX_ON, LUX_OFF, T_ON, T_OFF, T_TUNNEL);
        end
        clear AutoHeadlampLogic_sil
        nd = sum(yM ~= yS);
        fprintf('SIL_OK  pas compares = %d  differences = %d\n', n, nd);
        if nd == 0, disp('[PASS] B2 back-to-back MIL = SIL'); else, disp('[FAIL] B2 back-to-back'); end
    catch e
        disp(['SIL_ERR: ' e.message]);
    end
end
cd(root); diary off
