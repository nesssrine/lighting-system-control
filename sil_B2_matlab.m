%% SIL dans MATLAB (B2) : le code C est compile (LCC-win64) et execute par MATLAB, puis compare au MIL
clc; clear functions; root = pwd; addpath(fullfile(root,'scripts'));
diary(fullfile(root,'results','sil_B2_matlab.txt')); B2_params;
cd(fullfile(root,'sil'));
t = (0:Ts:45)'; n = numel(t); lux = 5000*ones(n,1); lux(t>=5 & t<15) = 300; lux(t>=25 & t<30) = 150;
valid = true(n,1); valid(t>=35 & t<40) = false;
clear AutoHeadlampLogic; yM = false(n,1);
for k = 1:n, yM(k) = AutoHeadlampLogic(lux(k), true, valid(k), Ts, LUX_ON, LUX_OFF, T_ON, T_OFF, T_TUNNEL); end
cfg = coder.config('lib','ecoder',true); cfg.VerificationMode = 'SIL';
args = {0, false, false, coder.Constant(Ts), coder.Constant(LUX_ON), coder.Constant(LUX_OFF), coder.Constant(T_ON), coder.Constant(T_OFF), coder.Constant(T_TUNNEL)};
try
    codegen('-config', cfg, 'AutoHeadlampLogic', '-args', args, '-d', fullfile(pwd,'codegen','sil','AutoHeadlampLogic'));
    yS = false(n,1);
    for k = 1:n, yS(k) = AutoHeadlampLogic_sil(lux(k), true, valid(k), Ts, LUX_ON, LUX_OFF, T_ON, T_OFF, T_TUNNEL); end
    clear AutoHeadlampLogic_sil
    fprintf('SIL_MATLAB_OK pas=%d differences=%d\n', n, sum(yM ~= yS));
    figure('Color','w','Position',[100 100 900 420]);
    subplot(2,1,1); plot(t, lux, 'LineWidth',1.2); ylabel('Lux'); grid on; title('B2 - SIL dans MATLAB : modele (MIL) et code C compile (SIL)');
    subplot(2,1,2); stairs(t, double(yM), 'Color',[0.6 0.6 0.6], 'LineWidth',4); hold on; stairs(t, double(yS), 'r--', 'LineWidth',1.3);
    ylim([-0.2 1.2]); grid on; legend('MIL','SIL (code C)'); xlabel('Temps [s]'); ylabel('Croisement');
    saveas(gcf, fullfile(root,'SIL_B2_matlab.png'));
catch e
    disp(['SIL_MATLAB_ERR: ' e.message]);
end
cd(root); diary off
